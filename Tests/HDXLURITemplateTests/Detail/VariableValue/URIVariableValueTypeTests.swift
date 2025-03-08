import Foundation
import Testing
@testable import HDXLURITemplate

extension Tag {
  @Tag
  static var uriVariableValueType: Self
}

@Test(
  "`URIVariableValueType.allCases` is ordered ascending",
  .tags(.uriVariableValueType)
)
private func allCasesOrderedAscending() {
  verifyOrderedAscending(URIVariableValueType.allCases)
}

@Test(
  "`URIVariableValueType` has unique descriptions",
  .tags(.uriVariableValueType)
)
private func uniqueDescriptions() {
  verifyUniqueStringification(
    URIVariableValueType.allCases,
    using: \.description
  )
}

@Test(
  "`URIVariableValueType` has unique debugDescriptions",
  .tags(.uriVariableValueType)
)
private func uniqueDebugDescriptions() {
  verifyUniqueStringification(
    URIVariableValueType.allCases,
    using: \.debugDescription
  )
}
