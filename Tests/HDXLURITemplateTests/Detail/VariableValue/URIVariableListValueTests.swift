import Testing
@testable import HDXLURITemplate

extension Tag {
  @Tag
  static var uriVariableListValue: Self
}

@Test(
  "`URIVariableListValue` fixtures",
  .tags(.uriVariableListValue)
)
private func validateFixtures() {
  verifyOrderedAscending(probeStrings)
  verifyOrderedAscending(probes)

  verifyAllSatisfy(
    probes,
    explanation: "Expect all probes to be valid.",
    predicate: \.isValid
  )

  verifyPairwiseDistinct(probes)
}

@Test(
  "`URIVariableListValue` has unique descriptions",
  .tags(.uriVariableListValue)
)
private func uniqueDescriptions() {
  verifyUniqueStringification(
    probes,
    using: \.description
  )
}

@Test(
  "`URIVariablePairValue` has unique debugDescriptions",
  .tags(.uriVariableListValue)
)
private func uniqueDebugDescriptions() {
  verifyUniqueStringification(
    probes,
    using: \.debugDescription
  )
}

@Test(
  "`URIVariablePairValue` isEmpty coherence",
  .tags(.uriVariableListValue),
  arguments: probes
)
private func isEmptyCoherence(probe: URIVariableListValue) {
  #expect(probe.isEmpty == probe.storage.isEmpty)
}

// MARK: Fixtures

private let probeStrings: [String] = [
  "",
  "a",
  "ab",
  "abc",
  "abcd",
  "abcde",
  "abcdef",
  "abcdefg",
]

private let probes: [URIVariableListValue] = probeStrings
  .smallPowerSet
  .map { strings in
    URIVariableListValue(
      values: strings.map {
        URIVariableTextValue(rawValue: $0)
      }
    )
  }
  .sorted()
