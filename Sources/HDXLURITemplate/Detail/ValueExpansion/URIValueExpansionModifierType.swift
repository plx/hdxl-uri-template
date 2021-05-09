//
//  URIValueExpansionModifierType.swift
//

import Foundation

// -------------------------------------------------------------------------- //
// MARK: URIValueExpansionModifierType - Definition
// -------------------------------------------------------------------------- //

@frozen
@usableFromInline
internal enum URIValueExpansionModifierType : UInt8 {
  
  case unmodified = 1
  case explode = 2
  case prefix = 4
  
}

// -------------------------------------------------------------------------- //
// MARK: URIValueExpansionModifierType - Equatable
// -------------------------------------------------------------------------- //

extension URIValueExpansionModifierType : Equatable {
  
  @inlinable
  internal static func ==(
    lhs: URIValueExpansionModifierType,
    rhs: URIValueExpansionModifierType) -> Bool {
    return lhs.rawValue == rhs.rawValue
  }
  
  @inlinable
  internal static func !=(
    lhs: URIValueExpansionModifierType,
    rhs: URIValueExpansionModifierType) -> Bool {
    return lhs.rawValue != rhs.rawValue
  }

}

// -------------------------------------------------------------------------- //
// MARK: URIValueExpansionModifierType - Comparable
// -------------------------------------------------------------------------- //

extension URIValueExpansionModifierType : Comparable {
  
  @inlinable
  internal static func <(
    lhs: URIValueExpansionModifierType,
    rhs: URIValueExpansionModifierType) -> Bool {
    return lhs.rawValue < rhs.rawValue
  }
  
  @inlinable
  internal static func >(
    lhs: URIValueExpansionModifierType,
    rhs: URIValueExpansionModifierType) -> Bool {
    return lhs.rawValue > rhs.rawValue
  }
  
  @inlinable
  internal static func <=(
    lhs: URIValueExpansionModifierType,
    rhs: URIValueExpansionModifierType) -> Bool {
    return lhs.rawValue <= rhs.rawValue
  }
  
  @inlinable
  internal static func >=(
    lhs: URIValueExpansionModifierType,
    rhs: URIValueExpansionModifierType) -> Bool {
    return lhs.rawValue >= rhs.rawValue
  }

}

// -------------------------------------------------------------------------- //
// MARK: URIValueExpansionModifierType - Hashable
// -------------------------------------------------------------------------- //

extension URIValueExpansionModifierType : Hashable {
  
  @inlinable
  internal func hash(into hasher: inout Hasher) {
    self.rawValue.hash(into: &hasher)
  }

}

// -------------------------------------------------------------------------- //
// MARK: URIValueExpansionModifierType - CustomStringConvertible
// -------------------------------------------------------------------------- //

extension URIValueExpansionModifierType : CustomStringConvertible {
  
  @inlinable
  internal var description: String {
    get {
      switch self {
      case .unmodified:
        return "unmodified"
      case .explode:
        return "explode"
      case .prefix:
        return "prefix"
      }
    }
  }
}

// -------------------------------------------------------------------------- //
// MARK: URIValueExpansionModifierType - CustomDebugStringConvertible
// -------------------------------------------------------------------------- //

extension URIValueExpansionModifierType : CustomDebugStringConvertible {
  
  @inlinable
  internal var debugDescription: String {
    get {
      switch self {
      case .unmodified:
        return "URIValueExpansionModifierType.unmodified"
      case .explode:
        return "URIValueExpansionModifierType.explode"
      case .prefix:
        return "URIValueExpansionModifierType.prefix"
      }
    }
  }
}

// -------------------------------------------------------------------------- //
// MARK: URIValueExpansionModifierType - Codable
// -------------------------------------------------------------------------- //

extension URIValueExpansionModifierType : Codable {
    
  // synthesized ok
  
}

// -------------------------------------------------------------------------- //
// MARK: URIValueExpansionModifierType - CaseIterable
// -------------------------------------------------------------------------- //

extension URIValueExpansionModifierType : CaseIterable {
  
  @usableFromInline
  internal typealias AllCases = [URIValueExpansionModifierType]
  
  @inlinable
  internal static var allCases: AllCases {
    get {
      return [
        .unmodified,
        .explode,
        .prefix
      ]
    }
  }
  
}
