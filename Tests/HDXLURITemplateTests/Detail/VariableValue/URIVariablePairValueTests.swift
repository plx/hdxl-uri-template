import Testing
@testable import HDXLURITemplate

extension Tag {
  @Tag
  static var uriVariablePairValue: Self
}

@Suite(.tags(.uriVariablePairValue))
struct URIVariablePairValueTests {

  @Test
  private func `fixtures are sensible`() {
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
  "abc",
  "abcde",
  "abcdefg"
].map {
  URIVariableTextValue(rawValue: $0)
}

private let values: [URIVariableTextValue] = [
  "m",
  "mn",
  "mno",
  "mnop",
  "mnoq"
].map {
  URIVariableTextValue(rawValue: $0)
}

private let probes: [URIVariablePairValue] = cartesianProduct(keys,values)
  .map {
    URIVariablePairValue(
      key: $0,
      value: $1
    )
  }
