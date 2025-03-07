//
//  URITemplateComponentType.swift
//

import Foundation

// -------------------------------------------------------------------------- //
// MARK: URITemplateComponentType - Definition
// -------------------------------------------------------------------------- //

@frozen
@usableFromInline
internal enum URITemplateComponentType : UInt8 {
  
  case literal = 1
  case expression = 2
  
}

// -------------------------------------------------------------------------- //
// MARK: URITemplateComponentType - Equatable
// -------------------------------------------------------------------------- //

extension URITemplateComponentType : Equatable {

  @inlinable
  internal static func ==(
    lhs: URITemplateComponentType,
    rhs: URITemplateComponentType) -> Bool {
    return lhs.rawValue == rhs.rawValue
  }
  
  @inlinable
  internal static func !=(
    lhs: URITemplateComponentType,
    rhs: URITemplateComponentType) -> Bool {
    return lhs.rawValue != rhs.rawValue
  }

}

// -------------------------------------------------------------------------- //
// MARK: URITemplateComponentType - Comparable
// -------------------------------------------------------------------------- //

extension URITemplateComponentType : Comparable {

  @inlinable
  internal static func <(
    lhs: URITemplateComponentType,
    rhs: URITemplateComponentType) -> Bool {
    return lhs.rawValue < rhs.rawValue
  }
  
  @inlinable
  internal static func >(
    lhs: URITemplateComponentType,
    rhs: URITemplateComponentType) -> Bool {
    return lhs.rawValue > rhs.rawValue
  }
  
  @inlinable
  internal static func <=(
    lhs: URITemplateComponentType,
    rhs: URITemplateComponentType) -> Bool {
    return lhs.rawValue <= rhs.rawValue
  }

  @inlinable
  internal static func >=(
    lhs: URITemplateComponentType,
    rhs: URITemplateComponentType) -> Bool {
    return lhs.rawValue >= rhs.rawValue
  }

}

// -------------------------------------------------------------------------- //
// MARK: URITemplateComponentType - Hashable
// -------------------------------------------------------------------------- //

extension URITemplateComponentType : Hashable {
  
  @inlinable
  func hash(into hasher: inout Hasher) {
    self.rawValue.hash(into: &hasher)
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: URITemplateComponentType - CustomStringConvertible
// -------------------------------------------------------------------------- //

extension URITemplateComponentType : CustomStringConvertible {

  @inlinable
  internal var description: String {
    get {
      switch self {
      case .literal:
        return ".literal"
      case .expression:
        return ".expression"
      }
    }
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: URITemplateComponentType - CustomDebugStringConvertible
// -------------------------------------------------------------------------- //

extension URITemplateComponentType : CustomDebugStringConvertible {
  
  @inlinable
  internal var debugDescription: String {
    get {
      switch self {
      case .literal:
        return "URITemplateComponentType.literal"
      case .expression:
        return "URITemplateComponentType.expression"
      }
    }
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: URITemplateComponentType - Codable
// -------------------------------------------------------------------------- //

extension URITemplateComponentType : Codable {
  
  // synthesized ok
  
}

// -------------------------------------------------------------------------- //
// MARK: URITemplateComponentType - CaseIterable
// -------------------------------------------------------------------------- //

extension URITemplateComponentType : CaseIterable {
  
  @usableFromInline
  internal typealias AllCases = [URITemplateComponentType]
  
  @inlinable
  internal static var allCases: AllCases {
    get {
      return [
        .literal,
        .expression
      ]
    }
  }
  
}

