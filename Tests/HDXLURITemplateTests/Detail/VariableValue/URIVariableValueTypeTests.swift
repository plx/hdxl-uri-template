import Foundation
import Testing
@testable import HDXLURITemplate

extension Tag {
  @Tag
  static var uriVariableValueType: Self
}

@Test(
  "`URIVariableValueType.allCases` contains every case",
  .tags(.uriVariableValueType)
)
private func allCasesAreComplete() {
  #expect(
    Set(URIVariableValueType.allCases)
      == [.undefined, .text, .list, .association]
  )
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
