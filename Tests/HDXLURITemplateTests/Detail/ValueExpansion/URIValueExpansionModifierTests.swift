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
  .tags(.uriValueExpansionModifier)
)
private func requiresActionOK() {
  for expansionModifier in URIValueExpansionModifier.allCases {
    switch expansionModifier {
    case .unmodified:
      #expect(
        !expansionModifier.requiresAction,
        """
        Unexpected `requiresAction` for \
        \(String(reflecting: expansionModifier)).
        """
      )
    case .explode, .prefix:
      #expect(
        expansionModifier.requiresAction,
        """
        Unexpected `requiresAction` for \
        \(String(reflecting: expansionModifier)).
        """
      )
    }
  }
}

@Test(
  "`URIValueExpansionModifier` is-type checks",
  .tags(.uriValueExpansionModifier)
)
private func isTypeChecks() {
  for expansionModifier in URIValueExpansionModifier.allCases {
    let expectedType: URIValueExpansionModifierType
    switch expansionModifier {
    case .unmodified:
      expectedType = .unmodified
    case .explode:
      expectedType = .explode
    case .prefix:
      expectedType = .prefix
    }

    #expect(
      expansionModifier.isUnmodifiedType
        == (expectedType == .unmodified),
      """
      Unexpected `isUnmodifiedType` for \
      \(String(reflecting: expansionModifier)).
      """
    )
    #expect(
      expansionModifier.isExplodeType == (expectedType == .explode),
      """
      Unexpected `isExplodeType` for \
      \(String(reflecting: expansionModifier)).
      """
    )
    #expect(
      expansionModifier.isPrefixType == (expectedType == .prefix),
      """
      Unexpected `isPrefixType` for \
      \(String(reflecting: expansionModifier)).
      """
    )
    #expect(
      expansionModifier.modifierType == expectedType,
      """
      Unexpected `modifierType` for \
      \(String(reflecting: expansionModifier)).
      """
    )
  }
}
