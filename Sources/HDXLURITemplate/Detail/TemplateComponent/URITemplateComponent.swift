
// MARK: URITemplateComponent

@usableFromInline
internal enum URITemplateComponent {
  
  case literal(URITemplateLiteralComponent)
  case expression(URITemplateExpressionComponent)
    
}

// MARK: - Synthesized Properties

extension URITemplateComponent : Sendable {}
extension URITemplateComponent : SendableMetatype {}
extension URITemplateComponent : Equatable {}
extension URITemplateComponent : Hashable {}
extension URITemplateComponent : Codable {}

// MARK: - Comparable

extension URITemplateComponent : Comparable {

  @inlinable
  internal static func <(
    lhs: URITemplateComponent,
    rhs: URITemplateComponent
  ) -> Bool {
#if HEAVY_DEBUG
    pedanticAssert(lhs.isValid)
    pedanticAssert(rhs.isValid)
#endif
    return switch (lhs,rhs) {
    case (.literal(let l), .literal(let r)):
       l < r
    case (.literal(_), .expression(_)):
      true
    case (.expression(_), .literal(_)):
      false
    case (.expression(let l), .expression(let r)):
      l < r
    }
  }
}

// MARK: - CustomStringConvertible

extension URITemplateComponent : CustomStringConvertible {
  
  @usableFromInline
  internal var description: String {
    switch self {
    case .literal(let literal):
      ".literal(\"\(literal.rawValue)\")"
    case .expression(let expression):
      ".expression(\"\(expression.description)\")"
    }
  }
  
}

// MARK: - CustomDebugStringConvertible

extension URITemplateComponent : CustomDebugStringConvertible {

  @usableFromInline
  internal var debugDescription: String {
    switch self {
    case .literal(let literal):
      "URITemplateComponent.literal(\(literal.debugDescription)"
    case .expression(let expression):
      "URITemplateComponent.expresssion(\(expression.debugDescription))"
    }
  }
  
}

// MARK: - Core API

extension URITemplateComponent {
  
  @inlinable
  internal var isLiteralComponent: Bool {
    switch self {
    case .literal:
      true
    case .expression:
      false
    }
  }
  
  @inlinable
  internal var isExpressionComponent: Bool {
    switch self {
    case .literal:
      false
    case .expression:
      true
    }
  }
  
  @inlinable
  internal var templateRepresentation: String {
    switch self {
    case .literal(let literal):
      literal.rawValue
    case .expression(let expression):
      "{\(expression.templateRepresentation)}"
    }
  }
  
  @inlinable
  internal var templateComponentType: URITemplateComponentType {
    switch self {
    case .literal:
      .literal
    case .expression:
      .expression
    }
  }
  
  @inlinable
  internal func injectTemplateVariables(into receiver: inout Set<URITemplateVariable>) {
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

// MARK: - Validatable

extension URITemplateComponent {
  
  @inlinable
  internal var isValid: Bool {
    switch self {
    case .literal(let literal):
      literal.isValid
    case .expression(let expression):
      expression.isValid
    }
  }
  
}
