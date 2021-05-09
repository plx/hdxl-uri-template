//
//  URITemplateComponent.swift
//

import Foundation
import HDXLCommonUtilities

// -------------------------------------------------------------------------- //
// MARK: URITemplateComponent - Definition
// -------------------------------------------------------------------------- //

@frozen
@usableFromInline
internal enum URITemplateComponent {
  
  case literal(URITemplateLiteralComponent)
  case expression(URITemplateExpressionComponent)
    
}

// -------------------------------------------------------------------------- //
// MARK: URITemplateComponent - Core API
// -------------------------------------------------------------------------- //

internal extension URITemplateComponent {
  
  @inlinable
  var isLiteralComponent: Bool {
    get {
      switch self {
      case .literal(_):
        return true
      case .expression(_):
        return false
      }
    }
  }
  
  @inlinable
  var isExpressionComponent: Bool {
    get {
      switch self {
      case .literal(_):
        return false
      case .expression(_):
        return true
      }
    }
  }
  
  @inlinable
  var templateRepresentation: String {
    get {
      switch self {
      case .literal(let literal):
        return literal.storage
      case .expression(let expression):
        return "{\(expression.templateRepresentation)}"
      }
    }
  }
  
  @inlinable
  var templateComponentType: URITemplateComponentType {
    get {
      switch self {
      case .literal(_):
        return .literal
      case .expression(_):
        return .expression
      }
    }
  }
  
  @inlinable
  func injectTemplateVariables(into receiver: inout Set<URITemplateVariable>) {
    switch self {
    case .literal(_):
      (); // nothing
    case .expression(let expression):
      expression.injectTemplateVariables(
        into: &receiver
      )
    }
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: URITemplateComponent - Validatable
// -------------------------------------------------------------------------- //

extension URITemplateComponent : Validatable {
  
  @inlinable
  internal var isValid: Bool {
    get {
      switch self {
      case .literal(let literal):
        return literal.isValid
      case .expression(let expression):
        return expression.isValid
      }
    }
  }

}

// -------------------------------------------------------------------------- //
// MARK: URITemplateComponent - Equatable
// -------------------------------------------------------------------------- //

extension URITemplateComponent : Equatable {
  
  @inlinable
  internal static func ==(
    lhs: URITemplateComponent,
    rhs: URITemplateComponent) -> Bool {
    // /////////////////////////////////////////////////////////////////////////
    pedantic_assert(lhs.isValid)
    pedantic_assert(rhs.isValid)
    // /////////////////////////////////////////////////////////////////////////
    switch (lhs,rhs) {
    case (.literal(let l), .literal(let r)):
      return l == r
    case (.expression(let l), .expression(let r)):
      return l == r
    default:
      return false
    }
  }

}

// -------------------------------------------------------------------------- //
// MARK: URITemplateComponent - Comparable
// -------------------------------------------------------------------------- //

extension URITemplateComponent : Comparable {

  @inlinable
  internal static func <(
    lhs: URITemplateComponent,
    rhs: URITemplateComponent) -> Bool {
    // /////////////////////////////////////////////////////////////////////////
    pedantic_assert(lhs.isValid)
    pedantic_assert(rhs.isValid)
    // /////////////////////////////////////////////////////////////////////////
    switch (lhs,rhs) {
    case (.literal(let l), .literal(let r)):
      return l < r
    case (.literal(_), .expression(_)):
      return true
    case (.expression(_), .literal(_)):
      return false
    case (.expression(let l), .expression(let r)):
      return l < r
    }
  }
}

// -------------------------------------------------------------------------- //
// MARK: URITemplateComponent - Hashable
// -------------------------------------------------------------------------- //

extension URITemplateComponent : Hashable {

  @inlinable
  internal func hash(into hasher: inout Hasher) {
    switch self {
    case .literal(let literal):
      URITemplateComponentType.literal.hash(into: &hasher)
      literal.hash(into: &hasher)
    case .expression(let expression):
      URITemplateComponentType.expression.hash(into: &hasher)
      expression.hash(into: &hasher)
    }
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: URITemplateComponent - CustomStringConvertible
// -------------------------------------------------------------------------- //

extension URITemplateComponent : CustomStringConvertible {
  
  @inlinable
  internal var description: String {
    get {
      switch self {
      case .literal(let literal):
        return ".literal(\"\(literal.storage)\")"
      case .expression(let expression):
        return ".expression(\"\(expression.description)\")"
      }
    }
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: URITemplateComponent - CustomDebugStringConvertible
// -------------------------------------------------------------------------- //

extension URITemplateComponent : CustomDebugStringConvertible {

  @inlinable
  internal var debugDescription: String {
    get {
      switch self {
      case .literal(let literal):
        return "URITemplateComponent.literal(\(literal.debugDescription)"
      case .expression(let expression):
        return "URITemplateComponent.expresssion(\(expression.debugDescription))"
      }
    }
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: URITemplateComponent - NSCoder
// -------------------------------------------------------------------------- //

extension URITemplateComponent : Codable {
  
  @usableFromInline
  internal typealias CodingKeys = StandardEnumerationCodingKeys
  
  @inlinable
  internal func encode(to encoder: Encoder) throws {
    var container = encoder.container(
      keyedBy: CodingKeys.self
    )
    try container.encode(
      self.templateComponentType,
      forKey: .type
    )
    switch self {
    case .literal(let literal):
      try container.encode(
        literal,
        forKey: .data
      )
    case .expression(let expression):
      try container.encode(
        expression,
        forKey: .data
      )
    }
  }
  
  @inlinable
  internal init(from decoder: Decoder) throws {
    let container = try decoder.container(
      keyedBy: CodingKeys.self
    )
    let type = try container.decode(
      URITemplateComponentType.self,
      forKey: .type
    )
    switch type {
    case .literal:
      self = .literal(
        try container.decode(
          URITemplateLiteralComponent.self,
          forKey: .data
        )
      )
    case .expression:
      self = .expression(
        try container.decode(
          URITemplateExpressionComponent.self,
          forKey: .data
        )
      )
    }
    
  }
  
}
