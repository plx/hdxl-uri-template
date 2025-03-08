import Foundation
import Testing
@testable import HDXLURITemplate

extension Tag {
  @Tag
  static var uriTemplateComponentType: Self
}

@Test(
  "`URITemplateComponentType.allCases` is ordered ascending",
  .tags(.uriTemplateComponentType)
)
private func allCasesOrderedAscending() {
  verifyOrderedAscending(URITemplateComponentType.allCases)
}

@Test(
  "`URITemplateComponentType` has unique descriptions",
  .tags(.uriTemplateComponentType)
)
private func uniqueDescriptions() {
  verifyUniqueStringification(
    URITemplateComponentType.allCases,
    using: \.description
  )
}

@Test(
  "`URITemplateComponentType` has unique debugDescriptions",
  .tags(.uriTemplateComponentType)
)
private func uniqueDebugDescriptions() {
  verifyUniqueStringification(
    URITemplateComponentType.allCases,
    using: \.debugDescription
  )
}
