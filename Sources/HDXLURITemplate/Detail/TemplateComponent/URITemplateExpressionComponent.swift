
// -------------------------------------------------------------------------- //
// MARK: URITemplateExpressionComponent - Definition
// -------------------------------------------------------------------------- //

internal struct URITemplateExpressionComponent {
  
  internal var expansionType: URIValueExpansionType
  
  internal var variables: [URITemplateVariable]
  
  internal init(
    expansionType: URIValueExpansionType,
    variable: URITemplateVariable
  ) {
    #if HEAVY_DEBUG
    pedanticAssert(variable.isValid)
    #endif
    self.init(
      expansionType: expansionType,
      variables: [variable]
    )
  }

  internal init(
    expansionType: URIValueExpansionType,
    variables: [URITemplateVariable]
  ) {
#if HEAVY_DEBUG
    pedanticAssert(!variables.isEmpty)
    pedanticAssert(variables.allSatisfy(\.isValid))
    defer { pedanticAssert(isValid)}
#endif
    self.expansionType = expansionType
    self.variables = variables
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: - Synthesized Conformances
// -------------------------------------------------------------------------- //

extension URITemplateExpressionComponent: Sendable { }
extension URITemplateExpressionComponent: Equatable { }
extension URITemplateExpressionComponent: Hashable { }

// -------------------------------------------------------------------------- //
// MARK: - Comparable
// -------------------------------------------------------------------------- //

extension URITemplateExpressionComponent : Comparable {

  internal static func <(
    lhs: URITemplateExpressionComponent,
    rhs: URITemplateExpressionComponent
  ) -> Bool {
#if HEAVY_DEBUG
    pedanticAssert(lhs.isValid)
    pedanticAssert(rhs.isValid)
#endif
    guard lhs.expansionType == rhs.expansionType else {
      return lhs.expansionType < rhs.expansionType
    }
    return lhs.variables.lexicographicallyPrecedes(rhs.variables)
  }

}

// -------------------------------------------------------------------------- //
// MARK: - CustomStringConvertible
// -------------------------------------------------------------------------- //

extension URITemplateExpressionComponent : CustomStringConvertible {
  
  internal var description: String {
    let variables = variables
      .lazy
      .map(\.description)
      .joined(separator: ", ")
    return "\(expansionType.description) for [ \(variables) ]"
  }

}

// -------------------------------------------------------------------------- //
// MARK: - CustomDebugStringConvertible
// -------------------------------------------------------------------------- //

extension URITemplateExpressionComponent : CustomDebugStringConvertible {
  
  internal var debugDescription: String {
    let variables = variables
      .lazy
      .map(\.debugDescription)
      .joined(separator: ", ")
    
    return "URITemplateExpressionComponent(expansionType: \(expansionType.debugDescription), variables: [ \(variables) ])"
  }

}

// -------------------------------------------------------------------------- //
// MARK: - Core API
// -------------------------------------------------------------------------- //

extension URITemplateExpressionComponent {
  
  internal var isEmpty: Bool {
    variables.isEmpty
  }
  
  internal var count: Int {
    variables.count
  }
  
  internal var templateRepresentation: String {
    let variables = variables
      .lazy
      .map(\.templateRepresentation)
      .joined(separator: ",")
    return "\(expansionType.formatString)\(variables)"
  }
  
  internal func injectTemplateVariables(into receiver: inout Set<URITemplateVariable>) {
    receiver.formUnion(variables)
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: - Validatable
// -------------------------------------------------------------------------- //

extension URITemplateExpressionComponent {
  
  internal var isValid: Bool {
    !variables.isEmpty
      && variables.allSatisfy(\.isValid)
  }
  
}
