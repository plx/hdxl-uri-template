import Foundation

// -------------------------------------------------------------------------- //
// MARK: URIValueExpansionModifier - Definition
// -------------------------------------------------------------------------- //

@usableFromInline
internal enum URIValueExpansionModifier {
  
  case unmodified
  case explode
  case prefix(Int)
  
  /// RFC 6570 `max-length` values are the integers `1...9999`.
  @usableFromInline
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
  
  @inlinable
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

  @inlinable
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

  @inlinable
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
// MARK: URIValueExpansionModifier - Codable
// -------------------------------------------------------------------------- //

extension URIValueExpansionModifier : Codable {

  @usableFromInline
  internal typealias CodingKeys = StandardEnumerationCodingKeys
  
  @inlinable
  internal func encode(to encoder: Encoder) throws {
    var container = encoder.container(
      keyedBy: CodingKeys.self
    )
    try container.encode(
      self.modifierType,
      forKey: .type
    )
    switch self {
    case .unmodified:
      ();
    case .explode:
      ();
    case .prefix(let codePointCount):
      try container.encode(
        codePointCount,
        forKey: .data
      )
    }
  }
  
  @inlinable
  init(from decoder: Decoder) throws {
    let container = try decoder.container(
      keyedBy: CodingKeys.self
    )
    let type = try container.decode(
      URIValueExpansionModifierType.self,
      forKey: .type
    )
    switch type {
    case .unmodified:
      self = .unmodified
    case .explode:
      self = .explode
    case .prefix:
      let codePointCount = try container.decode(
        Int.self,
        forKey: .data
      )
      guard URIValueExpansionModifier.rangeOfValidPrefixCodePointCounts.contains(codePointCount) else {
        let problemDescription: String = "Decoded out-of-range `codePointCount` \(codePointCount)!"
        if codePointCount < URIValueExpansionModifier.rangeOfValidPrefixCodePointCounts.lowerBound {
          throw DataValidationError(
            forType: URIValueExpansionModifier.self,
            problemDescription: problemDescription,
            repairDescription: "Could replace with minimum `codePointCount` of \(URIValueExpansionModifier.rangeOfValidPrefixCodePointCounts.lowerBound)",
            repairSuggestion: .prefix(URIValueExpansionModifier.rangeOfValidPrefixCodePointCounts.lowerBound)
          )
        } else {
          throw DataValidationError(
            forType: URIValueExpansionModifier.self,
            problemDescription: problemDescription,
            repairDescription: "Could replace with maximum `codePointCount` of \(URIValueExpansionModifier.rangeOfValidPrefixCodePointCounts.upperBound)",
            repairSuggestion: .prefix(URIValueExpansionModifier.rangeOfValidPrefixCodePointCounts.upperBound)
          )
        }
      }
      self = .prefix(codePointCount)
    }
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: URIValueExpansionModifier - CaseIterable
// -------------------------------------------------------------------------- //

extension URIValueExpansionModifier : CaseIterable {
  
  @usableFromInline
  internal typealias AllCases = [URIValueExpansionModifier]
  
  @usableFromInline
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
  
  @inlinable
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
  
  @inlinable
  internal var requiresAction: Bool {
    switch self {
    case .unmodified:
      false
    default:
      true
    }
  }
  
  @inlinable
  internal var isUnmodifiedType: Bool {
    switch self {
    case .unmodified:
      true
    default:
      false
    }
  }
  
  @inlinable
  internal var isExplodeType: Bool {
    switch self {
    case .explode:
      true
    default:
      false
    }
  }
  
  @inlinable
  internal var isPrefixType: Bool {
    switch self {
    case .prefix(_):
      true
    default:
      false
    }
  }
  
  @inlinable
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
  
  @inlinable
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
