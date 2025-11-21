import Testing
@testable import HDXLURITemplate

extension Tag {
  @Tag
  static var uriValueExpansionModifierType: Self
}

@Suite(.tags(.uriValueExpansionModifierType))
struct URIValueExpansionModifierTypeTests {
  
  @Test
  private func `allCases ordered ascending`() {
    verifyOrderedAscending(URIValueExpansionModifierType.allCases)
  }
  
  @Test
  private func `unique descriptions`() {
    verifyUniqueStringification(
      URIValueExpansionModifierType.allCases,
      using: \.description
    )
  }
  
  @Test
  private func `unique debugDescriptions`() {
    verifyUniqueStringification(
      URIValueExpansionModifierType.allCases,
      using: \.debugDescription
    )
  }

}
