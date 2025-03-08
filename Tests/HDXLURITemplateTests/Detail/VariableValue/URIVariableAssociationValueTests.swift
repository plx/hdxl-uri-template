import Testing
@testable import HDXLURITemplate

extension Tag {
  @Tag
  static var uriVariableAssociationValue: Self
}

@Test(
  "`URIVariableAssociationValue` fixtures",
  .tags(.uriVariableAssociationValue)
)
private func validateFixtures() {
  verifyOrderedAscending(keys)
  verifyOrderedAscending(values)
  verifyOrderedAscending(pairs)
  verifyOrderedAscending(probes)
  
  verifyAllSatisfy(
    probes,
    explanation: "Expect all probes to be valid.",
    predicate: \.isValid
  )
  
  verifyPairwiseDistinct(probes)
}


@Test(
  "`URIVariableAssociationValue` has unique descriptions",
  .tags(.uriVariableAssociationValue)
)
private func uniqueDescriptions() {
  verifyUniqueStringification(
    probes,
    using: \.description
  )
}

@Test(
  "`URIVariableAssociationValue` has unique debugDescriptions",
  .tags(.uriVariableAssociationValue)
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
  "abc"
].map {
  URIVariableTextValue(text: $0)
}

private let values: [URIVariableTextValue] = [
  "m",
  "mn",
  "mno"
].map {
  URIVariableTextValue(text: $0)
}

private let pairs: [URIVariablePairValue] = cartesianProduct(keys,values)
  .map {
    URIVariablePairValue(
      key: $0,
      value: $1
    )
  }
  .dropLast()
  .sorted()

private let probes: [URIVariableAssociationValue] = pairs
  .smallPowerSet
  .filter { subset in
    Set(subset.lazy.map(\.key)).count == subset.count
  }
  .map {
    URIVariableAssociationValue(values: $0)
  }
  .sorted()

