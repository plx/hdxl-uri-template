import Testing
@testable import HDXLURITemplate

extension Tag {
  @Tag
  static var uriVariableTextValue: Self
}

@Test(
  "`URIVariableTextValue` fixtures",
  .tags(.uriVariableTextValue)
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
  "`URIVariableTextValue` has unique descriptions",
  .tags(.uriVariableTextValue)
)
private func uniqueDescriptions() {
  verifyUniqueStringification(
    probes,
    using: \.description
  )
}

@Test(
  "`URIVariableTextValue` has unique debugDescriptions",
  .tags(.uriVariableTextValue)
)
private func uniqueDebugDescriptions() {
  verifyUniqueStringification(
    probes,
    using: \.debugDescription
  )
}

@Test(
  "`URIVariableTextValue` isEmpty coherence",
  .tags(.uriVariableTextValue),
  arguments: probes
)
private func isEmptyCoherence(probe: URIVariableTextValue) {
  #expect(probe.isEmpty == probe.rawValue.isEmpty)
}

// MARK: Fixtures

private let probeStrings: [String] = [
  "",
  "a",
  "ab",
  "abc",
  "abcde"
]

private let probes: [URIVariableTextValue] = probeStrings.map {
  URIVariableTextValue(rawValue: $0)
}

