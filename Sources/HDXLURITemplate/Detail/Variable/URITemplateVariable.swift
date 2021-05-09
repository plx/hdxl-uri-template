//
//  URITemplateVariable.swift
//

import Foundation
import HDXLCommonUtilities

// -------------------------------------------------------------------------- //
// MARK: URITemplateVariable - Definition
// -------------------------------------------------------------------------- //

@frozen
@usableFromInline
internal struct URITemplateVariable {
  
  @usableFromInline
  internal var variableName: URITemplateVariableName
  
  @usableFromInline
  internal var expansionModifier: URIValueExpansionModifier
  
  @inlinable
  internal init(
    variableName: URITemplateVariableName,
    expansionModifier: URIValueExpansionModifier) {
    // /////////////////////////////////////////////////////////////////////////
    pedantic_assert(variableName.isValid)
    pedantic_assert(expansionModifier.isValid)
    defer { pedantic_assert(self.isValid) }
    // /////////////////////////////////////////////////////////////////////////
    self.variableName = variableName
    self.expansionModifier = expansionModifier
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: URITemplateVariable - Core API
// -------------------------------------------------------------------------- //

internal extension URITemplateVariable {
  
  @inlinable
  var templateRepresentation: String {
    get {
      return "\(self.variableName.storage)\(self.expansionModifier.templateRepresentation)"
    }
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: URITemplateVariable - Validatable
// -------------------------------------------------------------------------- //

extension URITemplateVariable : Validatable {
  
  @inlinable
  internal var isValid: Bool {
    get {
      return self.variableName.isValid && self.expansionModifier.isValid
    }
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: URITemplateVariable - Equatable
// -------------------------------------------------------------------------- //

extension URITemplateVariable : Equatable {
  
  @inlinable
  internal static func ==(
    lhs: URITemplateVariable,
    rhs: URITemplateVariable) -> Bool {
    // /////////////////////////////////////////////////////////////////////////
    pedantic_assert(lhs.isValid)
    pedantic_assert(rhs.isValid)
    // /////////////////////////////////////////////////////////////////////////
    guard
      lhs.variableName == rhs.variableName,
      lhs.expansionModifier == rhs.expansionModifier else {
        return false
    }
    return true

  }

}

// -------------------------------------------------------------------------- //
// MARK: URITemplateVariable - Comparable
// -------------------------------------------------------------------------- //

extension URITemplateVariable : Comparable {
  
  @inlinable
  internal static func <(
    lhs: URITemplateVariable,
    rhs: URITemplateVariable) -> Bool {
    // /////////////////////////////////////////////////////////////////////////
    pedantic_assert(lhs.isValid)
    pedantic_assert(rhs.isValid)
    // /////////////////////////////////////////////////////////////////////////
    return ComparisonResult.coalescing(
      lhs.variableName <=> rhs.variableName,
      lhs.expansionModifier <=> rhs.expansionModifier
    ).impliesLessThan
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: URITemplateVariable - Hashable
// -------------------------------------------------------------------------- //

extension URITemplateVariable : Hashable {
  
  @inlinable
  internal func hash(into hasher: inout Hasher) {
    self.variableName.hash(into: &hasher)
    self.expansionModifier.hash(into: &hasher)
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: URITemplateVariable - CustomStringConvertible
// -------------------------------------------------------------------------- //

extension URITemplateVariable : CustomStringConvertible {
  
  @inlinable
  internal var description: String {
    get {
      return "\"\(self.variableName)\", \(self.expansionModifier.description)"
    }
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: URITemplateVariable - CustomDebugStringConvertible
// -------------------------------------------------------------------------- //

extension URITemplateVariable : CustomDebugStringConvertible {
  
  @inlinable
  internal var debugDescription: String {
    get {
      return "URITemplateVariable(variableName: \(self.variableName.debugDescription), expansionModifier: \(self.expansionModifier.debugDescription))"
    }
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: URITemplateVariable - Codable
// -------------------------------------------------------------------------- //

extension URITemplateVariable : Codable {
  
  // synthesized ok
  
}
