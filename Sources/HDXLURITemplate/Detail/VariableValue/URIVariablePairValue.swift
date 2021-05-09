//
//  URIVariablePairValue.swift
//

import Foundation
import HDXLCommonUtilities

// -------------------------------------------------------------------------- //
// MARK: URIVariablePairValue - Definition
// -------------------------------------------------------------------------- //

/// Represents a single key:value pair of strings--for use within `URIVariableAssociationValue`.
@usableFromInline
internal struct URIVariablePairValue {

  @usableFromInline
  internal var key: URIVariableTextValue
  
  @usableFromInline
  internal var value: URIVariableTextValue
  
  @inlinable
  internal init(
    key: URIVariableTextValue,
    value: URIVariableTextValue) {
    // /////////////////////////////////////////////////////////////////////////
    pedantic_assert(key.isValid)
    pedantic_assert(value.isValid)
    defer { pedantic_assert(self.isValid) }
    // /////////////////////////////////////////////////////////////////////////
    self.key = key
    self.value = value
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: URIVariablePairValue - Validatable
// -------------------------------------------------------------------------- //

extension URIVariablePairValue : Validatable {
  
  @inlinable
  internal var isValid: Bool {
    get {
      return self.key.isValid && self.value.isValid
    }
  }

}

// -------------------------------------------------------------------------- //
// MARK: URIVariablePairValue - Equatable
// -------------------------------------------------------------------------- //

extension URIVariablePairValue : Equatable {

  @inlinable
  internal static func ==(
    lhs: URIVariablePairValue,
    rhs: URIVariablePairValue) -> Bool {
    // /////////////////////////////////////////////////////////////////////////
    pedantic_assert(lhs.isValid)
    pedantic_assert(rhs.isValid)
    // /////////////////////////////////////////////////////////////////////////
    return lhs.key == rhs.key && lhs.value == rhs.value
  }
  
  @inlinable
  internal static func !=(
    lhs: URIVariablePairValue,
    rhs: URIVariablePairValue) -> Bool {
    // /////////////////////////////////////////////////////////////////////////
    pedantic_assert(lhs.isValid)
    pedantic_assert(rhs.isValid)
    // /////////////////////////////////////////////////////////////////////////
    return lhs.key != rhs.key || lhs.value != rhs.value
  }

}

// -------------------------------------------------------------------------- //
// MARK: URIVariablePairValue - Comparable
// -------------------------------------------------------------------------- //

extension URIVariablePairValue : Comparable {

  @inlinable
  internal static func <(
    lhs: URIVariablePairValue,
    rhs: URIVariablePairValue) -> Bool {
    // /////////////////////////////////////////////////////////////////////////
    pedantic_assert(lhs.isValid)
    pedantic_assert(rhs.isValid)
    // /////////////////////////////////////////////////////////////////////////
    return ComparisonResult.coalescing(
      lhs.key <=> rhs.key,
      lhs.value <=> rhs.value
    ).impliesLessThan
  }
  
  @inlinable
  internal static func >(
    lhs: URIVariablePairValue,
    rhs: URIVariablePairValue) -> Bool {
    // /////////////////////////////////////////////////////////////////////////
    pedantic_assert(lhs.isValid)
    pedantic_assert(rhs.isValid)
    // /////////////////////////////////////////////////////////////////////////
    return ComparisonResult.coalescing(
      lhs.key <=> rhs.key,
      lhs.value <=> rhs.value
    ).impliesGreaterThan
  }
  
  @inlinable
  internal static func <=(
    lhs: URIVariablePairValue,
    rhs: URIVariablePairValue) -> Bool {
    // /////////////////////////////////////////////////////////////////////////
    pedantic_assert(lhs.isValid)
    pedantic_assert(rhs.isValid)
    // /////////////////////////////////////////////////////////////////////////
    return ComparisonResult.coalescing(
      lhs.key <=> rhs.key,
      lhs.value <=> rhs.value
    ).impliesLessThanOrEqual
  }
  
  @inlinable
  internal static func >=(
    lhs: URIVariablePairValue,
    rhs: URIVariablePairValue) -> Bool {
    // /////////////////////////////////////////////////////////////////////////
    pedantic_assert(lhs.isValid)
    pedantic_assert(rhs.isValid)
    // /////////////////////////////////////////////////////////////////////////
    return ComparisonResult.coalescing(
      lhs.key <=> rhs.key,
      lhs.value <=> rhs.value
    ).impliesGreaterThanOrEqual
  }

}

// -------------------------------------------------------------------------- //
// MARK: URIVariablePairValue - Hashable
// -------------------------------------------------------------------------- //

extension URIVariablePairValue : Hashable {
  
  @inlinable
  internal func hash(into hasher: inout Hasher) {
    self.key.hash(into: &hasher)
    self.value.hash(into: &hasher)
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: URIVariablePairValue - CustomStringConvertible
// -------------------------------------------------------------------------- //

extension URIVariablePairValue : CustomStringConvertible {
  
  @inlinable
  internal var description: String {
    get {
      return "\"\(self.key.description)\":\"\(self.value.description)\""
    }
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: URIVariablePairValue - CustomDebugStringConvertible
// -------------------------------------------------------------------------- //

extension URIVariablePairValue : CustomDebugStringConvertible {
  
  @inlinable
  internal var debugDescription: String {
    get {
      return "URIVariablePairValue(key: \(self.key.debugDescription), value: \(self.value.debugDescription))"
    }
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: URIVariablePairValue - NSCoder
// -------------------------------------------------------------------------- //

extension URIVariablePairValue : Codable {
  
  // syntheiszed ok
  
}
