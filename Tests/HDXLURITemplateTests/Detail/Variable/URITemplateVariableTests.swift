import Testing
@testable import HDXLURITemplate

extension Tag {
  @Tag
  static var uriTemplateVariable: Self
}

@Test(
  "`URITemplateVariable` fixtures are sensible",
  .tags(.uriTemplateVariable)
)
private func allCasesOrderedAscending() {
  verifyOrderedAscending(probes)
  verifyAllSatisfy(
    probes,
    explanation: "All probes should be valid.",
    predicate: \.isValid
  )
}

@Test(
  "`URITemplateVariable` has unique descriptions",
  .tags(.uriTemplateVariable)
)
private func uniqueDescriptions() {
  verifyUniqueStringification(
    probes,
    using: \.description
  )
}

@Test(
  "`URIValueExpansionType` has unique debugDescriptions",
  .tags(.uriTemplateVariable)
)
private func uniqueDebugDescriptions() {
  verifyUniqueStringification(
    probes,
    using: \.debugDescription
  )
}

// MARK: Fixtures

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
    variableName: URITemplateVariableName(storage: $0),
    expansionModifier: $1
  )
}
