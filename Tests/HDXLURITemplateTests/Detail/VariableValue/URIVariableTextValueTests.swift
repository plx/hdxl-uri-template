import Testing
@testable import HDXLURITemplate

extension Tag {
  @Tag
  static var uriVariableTextValue: Self
}

@Suite(.tags(.uriVariableTextValue))
struct URIVariableTextValueTests {
  
  @Test
  private func `fixtures are sensible`() {
    verifyOrderedAscending(probeStrings)
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
  
  @Test(arguments: probes)
  private func `isEmpty`(probe: URIVariableTextValue) {
    #expect(probe.isEmpty == probe.rawValue.isEmpty)
  }

}

// MARK: - Fixtures

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

