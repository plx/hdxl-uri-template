//
//  URIVariableAssociationValue.swift
//

import Foundation
import HDXLCommonUtilities

// -------------------------------------------------------------------------- //
// MARK: URIVariableAssociationValue - Definition
// -------------------------------------------------------------------------- //

@frozen
@usableFromInline
internal struct URIVariableAssociationValue {
  
  @usableFromInline
  internal var storage: [URIVariablePairValue]

  @inlinable
  internal init() {
    self.init(values: [])
  }

  @inlinable
  internal init(value: URIVariablePairValue) {
    // /////////////////////////////////////////////////////////////////////////
    pedantic_assert(value.isValid)
    // /////////////////////////////////////////////////////////////////////////
    self.init(
      values: [value]
    )
  }

  @inlinable
  internal init(values: [URIVariablePairValue]) {
    // /////////////////////////////////////////////////////////////////////////
    pedantic_assert(values.allElementsAreValid)
    defer { pedantic_assert(self.isValid) }
    // /////////////////////////////////////////////////////////////////////////
    self.storage = values
  }
    
}

// -------------------------------------------------------------------------- //
// MARK: URIVariableAssociationValue - Core API
// -------------------------------------------------------------------------- //

internal extension URIVariableAssociationValue {
  
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
  subscript(index: Int) -> URIVariablePairValue {
    get {
      return self.storage[index]
    }
  }
  
  @inlinable
  subscript(key: String) -> URIVariableTextValue? {
    get {
      return self[URIVariableTextValue(text: key)]
    }
  }
  
  @inlinable
  subscript(key: URIVariableTextValue) -> URIVariableTextValue? {
    get {
      for pair in self.storage where pair.key == key {
        return pair.value
      }
      return nil
    }
  }

}

// -------------------------------------------------------------------------- //
// MARK: URIVariableAssociationValue - Equatable
// -------------------------------------------------------------------------- //

extension URIVariableAssociationValue : Validatable {
  
  @inlinable
  internal var isValid: Bool {
    get {
      guard
        self.storage.allElementsAreValid,
        self.allKeysAreDistinct else {
          return false
      }
      return true
    }
  }
  
  @inlinable
  var allKeysAreDistinct: Bool {
    get {
      return self.count == Set(
        self.storage.lazy.map() {$0.key}
      ).count
    }
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: URIVariableAssociationValue - Equatable
// -------------------------------------------------------------------------- //

extension URIVariableAssociationValue : Equatable {
  
  @inlinable
  internal static func ==(
    lhs: URIVariableAssociationValue,
    rhs: URIVariableAssociationValue) -> Bool {
    // /////////////////////////////////////////////////////////////////////////
    pedantic_assert(lhs.isValid)
    pedantic_assert(rhs.isValid)
    // /////////////////////////////////////////////////////////////////////////
    return lhs.storage == rhs.storage
  }
  
  @inlinable
  internal static func !=(
    lhs: URIVariableAssociationValue,
    rhs: URIVariableAssociationValue) -> Bool {
    // /////////////////////////////////////////////////////////////////////////
    pedantic_assert(lhs.isValid)
    pedantic_assert(rhs.isValid)
    // /////////////////////////////////////////////////////////////////////////
    return lhs.storage != rhs.storage
  }

}

// -------------------------------------------------------------------------- //
// MARK: URIVariableAssociationValue - Comparable
// -------------------------------------------------------------------------- //

extension URIVariableAssociationValue : Comparable {
  
  @inlinable
  internal static func <(
    lhs: URIVariableAssociationValue,
    rhs: URIVariableAssociationValue) -> Bool {
    // /////////////////////////////////////////////////////////////////////////
    pedantic_assert(lhs.isValid)
    pedantic_assert(rhs.isValid)
    // /////////////////////////////////////////////////////////////////////////
    return lhs.storage.lexicographicallyPrecedes(rhs.storage)
  }

}

// -------------------------------------------------------------------------- //
// MARK: URIVariableAssociationValue - Hashable
// -------------------------------------------------------------------------- //

extension URIVariableAssociationValue : Hashable {

  @inlinable
  internal func hash(into hasher: inout Hasher) {
    self.storage.hash(into: &hasher)
  }
}

// -------------------------------------------------------------------------- //
// MARK: URIVariableAssociationValue - CustomStringConvertible
// -------------------------------------------------------------------------- //

extension URIVariableAssociationValue : CustomStringConvertible {
  
  @inlinable
  internal var description: String {
    get {
      return self.storage.enclosedTransformJoin(
        endcaps: .squareBrackets,
        separator: ", ") {
          $0.description
      }
    }
  }
}

// -------------------------------------------------------------------------- //
// MARK: URIVariableAssociationValue - CustomDebugStringConvertible
// -------------------------------------------------------------------------- //

extension URIVariableAssociationValue : CustomDebugStringConvertible {
  
  @inlinable
  internal var debugDescription: String {
    get {
      let variableDescriptions = self.storage.enclosedTransformJoin(
        endcaps: .squareBrackets,
        separator: ", ") {
          $0.debugDescription
      }
      return "URIVariableAssociationValue(values: \(variableDescriptions))"
    }
  }
}

// -------------------------------------------------------------------------- //
// MARK: URIVariableAssociationValue - NSCoder
// -------------------------------------------------------------------------- //

extension URIVariableAssociationValue : Codable {
  
  // synthesized ok

}

