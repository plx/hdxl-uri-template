import Testing
@testable import HDXLURITemplate

extension Tag {
  @Tag
  static var uriVariablePairValue: Self
}

@Test(
  "`URIVariablePairValue` fixtures",
  .tags(.uriVariablePairValue)
)
private func validateFixtures() {
  verifyOrderedAscending(keys)
  verifyOrderedAscending(values)
  verifyOrderedAscending(probes)
  
  verifyAllSatisfy(
    probes,
    explanation: "Expect all probes to be valid.",
    predicate: \.isValid
  )
  
  verifyPairwiseDistinct(probes)
}


@Test(
  "`URIVariablePairValue` has unique descriptions",
  .tags(.uriVariablePairValue)
)
private func uniqueDescriptions() {
  verifyUniqueStringification(
    probes,
    using: \.description
  )
}

@Test(
  "`URIVariablePairValue` has unique debugDescriptions",
  .tags(.uriVariablePairValue)
)
private func uniqueDebugDescriptions() {
  verifyUniqueStringification(
    probes,
    using: \.debugDescription
  )
}

// MARK: Fixtures

private let keys: [URIVariableTextValue] = [
  "a",
  "ab",
  "abc",
  "abcde",
  "abcdefg"
].map {
  URIVariableTextValue(text: $0)
}

private let values: [URIVariableTextValue] = [
  "m",
  "mn",
  "mno",
  "mnop",
  "mnoq"
].map {
  URIVariableTextValue(text: $0)
}

private let probes: [URIVariablePairValue] = cartesianProduct(keys,values)
  .map {
    URIVariablePairValue(
      key: $0,
      value: $1
    )
  }
