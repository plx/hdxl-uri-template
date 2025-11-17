import Testing
@testable import HDXLURITemplate

extension Tag {
  @Tag
  static var uriTemplateLiteralComponent: Self
}

@Test(
  "`URITemplateLiteralComponent` test-fixture validation",
  .tags(.uriTemplateLiteralComponent)
)
private func textFixtureIsOk() {
  verifyOrderedAscending(probeStrings)
  verifyOrderedAscending(probes)
  
  verifyAllSatisfy(
    probes,
    explanation: "`URITemplateLiteralComponent.isValid` should be true for all test-fixture probes!",
    predicate: \.isValid
  )
  verifyPairwiseDistinct(probes)
}


@Test(
  "`URITemplateLiteralComponent` has unique descriptions",
  .tags(.uriTemplateLiteralComponent)
)
private func uniqueDescriptions() {
  verifyUniqueStringification(
    probes,
    using: \.description
  )
}

@Test(
  "`URITemplateLiteralComponent` has unique debugDescriptions",
  .tags(.uriTemplateLiteralComponent)
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

private let probes: [URITemplateLiteralComponent] = probeStrings.map {
  URITemplateLiteralComponent(rawValue: $0)
}


