// MARK: URITemplateExpressionComponent

/// Represents an expression component in a URI template, containing variables and an expansion type.
@usableFromInline
package struct URITemplateExpressionComponent {

  /// The expansion type determining how variables are expanded (simple, reserved, etc.).
  @usableFromInline
  package var expansionType: URIValueExpansionType

  /// The variables contained in this expression.
  @usableFromInline
  package var variables: [URITemplateVariable]

  /// Creates an expression component with a single variable.
  ///
  /// - Parameters:
  ///   - expansionType: The expansion type for the expression.
  ///   - variable: The single variable in this expression.
  @inlinable
  package init(
    expansionType: URIValueExpansionType,
    variable: URITemplateVariable
  ) {
    self.init(
      expansionType: expansionType,
      variables: [variable]
    )
  }

  /// Creates an expression component with multiple variables.
  ///
  /// - Parameters:
  ///   - expansionType: The expansion type for the expression.
  ///   - variables: The variables in this expression.
  @inlinable
  package init(
    expansionType: URIValueExpansionType,
    variables: [URITemplateVariable]
  ) {
    self.expansionType = expansionType
    self.variables = variables
  }

}

// MARK: - Synthesized Conformances

extension URITemplateExpressionComponent: Sendable { }
extension URITemplateExpressionComponent: Equatable { }
extension URITemplateExpressionComponent: Hashable { }
extension URITemplateExpressionComponent: Codable { }

// MARK: - Comparable

extension URITemplateExpressionComponent : Comparable {

  /// Compares two expression components by expansion type, then by variables.
  @inlinable
  package static func <(
    lhs: URITemplateExpressionComponent,
    rhs: URITemplateExpressionComponent
  ) -> Bool {
    guard lhs.expansionType == rhs.expansionType else {
      return lhs.expansionType < rhs.expansionType
    }
    return lhs.variables.lexicographicallyPrecedes(rhs.variables)
  }

}

// MARK: - CustomStringConvertible

extension URITemplateExpressionComponent : CustomStringConvertible {

  /// A textual representation of the expression component.
  @inlinable
  package var description: String {
    let variables = variables
      .lazy
      .map(\.description)
      .joined(separator: ", ")
    return "\(expansionType.description) for [ \(variables) ]"
  }

}

// MARK: - CustomDebugStringConvertible

extension URITemplateExpressionComponent : CustomDebugStringConvertible {

  /// A detailed debug description of the expression component.
  @inlinable
  package var debugDescription: String {
    let variables = variables
      .lazy
      .map(\.debugDescription)
      .joined(separator: ", ")
    
    return "URITemplateExpressionComponent(expansionType: \(expansionType.debugDescription), variables: [ \(variables) ])"
  }

}

// MARK: - Core API

extension URITemplateExpressionComponent {

  /// `true` if this expression contains no variables.
  @inlinable
  package var isEmpty: Bool {
    variables.isEmpty
  }

  /// The number of variables in this expression.
  @inlinable
  package var count: Int {
    variables.count
  }

  /// The template string representation of this expression (without braces).
  @inlinable
  package var templateRepresentation: String {
    let variables = variables
      .lazy
      .map(\.templateRepresentation)
      .joined(separator: ", ")
    return "\(expansionType.formatString)\(variables)"
  }
  
  /// Injects this expression's variables into the given set.
  ///
  /// - Parameter receiver: The set to receive the variables.
  @inlinable
  package func injectTemplateVariables(into receiver: inout Set<URITemplateVariable>) {
    receiver.formUnion(variables)
  }

}

// MARK: - Validatable

extension URITemplateExpressionComponent {

  /// Indicates whether all variables in this expression are valid.
  @inlinable
  package var isValid: Bool {
    variables.allSatisfy(\.isValid)
  }

}
