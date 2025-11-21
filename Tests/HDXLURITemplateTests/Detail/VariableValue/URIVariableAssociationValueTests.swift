import Testing
@testable import HDXLURITemplate

extension Tag {
  @Tag
  static var uriVariableAssociationValue: Self
}

@Suite(.tags(.uriVariableAssociationValue))
struct URIVariableAssociationValueTests {

  @Test
  private func `fixtures are sensible`() {
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
  
  
  @Test
  private func `unique descriptions`() {
    verifyUniqueStringification(
      probes,
      using: \.description
    )
  }
  
  @Test
  private func `unique debugDescriptions`() {
    verifyUniqueStringification(
      probes,
      using: \.debugDescription
    )
  }

}

// MARK: - Fixtures

private let keys: [URIVariableTextValue] = [
  "a",
  "ab",
  "abc"
].map {
  URIVariableTextValue(rawValue: $0)
}

private let values: [URIVariableTextValue] = [
  "m",
  "mn",
  "mno"
].map {
  URIVariableTextValue(rawValue: $0)
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

