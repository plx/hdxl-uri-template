import Testing
@testable import HDXLURITemplate

extension Tag {
  @Tag
  static var uriTemplateVariableName: Self
}

@Test(
  "`URITemplateVariableName` fixtures are sensible",
  .tags(.uriTemplateVariableName)
)
private func allCasesOrderedAscending() {
  verifyOrderedAscending(probes)
  verifyAllSatisfy(
    probes,
    explanation: "All probes should be valid.",
    predicate: \.isValid
  )
  verifyPairwiseDistinct(probes)
}

@Test(
  "`URITemplateVariableName` has unique descriptions",
  .tags(.uriTemplateVariableName)
)
private func uniqueDescriptions() {
  verifyUniqueStringification(
    probes,
    using: \.description
  )
}

@Test(
  "`URITemplateVariableName` has unique debugDescriptions",
  .tags(.uriTemplateVariableName)
)
private func uniqueDebugDescriptions() {
  verifyUniqueStringification(
    probes,
    using: \.debugDescription
  )
}

@Test(
  "`URITemplateVariableName` has unique debugDescriptions",
  .tags(.uriTemplateVariableName)
)
private func regularExpressionCompiles() throws {
  let _ = try URITemplateVariableName.prepareValidationRegularExpression()
  // ^ test is this doesn't throw
}

// MARK: Fixtures

private let probeStrings: [String] = [
  "a",
  "ab",
  "abc",
  "abcde",
]

private let probes: [URITemplateVariableName] = probeStrings.map {
  URITemplateVariableName(rawValue: $0)
}
