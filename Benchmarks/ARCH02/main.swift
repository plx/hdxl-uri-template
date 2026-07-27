import Foundation
import HDXLURITemplate

@main
private enum ARCH02Benchmark {

  static func main() throws {
    let arguments = try Arguments.parse(CommandLine.arguments)
    let report = try run(arguments: arguments)
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
    FileHandle.standardOutput.write(try encoder.encode(report))
    FileHandle.standardOutput.write(Data([0x0A]))
  }

  private static func run(arguments: Arguments) throws -> Report {
    let source = "https://example.com/é{/segments*}{?query,lang,query}"
    let alternateSource = "https://example.com/{id}"
    let template = try URITemplate(parsing: source)
    let equivalentTemplate = try URITemplate(parsing: source)
    let alternateTemplate = try URITemplate(parsing: alternateSource)
    let metadataTemplates = try (0..<32).map {
      try URITemplate(
        parsing: "https://example.com/users/\($0){?query,lang}"
      )
    }
    let parameters: [String: URIVariableValue] = [
      "segments": .list(["users", "42"]),
      "query": .text("uri templates"),
      "lang": .text("swift"),
    ]
    let expectedExpansion =
      "https://example.com/%C3%A9/users/42?query=uri%20templates"
      + "&lang=swift&query=uri%20templates"
    let encodedTemplate = try JSONEncoder().encode(template)

    let workloads = try [
      measure(
        id: "parse",
        iterations: 50_000,
        sampleCount: arguments.sampleCount
      ) {
        var digest: UInt64 = 0
        for _ in 0..<50_000 {
          let parsed = try URITemplate(parsing: source)
          digest &+= stableDigest(parsed.templateRepresentation)
        }
        return digest
      },
      measure(
        id: "expansion",
        iterations: 50_000,
        sampleCount: arguments.sampleCount
      ) {
        var digest: UInt64 = 0
        for _ in 0..<50_000 {
          let expansion = try template.evaluateAsString(parameters: parameters)
          guard expansion == expectedExpansion else {
            throw BenchmarkError("Expansion result drifted.")
          }
          digest &+= stableDigest(expansion)
        }
        return digest
      },
      measure(
        id: "metadata",
        iterations: 5_000_000,
        sampleCount: arguments.sampleCount
      ) {
        var digest: UInt64 = 0
        for index in 0..<5_000_000 {
          let selected = metadataTemplates[index & 31]
          digest &+= UInt64(selected.variableNames.count)
          digest &+= UInt64(selected.templateRepresentation.utf8.count)
        }
        return digest
      },
      measure(
        id: "copy-and-hash",
        iterations: 500_000,
        sampleCount: arguments.sampleCount
      ) {
        var digest: UInt64 = 0
        for _ in 0..<500_000 {
          let copy = template
          let values: Set<URITemplate> = [
            copy,
            equivalentTemplate,
            alternateTemplate,
          ]
          guard values.count == 2, values.contains(template) else {
            throw BenchmarkError("Copy or hashing semantics drifted.")
          }
          digest &+= UInt64(values.count)
          digest &+= stableDigest(copy.templateRepresentation)
        }
        return digest
      },
      measure(
        id: "semantic-codable",
        iterations: 20_000,
        sampleCount: arguments.sampleCount
      ) {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        var digest: UInt64 = 0
        for _ in 0..<20_000 {
          let encoded = try encoder.encode(template)
          guard encoded == encodedTemplate else {
            throw BenchmarkError("Semantic encoding drifted.")
          }
          let decoded = try decoder.decode(URITemplate.self, from: encoded)
          guard decoded == template else {
            throw BenchmarkError("Semantic decoding drifted.")
          }
          digest &+= stableDigest(decoded.templateRepresentation)
        }
        return digest
      },
    ]

    return Report(
      schemaVersion: 1,
      label: arguments.label,
      commit: arguments.commit,
      sampleCount: arguments.sampleCount,
      swiftVersion:
        ProcessInfo.processInfo.environment["ARCH02_SWIFT_VERSION"]
        ?? "unrecorded",
      architecture: architecture(),
      logicalCoreCount: ProcessInfo.processInfo.activeProcessorCount,
      workloads: workloads
    )
  }

