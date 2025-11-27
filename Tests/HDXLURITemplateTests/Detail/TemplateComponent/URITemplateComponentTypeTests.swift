import Foundation
import Testing
@testable import HDXLURITemplate

extension Tag {
  @Tag
  static var uriTemplateComponentType: Self
}

@Suite(.tags(.uriTemplateComponentType))
struct URITemplateComponentTypeTests {
  
  @Test
  private func `allCases ordered ascending`() {
    verifyOrderedAscending(URITemplateComponentType.allCases)
  }

  @Test
  private func `unique descriptions`() {
    verifyUniqueStringification(
      URITemplateComponentType.allCases,
      using: \.description
    )
  }
  
  @Test
  private func `unique debugDescriptions`() {
    verifyUniqueStringification(
      URITemplateComponentType.allCases,
      using: \.debugDescription
    )
  }

}
