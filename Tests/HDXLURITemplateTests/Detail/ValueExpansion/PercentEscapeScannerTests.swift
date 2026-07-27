import Foundation
import Testing
@testable import HDXLURITemplate

@Suite(.serialized)
private struct PercentEscapeScannerStressTests {}

@Test("Percent-escape scanning preserves valid triplets and encodes malformed input")
private func percentEscapeScannerCorrectnessMatrix() {
  let reservedCases: [(input: String, expected: String)] = [
    ("alpha/beta?x=y", "alpha/beta?x=y"),
    ("%20", "%20"),
    ("%20%2f%AF", "%20%2f%AF"),
    ("%a0%0B", "%a0%0B"),
    ("%", "%25"),
    ("%A", "%25A"),
    ("%GG", "%25GG"),
    ("%2G", "%252G"),
    ("%G2", "%25G2"),
    ("café", "caf%C3%A9"),
    ("a%20/b%2fc d%G0%", "a%20/b%2fc%20d%25G0%25"),
  ]

  for testCase in reservedCases {
    #expect(
      testCase.input.escaped(forValueExpansionType: .reserved)
        == testCase.expected
    )
    #expect(
      testCase.input.escaped(forValueExpansionType: .fragment)
        == testCase.expected
    )
  }

  #expect(
    "a%20/b%2fc d%G0%".escaped(forValueExpansionType: .simple)
      == "a%2520%2Fb%252fc%20d%25G0%25"
  )
}

@Test("Bounded percent-triplet lookahead covers exact ASCII boundaries")
private func boundedPercentTripletLookaheadCoversExactBoundaries() {
  for byte in [0x30, 0x39, 0x41, 0x46, 0x61, 0x66] as [UInt8] {
    #expect(byte.isASCIIHexadecimalDigit)
  }
  for byte in [0x2F, 0x3A, 0x40, 0x47, 0x60, 0x67] as [UInt8] {
    #expect(!byte.isASCIIHexadecimalDigit)
  }

  for source in ["%00", "%9a", "%Af", "%ff"] {
    let bytes = source.utf8
    #expect(
      bytes.indexAfterPercentEncodedTriplet(
        startingAt: bytes.startIndex
      ) == bytes.endIndex
    )
  }

  for source in ["", "A20", "%", "%2", "%GG", "%2G", "%G2"] {
    let bytes = source.utf8
    #expect(
      bytes.indexAfterPercentEncodedTriplet(
        startingAt: bytes.startIndex
      ) == nil
    )
  }
}

@Test("Public operators make percent-triplet preservation explicit")
private func publicOperatorsMakePercentTripletPreservationExplicit() throws {
  let value = "%20/%2f?café%G0%"
  let parameters: [String: URIVariableValue] = ["x": .text(value)]

  let simple = try URITemplate(parsing: "{x}")
  let reserved = try URITemplate(parsing: "{+x}")
  let fragment = try URITemplate(parsing: "{#x}")

  #expect(
    try simple.evaluateAsString(parameters: parameters)
      == "%2520%2F%252f%3Fcaf%C3%A9%25G0%25"
  )
  #expect(
    try reserved.evaluateAsString(parameters: parameters)
      == "%20/%2f?caf%C3%A9%25G0%25"
  )
  #expect(
    try fragment.evaluateAsString(parameters: parameters)
      == "#%20/%2f?caf%C3%A9%25G0%25"
  )

  let encodedName = try URITemplate(parsing: "{?name%2f}")
  #expect(
    try encodedName.evaluateAsString(
      parameters: ["name%2f": .text("value")]
    ) == "?name%2f=value"
  )
}

private extension PercentEscapeScannerStressTests {

