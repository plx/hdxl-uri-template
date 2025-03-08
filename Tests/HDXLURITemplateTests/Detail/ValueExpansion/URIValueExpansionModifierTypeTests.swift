import Testing
@testable import HDXLURITemplate

extension Tag {
  @Tag
  static var uriValueExpansionModifierType: Self
}

@Test(
  "`URIValueExpansionModifierType.allCases` is ordered ascending",
  .tags(.uriValueExpansionModifierType)
)
private func allCasesOrderedAscending() {
  verifyOrderedAscending(URIValueExpansionModifierType.allCases)
}

@Test(
  "`URIValueExpansionModifierType` has unique descriptions",
  .tags(.uriValueExpansionModifierType)
)
private func uniqueDescriptions() {
  verifyUniqueStringification(
    URIValueExpansionModifierType.allCases,
    using: \.description
  )
}

@Test(
  "`URIValueExpansionModifierType` has unique debugDescriptions",
  .tags(.uriValueExpansionModifierType)
)
private func uniqueDebugDescriptions() {
  verifyUniqueStringification(
    URIValueExpansionModifierType.allCases,
    using: \.debugDescription
  )
}
