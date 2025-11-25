// MARK: URITemplateComponent

/// Represents a single component of a URI template: either a literal string or an expression.
@usableFromInline
package enum URITemplateComponent {

  /// A literal text component to be included verbatim in the expanded URI.
  case literal(URITemplateLiteralComponent)
  /// An expression component containing variables to be substituted.
  case expression(URITemplateExpressionComponent)

}

// MARK: - Synthesized Properties

extension URITemplateComponent : Sendable {}
extension URITemplateComponent : Equatable {}
extension URITemplateComponent : Hashable {}
extension URITemplateComponent : Codable {}

// MARK: - Comparable

extension URITemplateComponent : Comparable {

  @inlinable
  package static func <(
    lhs: URITemplateComponent,
    rhs: URITemplateComponent
  ) -> Bool {
    switch (lhs,rhs) {
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
  package var description: String {
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
  package var debugDescription: String {
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

  /// `true` if this is a literal component.
  @inlinable
  package var isLiteralComponent: Bool {
    switch self {
    case .literal:
      true
    case .expression:
      false
    }
  }

  /// `true` if this is an expression component.
  @inlinable
  package var isExpressionComponent: Bool {
    switch self {
    case .literal:
      false
    case .expression:
      true
    }
  }

  /// The template string representation of this component.
  @inlinable
  package var templateRepresentation: String {
    switch self {
    case .literal(let literal):
      literal.rawValue
    case .expression(let expression):
      "{\(expression.templateRepresentation)}"
    }
  }

  /// The type of this component (literal or expression).
  @inlinable
  package var templateComponentType: URITemplateComponentType {
    switch self {
    case .literal:
      .literal
    case .expression:
      .expression
    }
  }

  /// Injects the variables from this component into the given set.
  ///
  /// - Parameter receiver: The set to receive the variables.
  @inlinable
  package func injectTemplateVariables(into receiver: inout Set<URITemplateVariable>) {
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

  /// Indicates whether this component is structurally valid.
  @inlinable
  package var isValid: Bool {
    switch self {
    case .literal(let literal):
      literal.isValid
    case .expression(let expression):
      expression.isValid
    }
  }
  
}
