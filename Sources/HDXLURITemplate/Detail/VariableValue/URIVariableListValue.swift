//
//  URIVariableListValue.swift
//

import Foundation
import HDXLCommonUtilities

// -------------------------------------------------------------------------- //
// MARK: URIVariableListValue - Definition
// -------------------------------------------------------------------------- //

@frozen
@usableFromInline
internal struct URIVariableListValue {
  
  @usableFromInline
  internal var storage: [URIVariableTextValue]
  
  @inlinable
  internal init() {
    self.init(
      values: []
    )
  }

  @inlinable
  internal init(value: URIVariableTextValue) {
    // /////////////////////////////////////////////////////////////////////////
    pedantic_assert(value.isValid)
    // /////////////////////////////////////////////////////////////////////////
    self.init(
      values: [value]
    )
  }

  @inlinable
  internal init(values: [URIVariableTextValue]) {
    // /////////////////////////////////////////////////////////////////////////
    pedantic_assert(values.allElementsAreValid)
    defer { pedantic_assert(self.isValid)}
    // /////////////////////////////////////////////////////////////////////////
    self.storage = values
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: URIVariableListValue - Core API
// -------------------------------------------------------------------------- //

internal extension URIVariableListValue {
  
  @inlinable
  var isEmpty: Bool {
    get {
      return self.storage.isEmpty
    }
  }
  
  @inlinable
  var count: Int {
    get {
      return self.storage.count
    }
  }
  
  @inlinable
  subscript(index: Int) -> URIVariableTextValue {
    get {
      return self.storage[index]
    }
  }
    
}

// -------------------------------------------------------------------------- //
// MARK: URIVariableListValue - Validatable
// -------------------------------------------------------------------------- //

extension URIVariableListValue : Validatable {
  
  @inlinable
  internal var isValid: Bool {
    get {
      return self.storage.allElementsAreValid
    }
  }
    
}

// -------------------------------------------------------------------------- //
// MARK: URIVariableListValue - Equatable
// -------------------------------------------------------------------------- //

extension URIVariableListValue : Equatable {

  @inlinable
  internal static func ==(
    lhs: URIVariableListValue,
    rhs: URIVariableListValue) -> Bool {
    // /////////////////////////////////////////////////////////////////////////
    pedantic_assert(lhs.isValid)
    pedantic_assert(rhs.isValid)
    // /////////////////////////////////////////////////////////////////////////
    return lhs.storage == rhs.storage
  }
  
  @inlinable
  internal static func !=(
    lhs: URIVariableListValue,
    rhs: URIVariableListValue) -> Bool {
    // /////////////////////////////////////////////////////////////////////////
    pedantic_assert(lhs.isValid)
    pedantic_assert(rhs.isValid)
    // /////////////////////////////////////////////////////////////////////////
    return lhs.storage != rhs.storage
  }

}

// -------------------------------------------------------------------------- //
// MARK: URIVariableListValue - Comparable
// -------------------------------------------------------------------------- //

extension URIVariableListValue : Comparable {
  
  @inlinable
  internal static func <(
    lhs: URIVariableListValue,
    rhs: URIVariableListValue) -> Bool {
    // /////////////////////////////////////////////////////////////////////////
    pedantic_assert(lhs.isValid)
    pedantic_assert(rhs.isValid)
    // /////////////////////////////////////////////////////////////////////////
    return lhs.storage.lexicographicallyPrecedes(rhs.storage)
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: URIVariableListValue - Hashable
// -------------------------------------------------------------------------- //

extension URIVariableListValue : Hashable {
  
  @inlinable
  internal func hash(into hasher: inout Hasher) {
    self.storage.hash(into: &hasher)
  }

}

// -------------------------------------------------------------------------- //
// MARK: URIVariableListValue - CustomStringConvertible
// -------------------------------------------------------------------------- //

extension URIVariableListValue : CustomStringConvertible {
  
  @inlinable
  internal var description: String {
    get {
      return self.storage
        .lazy
        .map() { $0.description }
        .enclosedJoin(
          endcaps: .squareBrackets,
          separator: ", "
        )
    }
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: URIVariableListValue - CustomDebugStringConvertible
// -------------------------------------------------------------------------- //

extension URIVariableListValue : CustomDebugStringConvertible {
  
  @inlinable
  internal var debugDescription: String {
    get {
      let values = self.storage
        .lazy
        .map() { $0.debugDescription }
        .enclosedJoin(
          endcaps: .squareBrackets,
          separator: ", "
      )
      return "URIVariableListValue(values: \(values))"
    }
  }
}

// -------------------------------------------------------------------------- //
// MARK: URIVariableListValue - Codable
// -------------------------------------------------------------------------- //

extension URIVariableListValue : Codable {

  // syntheiszed ok
  
}

