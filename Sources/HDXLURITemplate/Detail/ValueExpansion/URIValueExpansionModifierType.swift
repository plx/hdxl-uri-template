import Foundation

// -------------------------------------------------------------------------- //
// MARK: URIValueExpansionModifierType - Definition
// -------------------------------------------------------------------------- //

internal enum URIValueExpansionModifierType: UInt8 {

  case unmodified = 1
  case explode = 2
  case prefix = 4

}

// -------------------------------------------------------------------------- //
// MARK: - Synthesized Conformances
// -------------------------------------------------------------------------- //

extension URIValueExpansionModifierType: Sendable {}
extension URIValueExpansionModifierType: Equatable {}
extension URIValueExpansionModifierType: Hashable {}
extension URIValueExpansionModifierType: CaseIterable {}

// -------------------------------------------------------------------------- //
// MARK: - Comparable
// -------------------------------------------------------------------------- //

extension URIValueExpansionModifierType: Comparable {

  internal static func < (
    lhs: URIValueExpansionModifierType,
    rhs: URIValueExpansionModifierType
  ) -> Bool {
    lhs.rawValue < rhs.rawValue
  }

}

// -------------------------------------------------------------------------- //
// MARK: - CustomStringConvertible
// -------------------------------------------------------------------------- //

extension URIValueExpansionModifierType: CustomStringConvertible {

  internal var description: String {
    switch self {
    case .unmodified:
      ".unmodified"
    case .explode:
      ".explode"
    case .prefix:
      ".prefix"
    }
  }
}

// -------------------------------------------------------------------------- //
// MARK: - CustomDebugStringConvertible
// -------------------------------------------------------------------------- //

extension URIValueExpansionModifierType: CustomDebugStringConvertible {

  internal var debugDescription: String {
    switch self {
    case .unmodified:
      "URIValueExpansionModifierType.unmodified"
    case .explode:
      "URIValueExpansionModifierType.explode"
    case .prefix:
      "URIValueExpansionModifierType.prefix"
    }
  }
}
