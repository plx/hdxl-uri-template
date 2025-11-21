import Testing
@testable import HDXLURITemplate

extension Tag {
  @Tag
  static var uriTemplateLiteralComponent: Self
}

@Suite(
  "URITemplateLiteralComponent",
  .tags(.uriTemplateLiteralComponent)
)
struct URITemplateLiteralComponentTests {
  @Test
  private func `test-fixture validation`() {
    verifyOrderedAscending(probeStrings)
    verifyOrderedAscending(probes)
    
    verifyAllSatisfy(
      probes,
      explanation: "`URITemplateLiteralComponent.isValid` should be true for all test-fixture probes!",
      predicate: \.isValid
    )
    verifyPairwiseDistinct(probes)
  }


  @Test
  private func `unique descriptions`() {
    verifyUniqueStringification(
      probes,
      using: \.description
    )
  }

  @Test
  private func `unique debugDescription`() {
    verifyUniqueStringification(
      probes,
      using: \.debugDescription
    )
  }

}

// MARK: - Fixtures

private let probeStrings: [String] = [
  "a",
  "ab",
  "abc",
  "abcde"
]

private let probes: [URITemplateLiteralComponent] = probeStrings.map {
  URITemplateLiteralComponent(rawValue: $0)
}