  @Test("Seeded differential corpus preserves established escaping behavior")
  func seededDifferentialCorpusPreservesEstablishedBehavior() throws {
    let alphabet: [UnicodeScalar] = [
      "\u{0000}", "\t", "\n", " ", "!", "%", "&", "/", "0", "2", "9",
      "A", "F", "G", "Z", "a", "f", "g", "z", "?", "^", "~", "é",
      "\u{0301}", "日", "😀", "\u{200D}",
    ]
    var generator = DeterministicGenerator(state: 0x4841_5244_3031)

    for _ in 0..<2_000 {
      var scalars = String.UnicodeScalarView()
      let length = generator.next(upperBound: 65)
      for _ in 0..<length {
        scalars.append(alphabet[generator.next(upperBound: alphabet.count)])
      }
      let source = String(scalars)

      for expansionType in URIValueExpansionType.allCases {
        let expected = try #require(
          referenceEscaped(
            source,
            forValueExpansionType: expansionType
          )
        )
        #expect(
          source.escaped(forValueExpansionType: expansionType) == expected
        )
      }
    }
  }

  @Test("Shared template expands dense percent input concurrently")
  func sharedTemplateExpandsDensePercentInputConcurrently() async throws {
    let input =
      String(repeating: "%20", count: 20_000)
      + "/caf%C3%A9%G0%"
    let template = try URITemplate(parsing: "{+x}")
    let parameters: [String: URIVariableValue] = ["x": .text(input)]
    let expected = input.replacingOccurrences(of: "%G0%", with: "%25G0%25")

    try await withThrowingTaskGroup(of: String.self) { group in
      for _ in 0..<64 {
        group.addTask {
          try template.evaluateAsString(parameters: parameters)
        }
      }

      for try await output in group {
        #expect(output.utf8.elementsEqual(expected.utf8))
      }
    }
  }

  @Test("Large dense percent-triplet input is preserved without truncation")
  func largeDensePercentTripletInputIsPreservedWithoutTruncation() throws {
    let input = String(repeating: "%20", count: 100_000)
    let template = try URITemplate(parsing: "{+x}")
    let output = try template.evaluateAsString(
      parameters: ["x": .text(input)]
    )

    #expect(output.count == 300_000)
    #expect(output.utf8.elementsEqual(input.utf8))
  }

}

private struct DeterministicGenerator {

  var state: UInt64

  mutating func next(upperBound: Int) -> Int {
    state =
      state &* 6_364_136_223_846_793_005
      &+ 1_442_695_040_888_963_407
    return Int(state % UInt64(upperBound))
  }

}

private func referenceEscaped(
  _ source: String,
  forValueExpansionType expansionType: URIValueExpansionType
) -> String? {
  let allowedCharacters = CharacterSet.allowedCharacters(
    forValueExpansionType: expansionType
  )
  guard expansionType.allowsPercentEncodedTriplets else {
    return source.addingPercentEncoding(
      withAllowedCharacters: allowedCharacters
    )
  }

  let unescapedAllowedCharacters = allowedCharacters.subtracting(rfc_pct_encode)
  let scalars = Array(source.unicodeScalars)
  var pending = String.UnicodeScalarView()
  var result = String.UnicodeScalarView()
  var position = 0

  while position < scalars.count {
    let isTriplet =
      scalars[position] == "%"
      && position + 2 < scalars.count
      && rfcHEXDIG.contains(scalars[position + 1])
      && rfcHEXDIG.contains(scalars[position + 2])

    if isTriplet {
      guard
        let escapedPending = String(pending).addingPercentEncoding(
          withAllowedCharacters: unescapedAllowedCharacters
        )
      else {
        return nil
      }
      result.append(contentsOf: escapedPending.unicodeScalars)
      pending.removeAll(keepingCapacity: true)
      result.append(scalars[position])
      result.append(scalars[position + 1])
      result.append(scalars[position + 2])
      position += 3
    } else {
      pending.append(scalars[position])
      position += 1
    }
  }

  guard
    let escapedPending = String(pending).addingPercentEncoding(
      withAllowedCharacters: unescapedAllowedCharacters
    )
  else {
    return nil
  }
  result.append(contentsOf: escapedPending.unicodeScalars)
  return String(result)
}

