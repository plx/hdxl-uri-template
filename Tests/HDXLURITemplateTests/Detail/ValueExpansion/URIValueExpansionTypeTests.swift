import Foundation
import Testing
@testable import HDXLURITemplate

extension Tag {
  @Tag
  static var uriValueExpansionType: Self
}

@Suite(.tags(.uriValueExpansionType))
struct URIValueExpansionTypeTests {

  @Test
  private func `allCases ordered ascending`() {
    verifyOrderedAscending(URIValueExpansionType.allCases)
  }
  
  @Test
  private func `unique descriptions`() {
    verifyUniqueStringification(
      URIValueExpansionType.allCases,
      using: \.description
    )
  }
  
  @Test
  private func `unique debugDescriptions`() {
    verifyUniqueStringification(
      URIValueExpansionType.allCases,
      using: \.debugDescription
    )
  }
  
  @Test(arguments: URIValueExpansionType.allCases)
  private func `format-string round-trip`(expansionType: URIValueExpansionType) throws {
    let formatString = expansionType.formatString
    let roundTrippedExpansionType = try #require(URIValueExpansionType(formatString: formatString))
    #expect(
      expansionType == roundTrippedExpansionType,
    """
    Failed to round-trip `\(expansionType)` through intermediate format-string `\(formatString)`!
    """
    )
  }

}
