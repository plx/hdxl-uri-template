//
//  URIVariableTextValue.swift
//

import Foundation
import HDXLCommonUtilities

// -------------------------------------------------------------------------- //
// MARK: URIVariableTextValue - Definition
// -------------------------------------------------------------------------- //

/// Represents a flat-string, `.text` variable's value.
/// Implemented (by hand) as a minimal `newtype`-style string wrapper, with the
/// intent being that the constructor *certifies* that the wrapped string is ok.
///
/// For this specific type at this time that check is trivially `true` for any
/// string, but I'll need to re-read the spec to verify that there are, in fact,
/// no actual invariants/constraints/etc. that we need to satisfy here.
@frozen
@usableFromInline
internal struct URIVariableTextValue {

  @usableFromInline
  internal var storage: String
  
  @inlinable
  internal init(text: String) {
    // /////////////////////////////////////////////////////////////////////////
    defer { pedantic_assert(self.isValid) }
    // /////////////////////////////////////////////////////////////////////////
    self.storage = text
  }

}

// -------------------------------------------------------------------------- //
// MARK: URIVariableTextValue - Core API
// -------------------------------------------------------------------------- //

internal extension URIVariableTextValue {

  /// Extracts `self.storage` as a `String`.
  /// May get eliminated now that `URIVariableTextValue` is package-internal.
  @inlinable
  var asString: String {
    get {
      return self.storage
    }
  }
  
  /// `true` iff we're wrapping an empty string.
  @inlinable
  var isEmpty: Bool {
    get {
      return self.storage.isEmpty
    }
  }

}

// -------------------------------------------------------------------------- //
// MARK: URIVariableTextValue - Validatable
// -------------------------------------------------------------------------- //

extension URIVariableTextValue : Validatable {

  @inlinable
  internal var isValid: Bool {
    get {
      return true
    }
  }

}

// -------------------------------------------------------------------------- //
// MARK: URIVariableTextValue - Equatable
// -------------------------------------------------------------------------- //

extension URIVariableTextValue : Equatable {
  
  @inlinable
  internal static func ==(
    lhs: URIVariableTextValue,
    rhs: URIVariableTextValue) -> Bool {
    // /////////////////////////////////////////////////////////////////////////
    pedantic_assert(lhs.isValid)
    pedantic_assert(rhs.isValid)
    // /////////////////////////////////////////////////////////////////////////
    return lhs.storage == rhs.storage
  }
  
  @inlinable
  internal static func !=(
    lhs: URIVariableTextValue,
    rhs: URIVariableTextValue) -> Bool {
    // /////////////////////////////////////////////////////////////////////////
    pedantic_assert(lhs.isValid)
    pedantic_assert(rhs.isValid)
    // /////////////////////////////////////////////////////////////////////////
    return lhs.storage != rhs.storage
  }

}


// -------------------------------------------------------------------------- //
// MARK: URIVariableTextValue - Comparable
// -------------------------------------------------------------------------- //

extension URIVariableTextValue : Comparable {
  
  @inlinable
  internal static func <(
    lhs: URIVariableTextValue,
    rhs: URIVariableTextValue) -> Bool {
    // /////////////////////////////////////////////////////////////////////////
    pedantic_assert(lhs.isValid)
    pedantic_assert(rhs.isValid)
    // /////////////////////////////////////////////////////////////////////////
    return lhs.storage < rhs.storage
  }

  @inlinable
  internal static func >(
    lhs: URIVariableTextValue,
    rhs: URIVariableTextValue) -> Bool {
    // /////////////////////////////////////////////////////////////////////////
    pedantic_assert(lhs.isValid)
    pedantic_assert(rhs.isValid)
    // /////////////////////////////////////////////////////////////////////////
    return lhs.storage > rhs.storage
  }
  
  @inlinable
  internal static func <=(
    lhs: URIVariableTextValue,
    rhs: URIVariableTextValue) -> Bool {
    // /////////////////////////////////////////////////////////////////////////
    pedantic_assert(lhs.isValid)
    pedantic_assert(rhs.isValid)
    // /////////////////////////////////////////////////////////////////////////
    return lhs.storage <= rhs.storage
  }

  @inlinable
  internal static func >=(
    lhs: URIVariableTextValue,
    rhs: URIVariableTextValue) -> Bool {
    // /////////////////////////////////////////////////////////////////////////
    pedantic_assert(lhs.isValid)
    pedantic_assert(rhs.isValid)
    // /////////////////////////////////////////////////////////////////////////
    return lhs.storage >= rhs.storage
  }

}

// -------------------------------------------------------------------------- //
// MARK: URIVariableTextValue - Hashable
// -------------------------------------------------------------------------- //

extension URIVariableTextValue : Hashable {

  @inlinable
  internal func hash(into hasher: inout Hasher) {
    self.storage.hash(into: &hasher)
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: URIVariableTextValue - CustomStringConvertible
// -------------------------------------------------------------------------- //

extension URIVariableTextValue : CustomStringConvertible {

  @inlinable
  internal var description: String {
    get {
      return self.storage
    }
  }
}

// -------------------------------------------------------------------------- //
// MARK: URIVariableTextValue - CustomDebugStringConvertible
// -------------------------------------------------------------------------- //

extension URIVariableTextValue : CustomDebugStringConvertible {
  
  @inlinable
  internal var debugDescription: String {
    get {
      return "URIVariableTextValue(text: '\(self.storage)')"
    }
  }
}

// -------------------------------------------------------------------------- //
// MARK: URIVariableTextValue - Codable
// -------------------------------------------------------------------------- //

extension URIVariableTextValue : Codable {
  
  // synthesized ok
  
}
