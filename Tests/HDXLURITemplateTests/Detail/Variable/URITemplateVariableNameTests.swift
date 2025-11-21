import Testing
@testable import HDXLURITemplate

extension Tag {
  @Tag
  static var uriTemplateVariableName: Self
}

@Suite(.tags(.uriTemplateVariableName))
struct URITemplateVariableNameTests {

  @Test
  private func `fixtures are sensible`() {
    verifyOrderedAscending(probes)
    verifyAllSatisfy(
      probes,
      explanation: "All probes should be valid.",
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
  
  @Test
  private func `validation regex compiles`() throws {
    let _ = try URITemplateVariableName.prepareValidationRegularExpression()
    // ^ test is this doesn't throw
  }

}

// MARK: - Fixtures

private let probeStrings: [String] = [
  "a",
  "ab",
  "abc",
  "abcde"
]

private let probes: [URITemplateVariableName] = probeStrings.map {
  URITemplateVariableName(rawValue: $0)
}
