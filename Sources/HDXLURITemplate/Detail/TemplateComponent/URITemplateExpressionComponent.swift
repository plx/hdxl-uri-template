
// MARK: URITemplateExpressionComponent

@usableFromInline
package struct URITemplateExpressionComponent {
  
  @usableFromInline
  package var expansionType: URIValueExpansionType
  
  @usableFromInline
  package var variables: [URITemplateVariable]
  
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
  
  @inlinable
  package var isEmpty: Bool {
    variables.isEmpty
  }
  
  @inlinable
  package var count: Int {
    variables.count
  }
  
  @inlinable
  package var templateRepresentation: String {
    let variables = variables
      .lazy
      .map(\.templateRepresentation)
      .joined(separator: ", ")
    return "\(expansionType.formatString)\(variables)"
  }
  
  @inlinable
  package func injectTemplateVariables(into receiver: inout Set<URITemplateVariable>) {
    receiver.formUnion(variables)
  }
  
}

// MARK: - Validatable

extension URITemplateExpressionComponent {
  
  @inlinable
  package var isValid: Bool {
    variables.allSatisfy(\.isValid)
  }
  
}
