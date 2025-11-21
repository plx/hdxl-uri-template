import Foundation
import Testing
@testable import HDXLURITemplate

extension Tag {
  @Tag
  static var uriVariableValueType: Self
}

@Suite(.tags(.uriVariableValueType))
struct URIVariableValueTypeTests {

  @Test
  private func `allCases ordered ascending`() {
    verifyOrderedAscending(URIVariableValueType.allCases)
  }
  
  @Test
  private func `unique descriptions`() {
    verifyUniqueStringification(
      URIVariableValueType.allCases,
      using: \.description
    )
  }
  
  @Test
  private func `unique debugDescriptions`() {
    verifyUniqueStringification(
      URIVariableValueType.allCases,
      using: \.debugDescription
    )
  }

}
