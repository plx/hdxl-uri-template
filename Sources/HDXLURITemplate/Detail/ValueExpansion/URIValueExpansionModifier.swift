import Foundation

// RFC-derived Code Components in this file are attributed in
// THIRD_PARTY_NOTICES.md.

// -------------------------------------------------------------------------- //
// MARK: URIValueExpansionModifier - Definition
// -------------------------------------------------------------------------- //

internal enum URIValueExpansionModifier {
  
  case unmodified
  case explode
  case prefix(Int)
  
  /// RFC 6570 `max-length` values are the integers `1...9999`.
  internal static let rangeOfValidPrefixCodePointCounts: ClosedRange<Int> = 1...9999
  
}

// -------------------------------------------------------------------------- //
// MARK: - Synthesized Conformances
// -------------------------------------------------------------------------- //

extension URIValueExpansionModifier : Sendable { }
extension URIValueExpansionModifier : Equatable { }
extension URIValueExpansionModifier : Hashable { }

// -------------------------------------------------------------------------- //
// MARK: - Comparable
// -------------------------------------------------------------------------- //

extension URIValueExpansionModifier : Comparable {
  
  internal static func <(
    lhs: URIValueExpansionModifier,
    rhs: URIValueExpansionModifier
  ) -> Bool {
    switch (lhs,rhs) {
    case (.unmodified, .unmodified):
      false
    case (.unmodified, .explode):
      true
    case (.unmodified, .prefix(_)):
      true
    case (.explode, .unmodified):
      false
    case (.explode, .explode):
      false
    case (.explode, .prefix(_)):
      true
    case (.prefix(_), .unmodified):
      false
    case (.prefix(_), .explode):
      false
    case (.prefix(let l), .prefix(let r)):
      l < r
    }
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: - CustomStringConvertible
// -------------------------------------------------------------------------- //

extension URIValueExpansionModifier : CustomStringConvertible {

  internal var description: String {
    switch self {
    case .unmodified:
      ".unmodified"
    case .explode:
      ".explode"
    case .prefix(let codePointCount):
      ".prefix(\(codePointCount))"
    }
  }
}

// -------------------------------------------------------------------------- //
// MARK: URIValueExpansionModifier - CustomDebugStringConvertible
// -------------------------------------------------------------------------- //

extension URIValueExpansionModifier : CustomDebugStringConvertible {

  internal var debugDescription: String {
    switch self {
    case .unmodified:
      "URIValueExpansionModifier.unmodified"
    case .explode:
      "URIValueExpansionModifier.explode"
    case .prefix(let codePointCount):
      "URIValueExpansionModifier.prefix(\(codePointCount))"
    }
  }
}

// -------------------------------------------------------------------------- //
// MARK: URIValueExpansionModifier - CaseIterable
// -------------------------------------------------------------------------- //

extension URIValueExpansionModifier : CaseIterable {
  
  internal typealias AllCases = [URIValueExpansionModifier]
  
  internal static let allCases: AllCases = [
    .unmodified,
    .explode
  ] + URIValueExpansionModifier
    .rangeOfValidPrefixCodePointCounts
    .lazy
    .map {
      .prefix($0)
    }
  
}

// -------------------------------------------------------------------------- //
// MARK:  - Validatable
// -------------------------------------------------------------------------- //

extension URIValueExpansionModifier {
  
  internal var isValid: Bool {
    switch self {
    case .unmodified:
      true
    case .explode:
      true
    case .prefix(let codePointCount):
      URIValueExpansionModifier.rangeOfValidPrefixCodePointCounts.contains(codePointCount)
    }
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: URIValueExpansionModifier - Core API
// -------------------------------------------------------------------------- //

extension URIValueExpansionModifier {
  
  internal var requiresAction: Bool {
    switch self {
    case .unmodified:
      false
    default:
      true
    }
  }
  
  internal var isUnmodifiedType: Bool {
    switch self {
    case .unmodified:
      true
    default:
      false
    }
  }
  
  internal var isExplodeType: Bool {
    switch self {
    case .explode:
      true
    default:
      false
    }
  }
  
  internal var isPrefixType: Bool {
    switch self {
    case .prefix(_):
      true
    default:
      false
    }
  }
  
  internal var modifierType: URIValueExpansionModifierType {
    switch self {
    case .unmodified:
        .unmodified
    case .explode:
        .explode
    case .prefix(_):
        .prefix
    }
  }
  
  internal var templateRepresentation: String {
    switch self {
    case .unmodified:
      ""
    case .explode:
      "*"
    case .prefix(let codePointCount):
      ":\(codePointCount)"
    }
  }
  
}
