import Testing
@testable import HDXLURITemplate

extension Tag {
  @Tag
  static var uriValueExpansionModifier: Self
}

@Suite(.tags(.uriValueExpansionModifier))
struct URIValueExpansionModifierTests {
  
  private let expansionModifiers = URIValueExpansionModifier.allCases
  
  @Test
  private func `allCases ordered ascending`() {
    verifyOrderedAscending(URIValueExpansionModifier.allCases)
  }
  
  @Test
  private func `unique descriptions`() {
    verifyUniqueStringification(
      URIValueExpansionModifier.allCases,
      using: \.description
    )
  }
  
  @Test
  private func `unique debugDescriptions`() {
    verifyUniqueStringification(
      URIValueExpansionModifier.allCases,
      using: \.debugDescription
    )
  }
  
  @Test
  private func `requiresAction`() throws {
    // this is ~10000 cases, Xcode's GUI *cannot* handle
    // having that many individually-runnable test cases,
    // and thus we can't use `@Test(arguments: URIValueExpansionModifier.allCases)`
    for expansionModifier in expansionModifiers {
      switch expansionModifier {
      case .unmodified:
        #expect(!expansionModifier.requiresAction)
      case .explode:
        #expect(expansionModifier.requiresAction)
      case .prefix:
        #expect(expansionModifier.requiresAction)
      }
    }
  }
  
  @Test
  private func `is-type checks`() throws {
    // this is ~10000 cases, Xcode's GUI *cannot* handle
    // having that many individually-runnable test cases,
    // and thus we can't use `@Test(arguments: URIValueExpansionModifier.allCases)`
    for expansionModifier in expansionModifiers {
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
  }

}

// MARK: - Fixtures

private let probes = URIValueExpansionModifier.allCases
private let reducedProbes = Array(probes[0..<25])
