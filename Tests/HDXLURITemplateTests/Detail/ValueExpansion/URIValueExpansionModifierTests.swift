import Testing
@testable import HDXLURITemplate

extension Tag {
  @Tag
  static var uriValueExpansionModifier: Self
}

@Test(
  "`URIValueExpansionModifier.allCases` is ordered ascending",
  .tags(.uriValueExpansionModifier)
)
private func allCasesOrderedAscending() {
  verifyOrderedAscending(URIValueExpansionModifier.allCases)
}

@Test(
  "`URIValueExpansionModifier` has unique descriptions",
  .tags(.uriValueExpansionModifier)
)
private func uniqueDescriptions() {
  verifyUniqueStringification(
    URIValueExpansionModifier.allCases,
    using: \.description
  )
}

@Test(
  "`URIValueExpansionModifier` has unique debugDescriptions",
  .tags(.uriValueExpansionModifier)
)
private func uniqueDebugDescriptions() {
  verifyUniqueStringification(
    URIValueExpansionModifier.allCases,
    using: \.debugDescription
  )
}

@Test(
  "`URIValueExpansionModifier.requiresAction`",
  .tags(.uriValueExpansionModifier),
  arguments: URIValueExpansionModifier.allCases
)
private func requiresActionOK(expansionModifier: URIValueExpansionModifier) throws {
  switch expansionModifier {
  case .unmodified:
    #expect(!expansionModifier.requiresAction)
  case .explode:
    #expect(expansionModifier.requiresAction)
  case .prefix:
    #expect(expansionModifier.requiresAction)
  }
}

@Test(
  "`URIValueExpansionModifier` is-type checks",
  .tags(.uriValueExpansionModifier),
  arguments: URIValueExpansionModifier.allCases
)
private func isTypeChecks(expansionModifier: URIValueExpansionModifier) throws {
  switch expansionModifier {
  case .unmodified:
    #expect(expansionModifier.isUnmodifiedType)
    #expect(!expansionModifier.isExplodeType)
    #expect(!expansionModifier.isPrefixType)
    #expect(expansionModifier.modifierType == .unmodified)
  case .explode:
    #expect(!expansionModifier.isUnmodifiedType)
    #expect(expansionModifier.isExplodeType)
    #expect(!expansionModifier.isPrefixType)
    #expect(expansionModifier.modifierType == .explode)
  case .prefix:
    #expect(!expansionModifier.isUnmodifiedType)
    #expect(!expansionModifier.isExplodeType)
    #expect(expansionModifier.isPrefixType)
    #expect(expansionModifier.modifierType == .prefix)
  }
}


// MARK: Fixtures

private let probes = URIValueExpansionModifier.allCases
private let reducedProbes = Array(probes[0..<25])
