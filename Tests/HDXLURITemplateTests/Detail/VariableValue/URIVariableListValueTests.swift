import Testing
@testable import HDXLURITemplate

extension Tag {
  @Tag
  static var uriVariableListValue: Self
}

@Suite(.tags(.uriVariableListValue))
struct URIVariableListValueTests {

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
  private func `isEmpty`(probe: URIVariableListValue) {
    #expect(probe.isEmpty == probe.storage.isEmpty)
  }

}

// MARK: - Fixtures

private let probeStrings: [String] = [
  "",
  "a",
  "ab",
  "abc",
  "abcd",
  "abcde",
  "abcdef",
  "abcdefg"
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