#if !DEBUG
  private func medianDenseExpansionDurations(
    template: URITemplate,
    tripletCounts: [Int],
    repetitions: [Int],
    sampleCount: Int
  ) throws -> [Double] {
    let clock = ContinuousClock()
    return try zip(tripletCounts, repetitions).map { configuration in
      let (tripletCount, repetitionCount) = configuration
      let input = String(repeating: "%20", count: tripletCount)
      let parameters: [String: URIVariableValue] = ["x": .text(input)]
      var samples: [Double] = []
      samples.reserveCapacity(sampleCount)

      for _ in 0..<sampleCount {
        var output = ""
        let elapsed = try clock.measure {
          for _ in 0..<repetitionCount {
            output = try template.evaluateAsString(parameters: parameters)
          }
        }
        #expect(output.utf8.elementsEqual(input.utf8))
        samples.append(elapsed.seconds / Double(repetitionCount))
      }

      return samples.sorted()[sampleCount / 2]
    }
  }

  private func fittedScalingExponent(
    sizes: [Int],
    durations: [Double]
  ) -> Double {
    let logarithmicSizes = sizes.map { log(Double($0)) }
    let logarithmicDurations = durations.map(log)
    let meanSize =
      logarithmicSizes.reduce(0, +) / Double(logarithmicSizes.count)
    let meanDuration =
      logarithmicDurations.reduce(0, +) / Double(logarithmicDurations.count)
    let covariance = zip(
      logarithmicSizes,
      logarithmicDurations
    ).reduce(into: 0.0) { partialResult, point in
      partialResult +=
        ((point.0 - meanSize)
          * (point.1 - meanDuration))
    }
    let sizeVariance = logarithmicSizes.reduce(
      into: 0.0
    ) { partialResult, value in
      partialResult += pow(value - meanSize, 2)
    }
    return covariance / sizeVariance
  }

  private func expectLinearScaling(
    tripletCounts: [Int],
    medianDurations: [Double],
    adjacentRatios: [Double],
    fittedExponent: Double
  ) {
    for ratio in adjacentRatios {
      #expect(
        ratio <= 3.0,
        """
        Expected no adjacent doubling above 3.0x, but measured \
        \(medianDurations) seconds for \(tripletCounts) triplets.
        """
      )
    }
    #expect(
      fittedExponent <= 1.25,
      """
      Expected a fitted scaling exponent no greater than 1.25, but measured \
      \(fittedExponent) from \(medianDurations) seconds at \(tripletCounts) \
      triplets.
      """
    )
  }

  private extension PercentEscapeScannerStressTests {

    @Test("Dense percent-triplet expansion has linear geometric scaling")
    func densePercentTripletExpansionHasLinearGeometricScaling() throws {
      let template = try URITemplate(parsing: "{+x}")
      let tripletCounts = [10_000, 20_000, 40_000, 80_000]
      let repetitions = [64, 32, 16, 8]
      let sampleCount = 5

      _ = try template.evaluateAsString(
        parameters: ["x": .text(String(repeating: "%20", count: tripletCounts[0]))]
      )

      let medianDurations = try medianDenseExpansionDurations(
        template: template,
        tripletCounts: tripletCounts,
        repetitions: repetitions,
        sampleCount: sampleCount
      )
      let adjacentRatios = zip(
        medianDurations.dropFirst(),
        medianDurations.dropLast()
      ).map {
        $0 / $1
      }
      let fittedExponent = fittedScalingExponent(
        sizes: tripletCounts,
        durations: medianDurations
      )

      let shouldReport =
        ProcessInfo.processInfo.environment[
          "HDXL_URI_TEMPLATE_REPORT_PERFORMANCE"
        ] == "1"
      if shouldReport {
        print(
          """
          HARD-01 percent-triplet benchmark: sizes=\(tripletCounts), \
          median-seconds=\(medianDurations), adjacent-ratios=\(adjacentRatios), \
          fitted-exponent=\(fittedExponent)
          """
        )
      }
      expectLinearScaling(
        tripletCounts: tripletCounts,
        medianDurations: medianDurations,
        adjacentRatios: adjacentRatios,
        fittedExponent: fittedExponent
      )
    }

  }

  private extension Duration {

    var seconds: Double {
      let components = self.components
      return Double(components.seconds)
        + Double(components.attoseconds) / 1_000_000_000_000_000_000
    }

  }
#endif
