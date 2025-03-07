//
//  URIValueExpansionModifier.swift
//

import Foundation

// -------------------------------------------------------------------------- //
// MARK: URIValueExpansionModifier - Definition
// -------------------------------------------------------------------------- //

@frozen
@usableFromInline
internal enum URIValueExpansionModifier {
  
  case unmodified
  case explode
  case prefix(Int)
  
  /// - todo: Verify my interpretation of "positive integer < 10000" as excluding `0`
  @usableFromInline
  internal static let rangeOfValidPrefixCodePointCounts: ClosedRange<Int> = 1...9999
  
}

// -------------------------------------------------------------------------- //
// MARK: URIValueExpansionModifier - Core API
// -------------------------------------------------------------------------- //

internal extension URIValueExpansionModifier {
  
  @inlinable
  var requiresAction: Bool {
    get {
      switch self {
      case .unmodified:
        return false
      default:
        return true
      }
    }
  }
  
  @inlinable
  var isUnmodifiedType: Bool {
    get {
      switch self {
      case .unmodified:
        return true
      default:
        return false
      }
    }
  }
  
  @inlinable
  var isExplodeType: Bool {
    get {
      switch self {
      case .explode:
        return true
      default:
        return false
      }
    }
  }
  
  @inlinable
  var isPrefixType: Bool {
    get {
      switch self {
      case .prefix(_):
        return true
      default:
        return false
      }
    }
  }
  
  @inlinable
  var modifierType: URIValueExpansionModifierType {
    get {
      switch self {
      case .unmodified:
        return .unmodified
      case .explode:
        return .explode
      case .prefix(_):
        return .prefix
      }
    }
  }
  
  @inlinable
  var templateRepresentation: String {
    get {
      switch self {
      case .unmodified:
        return ""
      case .explode:
        return "*"
      case .prefix(let codePointCount):
        return ":\(codePointCount)"
      }
    }
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: URIValueExpansionModifier - Validatable
// -------------------------------------------------------------------------- //

extension URIValueExpansionModifier {
  
  @inlinable
  internal var isValid: Bool {
    get {
      switch self {
      case .unmodified:
        return true
      case .explode:
        return true
      case .prefix(let codePointCount):
        return URIValueExpansionModifier.rangeOfValidPrefixCodePointCounts.contains(codePointCount)
      }
    }
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: URIValueExpansionModifier - Equatable
// -------------------------------------------------------------------------- //

extension URIValueExpansionModifier : Equatable {
  
  @inlinable
  internal static func ==(
    lhs: URIValueExpansionModifier,
    rhs: URIValueExpansionModifier) -> Bool {
    switch (lhs,rhs) {
    case (.unmodified, .unmodified):
      return true
    case (.explode, .explode):
      return true
    case (.prefix(let l), .prefix(let r)):
      return l == r
    default:
      return false
    }
  }

}

// -------------------------------------------------------------------------- //
// MARK: URIValueExpansionModifier - Comparable
// -------------------------------------------------------------------------- //

extension URIValueExpansionModifier : Comparable {
  
  @inlinable
  internal static func <(
    lhs: URIValueExpansionModifier,
    rhs: URIValueExpansionModifier) -> Bool {
    switch (lhs,rhs) {
    case (.unmodified, .unmodified):
      return false
    case (.unmodified, .explode):
      return true
    case (.unmodified, .prefix(_)):
      return true
    case (.explode, .unmodified):
      return false
    case (.explode, .explode):
      return false
    case (.explode, .prefix(_)):
      return true
    case (.prefix(_), .unmodified):
      return false
    case (.prefix(_), .explode):
      return false
    case (.prefix(let l), .prefix(let r)):
      return l < r
    }
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: URIValueExpansionModifier - Hashable
// -------------------------------------------------------------------------- //

extension URIValueExpansionModifier : Hashable {
  
  @inlinable
  internal func hash(into hasher: inout Hasher) {
    switch self {
    case .unmodified:
      URIValueExpansionModifierType.unmodified.hash(into: &hasher)
    case .explode:
      URIValueExpansionModifierType.explode.hash(into: &hasher)
    case .prefix(let codePointCount):
      URIValueExpansionModifierType.prefix.hash(into: &hasher)
      codePointCount.hash(into: &hasher)
    }
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: URIValueExpansionModifier - CustomStringConvertible
// -------------------------------------------------------------------------- //

extension URIValueExpansionModifier : CustomStringConvertible {

  @inlinable
  internal var description: String {
    get {
      switch self {
      case .unmodified:
        return ".unmodified"
      case .explode:
        return ".explode"
      case .prefix(let codePointCount):
        return ".prefix(\(codePointCount))"
      }
    }
  }
}

// -------------------------------------------------------------------------- //
// MARK: URIValueExpansionModifier - CustomDebugStringConvertible
// -------------------------------------------------------------------------- //

extension URIValueExpansionModifier : CustomDebugStringConvertible {

  @inlinable
  internal var debugDescription: String {
    get {
      switch self {
      case .unmodified:
        return "URIValueExpansionModifier.unmodified"
      case .explode:
        return "URIValueExpansionModifier.explode"
      case .prefix(let codePointCount):
        return "URIValueExpansionModifier.prefix(\(codePointCount))"
      }
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
            repairSuggestion: .prefix(URIValueExpansionModifier.rangeOfValidPrefixCodePointCounts.upperBound)
          )
        } else if codePointCount > URIValueExpansionModifier.rangeOfValidPrefixCodePointCounts.upperBound {
          throw DataValidationError(
            forType: URIValueExpansionModifier.self,
            problemDescription: problemDescription,
            repairDescription: "Could replace with maximum `codePointCount` of \(URIValueExpansionModifier.rangeOfValidPrefixCodePointCounts.upperBound)",
            repairSuggestion: .prefix(URIValueExpansionModifier.rangeOfValidPrefixCodePointCounts.upperBound)
          )
        } else {
          fatalError("Reached highly-unexpected code point count.")
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
  
  @inlinable
  internal static var allCases: AllCases {
    get {
      var result: AllCases = [
        .unmodified,
        .explode
      ]
      result.append(
        contentsOf: URIValueExpansionModifier
          .rangeOfValidPrefixCodePointCounts
          .lazy
          .map() {
            .prefix($0)
        }
      )
      return result
    }
  }
  
}
