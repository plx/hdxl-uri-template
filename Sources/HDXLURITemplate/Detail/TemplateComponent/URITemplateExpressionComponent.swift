//
//  URITemplateExpressionComponent.swift
//

import Foundation
import HDXLCommonUtilities

// -------------------------------------------------------------------------- //
// MARK: URITemplateExpressionComponent - Definition
// -------------------------------------------------------------------------- //

@frozen
@usableFromInline
internal struct URITemplateExpressionComponent {
  
  @usableFromInline
  internal var expansionType: URIValueExpansionType
  
  @usableFromInline
  internal var variables: [URITemplateVariable]
  
  @inlinable
  internal init(
    expansionType: URIValueExpansionType,
    variable: URITemplateVariable) {
    // /////////////////////////////////////////////////////////////////////////
    pedantic_assert(variable.isValid)
    // /////////////////////////////////////////////////////////////////////////
    self.init(
      expansionType: expansionType,
      variables: [variable]
    )
  }

  @inlinable
  internal init(
    expansionType: URIValueExpansionType,
    variables: [URITemplateVariable]) {
    // /////////////////////////////////////////////////////////////////////////
    pedantic_assert(variables.allElementsAreValid)
    defer { pedantic_assert(self.isValid)}
    // /////////////////////////////////////////////////////////////////////////
    self.expansionType = expansionType
    self.variables = variables
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: URITemplateExpressionComponent - Core API
// -------------------------------------------------------------------------- //

internal extension URITemplateExpressionComponent {
  
  @inlinable
  var isEmpty: Bool {
    get {
      return self.variables.isEmpty
    }
  }
  
  @inlinable
  var count: Int {
    get {
      return self.variables.count
    }
  }
  
  @inlinable
  var templateRepresentation: String {
    get {
      
      let variables = self.variables
        .lazy
        .map() {
          $0.templateRepresentation
      }.joined(separator: ", ")
      return "\(self.expansionType.formatString)\(variables)"
    }
  }
  
  @inlinable
  func injectTemplateVariables(into receiver: inout Set<URITemplateVariable>) {
    receiver.formUnion(self.variables)
  }

}

// -------------------------------------------------------------------------- //
// MARK: URITemplateExpressionComponent - Validatable
// -------------------------------------------------------------------------- //

extension URITemplateExpressionComponent : Validatable {
  
  @inlinable
  internal var isValid: Bool {
    get {
      return self.variables.allElementsAreValid
    }
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: URITemplateExpressionComponent - Equatable
// -------------------------------------------------------------------------- //

extension URITemplateExpressionComponent : Equatable {

  @inlinable
  internal static func ==(
    lhs: URITemplateExpressionComponent,
    rhs: URITemplateExpressionComponent) -> Bool {
    // /////////////////////////////////////////////////////////////////////////
    pedantic_assert(lhs.isValid)
    pedantic_assert(rhs.isValid)
    // /////////////////////////////////////////////////////////////////////////
    guard
      lhs.expansionType == rhs.expansionType,
      lhs.variables == rhs.variables else {
      return false
    }
    return true
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: URITemplateExpressionComponent - Comparable
// -------------------------------------------------------------------------- //

extension URITemplateExpressionComponent : Comparable {

  @inlinable
  internal static func <(
    lhs: URITemplateExpressionComponent,
    rhs: URITemplateExpressionComponent) -> Bool {
    // /////////////////////////////////////////////////////////////////////////
    pedantic_assert(lhs.isValid)
    pedantic_assert(rhs.isValid)
    // /////////////////////////////////////////////////////////////////////////
    switch lhs.expansionType <=> rhs.expansionType {
    case .orderedAscending:
      return true
    case .orderedSame:
      return lhs.variables.lexicographicallyPrecedes(rhs.variables)
    case .orderedDescending:
      return false
    }
  }

}

// -------------------------------------------------------------------------- //
// MARK: URITemplateExpressionComponent - Hashable
// -------------------------------------------------------------------------- //

extension URITemplateExpressionComponent : Hashable {
  
  @inlinable
  internal func hash(into hasher: inout Hasher) {
    self.expansionType.hash(into: &hasher)
    self.variables.hash(into: &hasher)
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: URITemplateExpressionComponent - CustomStringConvertible
// -------------------------------------------------------------------------- //

extension URITemplateExpressionComponent : CustomStringConvertible {
  
  @inlinable
  internal var description: String {
    get {
      let variables = self.variables.enclosedTransformJoin(
        endcaps: .squareBrackets,
        separator: ", ") {
          $0.description
      }
      return "\(self.expansionType.description) for \(variables)"
    }
  }

}

// -------------------------------------------------------------------------- //
// MARK: URITemplateExpressionComponent - CustomDebugStringConvertible
// -------------------------------------------------------------------------- //

extension URITemplateExpressionComponent : CustomDebugStringConvertible {
  
  @inlinable
  internal var debugDescription: String {
    get {
      let variables = self.variables.enclosedTransformJoin(
        endcaps: .squareBrackets,
        separator: ", ") {
          $0.debugDescription
      }
      return "URITemplateExpressionComponent(expansionType: \(self.expansionType.debugDescription), variables: \(variables))"
    }
  }

}

// -------------------------------------------------------------------------- //
// MARK: URITemplateExpressionComponent - Codable
// -------------------------------------------------------------------------- //

extension URITemplateExpressionComponent : Codable {

  // synthesized ok
  
}