  private static func measure(
    id: String,
    iterations: Int,
    sampleCount: Int,
    operation: () throws -> UInt64
  ) throws -> Workload {
    _ = try operation()
    var rawNanoseconds: [UInt64] = []
    var expectedDigest: UInt64?

    for _ in 0..<sampleCount {
      let start = ContinuousClock.now
      let digest = try operation()
      let elapsed = start.duration(to: .now).nanoseconds
      if let expectedDigest {
        guard digest == expectedDigest else {
          throw BenchmarkError("\(id) produced a nondeterministic digest.")
        }
      } else {
        expectedDigest = digest
      }
      rawNanoseconds.append(max(1, elapsed))
    }

    let medianNanoseconds = rawNanoseconds.sorted()[sampleCount / 2]
    return Workload(
      id: id,
      iterations: iterations,
      rawNanoseconds: rawNanoseconds,
      medianNanoseconds: medianNanoseconds,
      medianNanosecondsPerOperation:
        Double(medianNanoseconds) / Double(iterations),
      resultDigest: hex(expectedDigest ?? 0)
    )
  }

  private static func architecture() -> String {
    #if arch(arm64)
      "arm64"
    #elseif arch(x86_64)
      "x86_64"
    #else
      "unknown"
    #endif
  }
}

private struct Arguments {
  let label: String
  let commit: String
  let sampleCount: Int

  static func parse(_ arguments: [String]) throws -> Self {
    var label: String?
    var commit: String?
    var sampleCount = 7
    var index = 1

    while index < arguments.count {
      switch arguments[index] {
      case "--label":
        index += 1
        label = try value(at: index, in: arguments, for: "--label")
      case "--commit":
        index += 1
        commit = try value(at: index, in: arguments, for: "--commit")
      case "--samples":
        index += 1
        let value = try value(at: index, in: arguments, for: "--samples")
        guard let parsed = Int(value) else {
          throw BenchmarkError("--samples must be an integer.")
        }
        sampleCount = parsed
      default:
        throw BenchmarkError("Unknown argument \(arguments[index]).")
      }
      index += 1
    }

    guard let label, label.isEmpty == false else {
      throw BenchmarkError("--label is required.")
    }
    guard let commit, commit.isEmpty == false else {
      throw BenchmarkError("--commit is required.")
    }
    guard sampleCount >= 3, sampleCount.isMultiple(of: 2) == false else {
      throw BenchmarkError("--samples must be an odd integer at least 3.")
    }
    return Self(label: label, commit: commit, sampleCount: sampleCount)
  }

  private static func value(
    at index: Int,
    in arguments: [String],
    for option: String
  ) throws -> String {
    guard arguments.indices.contains(index) else {
      throw BenchmarkError("\(option) requires a value.")
    }
    return arguments[index]
  }
}

private struct Report: Codable {
  let schemaVersion: Int
  let label: String
  let commit: String
  let sampleCount: Int
  let swiftVersion: String
  let architecture: String
  let logicalCoreCount: Int
  let workloads: [Workload]
}

private struct Workload: Codable {
  let id: String
  let iterations: Int
  let rawNanoseconds: [UInt64]
  let medianNanoseconds: UInt64
  let medianNanosecondsPerOperation: Double
  let resultDigest: String
}

private struct BenchmarkError: Error, CustomStringConvertible {
  let description: String

  init(_ description: String) {
    self.description = description
  }
}

private func stableDigest(_ value: String) -> UInt64 {
  value.utf8.reduce(into: UInt64(0xCBF2_9CE4_8422_2325)) {
    $0 ^= UInt64($1)
    $0 &*= 0x0000_0100_0000_01B3
  }
}

private func hex(_ value: UInt64) -> String {
  String(format: "%016llx", value)
}

extension Duration {
  fileprivate var nanoseconds: UInt64 {
    let components = self.components
    let seconds = UInt64(max(0, components.seconds))
    let attoseconds = UInt64(max(0, components.attoseconds))
    return seconds &* 1_000_000_000 + attoseconds / 1_000_000_000
  }
}
