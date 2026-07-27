import Foundation
import HDXLURITemplate

package struct QA03FuzzConfiguration: Sendable {
  package let seed: UInt64
  package let iterations: Int
  package let fixtureDirectory: URL?
  package let replayIndex: Int?
  package let injectedFailureIndex: Int?

  package init(
    seed: UInt64,
    iterations: Int,
    fixtureDirectory: URL?,
    replayIndex: Int? = nil,
    injectedFailureIndex: Int? = nil
  ) {
    self.seed = seed
    self.iterations = iterations
    self.fixtureDirectory = fixtureDirectory
    self.replayIndex = replayIndex
    self.injectedFailureIndex = injectedFailureIndex
  }
}

package struct QA03FuzzReport: Codable, Sendable {
  package let schemaVersion: Int
  package let command: String
  package let commit: String
  package let seed: String
  package let requestedIterations: Int
  package let completedIterations: Int
  package let replayIndex: Int?
  package let corpusCount: Int
  package let corpusDigest: String
  package let acceptedTemplateCount: Int
  package let rejectedTemplateCount: Int
  package let successfulExpansionCount: Int
  package let controlledExpansionFailureCount: Int
  package let elapsedNanoseconds: UInt64
  package let resultDigest: String
}

package enum QA03FuzzRunner {

  package static func run(
    configuration: QA03FuzzConfiguration,
    commit: String,
    progress: @Sendable (String) -> Void = { _ in }
  ) throws -> QA03FuzzReport {
    guard configuration.iterations > 0 else {
      throw QA03Error("Fuzz iteration count must be positive.")
    }
    if let replayIndex = configuration.replayIndex {
      guard replayIndex >= 0, replayIndex < configuration.iterations else {
        throw QA03Error("Fuzz replay index is outside the iteration range.")
      }
    }

    let corpus = try makeCorpus(
      fixtureDirectory: configuration.fixtureDirectory
    )
    let corpusDigest = corpus.reduce(0 as UInt64) {
      $0 &+ qa03StableDigest($1)
    }
    let indices: [Int] =
      if let replayIndex = configuration.replayIndex {
        [replayIndex]
      } else {
        Array(0..<configuration.iterations)
      }
    var counters = Counters()
    let clock = ContinuousClock()
    let start = clock.now

    progress(
      "qa03-fuzz-start seed=\(qa03Hex(configuration.seed)) "
        + "iterations=\(configuration.iterations) "
        + "replay=\(configuration.replayIndex.map(String.init) ?? "none")"
    )

    for index in indices {
      if index.isMultiple(of: 10_000) {
        progress(
          "qa03-fuzz-checkpoint seed=\(qa03Hex(configuration.seed)) "
            + "index=\(index)"
        )
      }
      let caseSeed = QA03DeterministicGenerator.caseSeed(
        rootSeed: configuration.seed,
        index: index
      )
      do {
        if configuration.injectedFailureIndex == index {
          throw QA03Error("Injected deterministic fuzz failure.")
        }
        var generator = QA03DeterministicGenerator(seed: caseSeed)
        let source = makeSource(
          index: index,
          corpus: corpus,
          generator: &generator
        )
        let result = try runCase(
          source: source,
          index: index,
          generator: &generator
        )
        counters.record(result, source: source, index: index)
      } catch {
        throw QA03Error(
          "Fuzz failure seed=\(qa03Hex(configuration.seed)) "
            + "index=\(index) case-seed="
            + "\(qa03Hex(caseSeed)) "
            + "error=\(String(describing: error))"
        )
      }
    }

    return QA03FuzzReport(
      schemaVersion: 1,
      command: "fuzz",
      commit: commit,
      seed: qa03Hex(configuration.seed),
      requestedIterations: configuration.iterations,
      completedIterations: indices.count,
      replayIndex: configuration.replayIndex,
      corpusCount: corpus.count,
      corpusDigest: qa03Hex(corpusDigest),
      acceptedTemplateCount: counters.acceptedTemplates,
      rejectedTemplateCount: counters.rejectedTemplates,
      successfulExpansionCount: counters.successfulExpansions,
      controlledExpansionFailureCount: counters.controlledExpansionFailures,
      elapsedNanoseconds: start.duration(to: clock.now).qa03Nanoseconds,
      resultDigest: qa03Hex(counters.digest)
    )
  }

  private static func makeCorpus(
    fixtureDirectory: URL?
  ) throws -> [String] {
    var sources = [
      "",
      "literal",
      "https://example.com{/id}{?query}",
      "{value}",
      "{+value}",
      "{#value}",
      "{.value}",
      "{/value}",
      "{;value}",
      "{?value}",
      "{&value}",
      "{list*}",
      "{?pairs*}",
      "{value:1}",
      "{value:9999}",
      "{items:1}",
      "'{value}'",
      "~café/%2f",
      "{alpha.%2F}",
      "{",
      "{}",
      "{value,}",
      "{value:%}",
      String(repeating: "%20", count: 256),
    ]

    if let fixtureDirectory {
      let names = [
        "spec-examples.json",
        "spec-examples-by-section.json",
        "extended-tests.json",
        "negative-tests.json",
      ]
      for name in names {
        let data = try Data(
          contentsOf: fixtureDirectory.appendingPathComponent(name)
        )
        let object = try JSONSerialization.jsonObject(with: data)
        collectTemplateSources(in: object, into: &sources)
      }
    }

    return Array(Set(sources)).sorted()
  }

  private static func collectTemplateSources(
    in object: Any,
    into sources: inout [String]
  ) {
    if let dictionary = object as? [String: Any] {
      if let testCases = dictionary["testcases"] as? [Any] {
        for case let testCase as [Any] in testCases {
          if let template = testCase.first as? String {
            sources.append(template)
          }
        }
      }
      for value in dictionary.values {
        collectTemplateSources(in: value, into: &sources)
      }
    } else if let array = object as? [Any] {
      for value in array {
        collectTemplateSources(in: value, into: &sources)
      }
    }
  }

  private static func makeSource(
    index: Int,
    corpus: [String],
    generator: inout QA03DeterministicGenerator
  ) -> String {
    switch index % 6 {
    case 0:
      return corpus[generator.next(upperBound: corpus.count)]
    case 1:
      return mutate(
        corpus[generator.next(upperBound: corpus.count)],
        generator: &generator
      )
    case 2:
      return structuredSource(generator: &generator)
    case 3:
      return randomSource(
        length: generator.next(upperBound: 97),
        generator: &generator
      )
    case 4:
      let length =
        index.isMultiple(of: 1_000)
        ? 4_096
        : 32 + generator.next(upperBound: 224)
      return String(repeating: "a", count: length) + "{name%G}"
    default:
      return "SENSITIVE_TEMPLATE_\(index)"
        + structuredSource(generator: &generator)
    }
  }

  private static func mutate(
    _ source: String,
    generator: inout QA03DeterministicGenerator
  ) -> String {
    var scalars = Array(source.unicodeScalars)
    let alphabet = mutationAlphabet
    switch generator.next(upperBound: 4) {
    case 0 where !scalars.isEmpty:
      scalars.remove(at: generator.next(upperBound: scalars.count))
    case 1 where !scalars.isEmpty:
      scalars[generator.next(upperBound: scalars.count)] =
        alphabet[generator.next(upperBound: alphabet.count)]
    case 2:
      scalars.insert(
        alphabet[generator.next(upperBound: alphabet.count)],
        at: generator.next(upperBound: scalars.count + 1)
      )
    default:
      scalars.append(
        alphabet[generator.next(upperBound: alphabet.count)]
      )
    }
    return String(String.UnicodeScalarView(scalars))
  }

  private static func structuredSource(
    generator: inout QA03DeterministicGenerator
  ) -> String {
    let operators = ["", "+", "#", ".", "/", ";", "?", "&"]
    let names = ["value", "items", "pairs", "alpha.beta", "name%2F"]
    let literal = ["", "https://example.com", "café", "~", "/root"][
      generator.next(upperBound: 5)
    ]
    let componentCount = 1 + generator.next(upperBound: 4)
    var source = literal
    for _ in 0..<componentCount {
      let operation = operators[generator.next(upperBound: operators.count)]
      let name = names[generator.next(upperBound: names.count)]
      let modifier =
        switch generator.next(upperBound: 5) {
        case 0:
          "*"
        case 1:
          ":\(1 + generator.next(upperBound: 32))"
        default:
          ""
        }
      source += "{\(operation)\(name)\(modifier)}"
    }
    return source
  }

  private static func randomSource(
    length: Int,
    generator: inout QA03DeterministicGenerator
  ) -> String {
    var result = String.UnicodeScalarView()
    for _ in 0..<length {
      result.append(
        mutationAlphabet[
          generator.next(upperBound: mutationAlphabet.count)
        ]
      )
    }
    return String(result)
  }

  private static func runCase(
    source: String,
    index: Int,
    generator: inout QA03DeterministicGenerator
  ) throws -> CaseResult {
    do {
      let template = try URITemplate(parsing: source)
      guard
        template.templateRepresentation == source,
        try URITemplate(parsing: source) == template
      else {
        throw QA03Error("Accepted template did not retain exact source.")
      }

      let encodedTemplate = try JSONEncoder().encode(template)
      let decodedTemplate = try JSONDecoder().decode(
        URITemplate.self,
        from: encodedTemplate
      )
      guard
        decodedTemplate == template,
        decodedTemplate.templateRepresentation == source
      else {
        throw QA03Error("Template Codable round trip drifted.")
      }

      let parameters = try makeParameters(
        names: template.variableNames.sorted(),
        generator: &generator
      )
      let first = try expansionOutcome(
        template: template,
        parameters: parameters
      )
      let second = try expansionOutcome(
        template: template,
        parameters: parameters
      )
      guard first == second else {
        throw QA03Error("Repeated expansion was nondeterministic.")
      }
      try validateURLDeterminism(
        template: template,
        parameters: parameters
      )

      if index.isMultiple(of: 17) {
        try exerciseArbitraryDecoders(
          generator: &generator
        )
      }
      if index.isMultiple(of: 97) {
        try exerciseDuplicateAssociationBoundary()
      }

      switch first {
      case .success(let output):
        guard containsOnlyCompletePercentTriplets(output) else {
          throw QA03Error(
            "Expansion introduced an incomplete percent triplet."
          )
        }
        return CaseResult(
          accepted: true,
          expansionSucceeded: true,
          digest: qa03StableDigest(source) &+ qa03StableDigest(output)
        )
      case .failure(let kind):
        return CaseResult(
          accepted: true,
          expansionSucceeded: false,
          digest: qa03StableDigest(source) &+ qa03StableDigest(kind)
        )
      }
    } catch let error as URITemplate.ParseError {
      try validateDiagnostic(
        String(describing: error),
        source: source
      )
      return CaseResult(
        accepted: false,
        expansionSucceeded: false,
        digest: qa03StableDigest(source)
      )
    }
  }

  private static func makeParameters(
    names: [String],
    generator: inout QA03DeterministicGenerator
  ) throws -> [String: URIVariableValue] {
    var parameters: [String: URIVariableValue] = [:]
    for (offset, name) in names.enumerated() {
      let sentinel = "SENSITIVE_VALUE_\(offset)_"
      switch generator.next(upperBound: 4) {
      case 0:
        parameters[name] = .undefined
      case 1:
        parameters[name] = .text(
          sentinel + randomValue(generator: &generator)
        )
      case 2:
        parameters[name] = .list([
          sentinel + randomValue(generator: &generator),
          randomValue(generator: &generator),
          "%20/%G",
        ])
      default:
        parameters[name] = try .association([
          ("key0", sentinel + randomValue(generator: &generator)),
          ("key1", randomValue(generator: &generator)),
        ])
      }
    }
    return parameters
  }

  private static func randomValue(
    generator: inout QA03DeterministicGenerator
  ) -> String {
    let pieces = [
      "",
      "alpha",
      "uri templates",
      ":/?#[]@!$&'()*+,;=",
      "%20%2F%G%",
      "café",
      "e\u{0301}",
      "日本語",
      "😀",
    ]
    let count = 1 + generator.next(upperBound: 4)
    return (0..<count).map { _ in
      pieces[generator.next(upperBound: pieces.count)]
    }.joined()
  }

  private static func expansionOutcome(
    template: URITemplate,
    parameters: [String: URIVariableValue]
  ) throws -> ExpansionOutcome {
    do {
      return .success(
        try template.evaluateAsString(parameters: parameters)
      )
    } catch let error as URITemplate.EvaluationError {
      try validateDiagnostic(
        String(describing: error),
        source: template.templateRepresentation
      )
      return .failure(error.kind.description)
    } catch {
      throw QA03Error(
        "Expansion escaped its package error boundary: \(type(of: error))."
      )
    }
  }

  private static func validateURLDeterminism(
    template: URITemplate,
    parameters: [String: URIVariableValue]
  ) throws {
    let first = try urlOutcome(template: template, parameters: parameters)
    let second = try urlOutcome(template: template, parameters: parameters)
    guard first == second else {
      throw QA03Error("Repeated URL conversion was nondeterministic.")
    }
  }

  private static func urlOutcome(
    template: URITemplate,
    parameters: [String: URIVariableValue]
  ) throws -> ExpansionOutcome {
    do {
      return .success(
        try template.evaluate(parameters: parameters).absoluteString
      )
    } catch let error as URITemplate.EvaluationError {
      try validateDiagnostic(
        String(describing: error),
        source: template.templateRepresentation
      )
      return .failure(error.kind.description)
    } catch {
      throw QA03Error(
        "URL conversion escaped its package error boundary: \(type(of: error))."
      )
    }
  }

  private static func validateDiagnostic(
    _ diagnostic: String,
    source: String
  ) throws {
    guard diagnostic.utf8.count <= 512 else {
      throw QA03Error("Public diagnostic exceeded 512 UTF-8 bytes.")
    }
    if source.utf8.count >= 8, diagnostic.contains(source) {
      throw QA03Error("Public diagnostic exposed source payload.")
    }
  }

  private static func exerciseArbitraryDecoders(
    generator: inout QA03DeterministicGenerator
  ) throws {
    let count = generator.next(upperBound: 129)
    let data = Data((0..<count).map { _ in UInt8(truncatingIfNeeded: generator.next()) })
    _ = try? JSONDecoder().decode(URITemplate.self, from: data)
    _ = try? JSONDecoder().decode(URIVariableValue.self, from: data)
    _ = try? PropertyListDecoder().decode(URITemplate.self, from: data)
    _ = try? PropertyListDecoder().decode(URIVariableValue.self, from: data)
  }

  private static func exerciseDuplicateAssociationBoundary() throws {
    do {
      _ = try URIVariableValue.association([
        ("duplicate", "first"),
        ("duplicate", "second"),
      ])
      throw QA03Error("Duplicate association keys unexpectedly succeeded.")
    } catch is URIVariableValue.AssociationError {
      return
    }
  }

  private static func containsOnlyCompletePercentTriplets(
    _ string: String
  ) -> Bool {
    let bytes = Array(string.utf8)
    var index = 0
    while index < bytes.count {
      if bytes[index] == 0x25 {
        guard
          index + 2 < bytes.count,
          isHex(bytes[index + 1]),
          isHex(bytes[index + 2])
        else {
          return false
        }
        index += 3
      } else {
        index += 1
      }
    }
    return true
  }

  private static func isHex(_ byte: UInt8) -> Bool {
    (0x30...0x39).contains(byte)
      || (0x41...0x46).contains(byte)
      || (0x61...0x66).contains(byte)
  }

  private static let mutationAlphabet: [UnicodeScalar] = [
    "\u{0000}", "\t", "\n", " ", "!", "\"", "#", "%", "&", "'", "(",
    ")", "*", "+", ",", "-", ".", "/", "0", "9", ":", ";", "<", "=", ">",
    "?", "@", "A", "F", "G", "[", "\\", "]", "^", "_", "`", "a", "f", "g",
    "{", "|", "}", "~", "é", "\u{0301}", "日", "😀",
  ]
}

private enum ExpansionOutcome: Equatable {
  case success(String)
  case failure(String)
}

private struct CaseResult {
  let accepted: Bool
  let expansionSucceeded: Bool
  let digest: UInt64
}

private struct Counters {
  var acceptedTemplates = 0
  var rejectedTemplates = 0
  var successfulExpansions = 0
  var controlledExpansionFailures = 0
  var digest: UInt64 = 0

  mutating func record(
    _ result: CaseResult,
    source: String,
    index: Int
  ) {
    if result.accepted {
      acceptedTemplates += 1
      if result.expansionSucceeded {
        successfulExpansions += 1
      } else {
        controlledExpansionFailures += 1
      }
    } else {
      rejectedTemplates += 1
    }
    digest &+=
      result.digest
      &+ qa03StableDigest(source)
      &+ UInt64(index) &* 0x9E37_79B9_7F4A_7C15
  }
}
