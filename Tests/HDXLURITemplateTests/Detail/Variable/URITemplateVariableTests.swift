import Testing
@testable import HDXLURITemplate

extension Tag {
  @Tag
  static var uriTemplateVariable: Self
}

@Suite(.tags(.uriTemplateVariable))
struct URITemplateVariableTests {

  @Test
  private func `fixtures are sensible`() {
    verifyOrderedAscending(probes)
    verifyAllSatisfy(
      probes,
      explanation: "All probes should be valid.",
      predicate: \.isValid
    )
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

private let probeStrings: [String] = [
  "a",
  "ab",
  "abc",
  "abcde"
]

private let probes: [URITemplateVariable] = cartesianProduct(
  probeStrings,
  URIValueExpansionModifier.allCases[0...10]
).map {
  URITemplateVariable(
    variableName: URITemplateVariableName(rawValue: $0),
    expansionModifier: $1
  )
}
