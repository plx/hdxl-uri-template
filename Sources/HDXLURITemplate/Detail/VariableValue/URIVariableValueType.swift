//
//  URIVariableValueType.swift
//

import Foundation
import HDXLCommonUtilities

// -------------------------------------------------------------------------- //
// MARK: URIVariableValueType - Definition
// -------------------------------------------------------------------------- //

/// Case-enumeration for variable *values*, which can be either undefined (`nil`-like),
/// `text` (simple string), `list` (of simple strings), or `association` (*ordered* list
/// of key-value pairs).
///
/// Made public and compatible with Objective-C so as to faciliate use of this
/// package's functionality from Objective-C code.
///
@frozen
@objc(HDXLURIVariableValueType)
public enum URIVariableValueType : UInt8 {
  
  case undefined = 1
  case text = 2
  case list = 4
  case association = 8
  
}

// -------------------------------------------------------------------------- //
// MARK: URIVariableValueType - Equatable
// -------------------------------------------------------------------------- //

extension URIVariableValueType : Equatable {

  @inlinable
  public static func ==(
    lhs: URIVariableValueType,
    rhs: URIVariableValueType) -> Bool {
    return lhs.rawValue == rhs.rawValue
  }
  
  @inlinable
  public static func !=(
    lhs: URIVariableValueType,
    rhs: URIVariableValueType) -> Bool {
    return lhs.rawValue != rhs.rawValue
  }
}


// -------------------------------------------------------------------------- //
// MARK: URIVariableValueType - Comparable
// -------------------------------------------------------------------------- //

extension URIVariableValueType : Comparable {
  
  @inlinable
  public static func <(
    lhs: URIVariableValueType,
    rhs: URIVariableValueType) -> Bool {
    return lhs.rawValue < rhs.rawValue
  }
  
  @inlinable
  public static func >(
    lhs: URIVariableValueType,
    rhs: URIVariableValueType) -> Bool {
    return lhs.rawValue > rhs.rawValue
  }

  @inlinable
  public static func <=(
    lhs: URIVariableValueType,
    rhs: URIVariableValueType) -> Bool {
    return lhs.rawValue <= rhs.rawValue
  }
  
  @inlinable
  public static func >=(
    lhs: URIVariableValueType,
    rhs: URIVariableValueType) -> Bool {
    return lhs.rawValue >= rhs.rawValue
  }

}


// -------------------------------------------------------------------------- //
// MARK: URIVariableValueType - Hashable
// -------------------------------------------------------------------------- //

extension URIVariableValueType : Hashable {
  
  @inlinable
  public func hash(into hasher: inout Hasher) {
    self.rawValue.hash(into: &hasher)
  }

}

// -------------------------------------------------------------------------- //
// MARK: URIVariableValueType - CustomStringConvertible
// -------------------------------------------------------------------------- //

extension URIVariableValueType : CustomStringConvertible {
  
  @inlinable
  public var description: String {
    get {
      switch self {
      case .undefined:
        return "undefined"
      case .text:
        return "text"
      case .list:
        return "list"
      case .association:
        return "association"
      }
    }
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: URIVariableValueType - CustomDebugStringConvertible
// -------------------------------------------------------------------------- //

extension URIVariableValueType : CustomDebugStringConvertible {
  
  @inlinable
  public var debugDescription: String {
    get {
      switch self {
      case .undefined:
        return "URIVariableValueType.undefined"
      case .text:
        return "URIVariableValueType.text"
      case .list:
        return "URIVariableValueType.list"
      case .association:
        return "URIVariableValueType.association"
      }
    }
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: URIVariableValueType - Codable
// -------------------------------------------------------------------------- //

extension URIVariableValueType : Codable {

  // synthesized ok
  
}


// -------------------------------------------------------------------------- //
// MARK: URIVariableValueType - CaseIterable
// -------------------------------------------------------------------------- //

extension URIVariableValueType : CaseIterable {
  
  public typealias AllCases = [URIVariableValueType]
  
  @inlinable
  public static var allCases: [URIVariableValueType] {
    get {
      return [
        .undefined,
        .text,
        .list,
        .association
      ]
    }
  }
  
}
