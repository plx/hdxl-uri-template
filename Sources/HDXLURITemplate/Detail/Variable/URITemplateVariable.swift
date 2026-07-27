import Foundation

// -------------------------------------------------------------------------- //
// MARK: URITemplateVariable - Definition
// -------------------------------------------------------------------------- //

internal struct URITemplateVariable {
  
  internal var variableName: URITemplateVariableName
  
  internal var expansionModifier: URIValueExpansionModifier
  
  internal init(
    variableName: URITemplateVariableName,
    expansionModifier: URIValueExpansionModifier
  ) {
#if HEAVY_DEBUG
    pedanticAssert(variableName.isValid)
    pedanticAssert(expansionModifier.isValid)
    defer { pedanticAssert(isValid) }
#endif
    self.variableName = variableName
    self.expansionModifier = expansionModifier
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: - Synthesized Conformances
// -------------------------------------------------------------------------- //

extension URITemplateVariable : Sendable { }
extension URITemplateVariable : Equatable { }
extension URITemplateVariable : Hashable { }

// -------------------------------------------------------------------------- //
// MARK: - Comparable
// -------------------------------------------------------------------------- //

extension URITemplateVariable : Comparable {
  
  internal static func <(
    lhs: URITemplateVariable,
    rhs: URITemplateVariable
  ) -> Bool {
#if HEAVY_DEBUG
    pedanticAssert(lhs.isValid)
    pedanticAssert(rhs.isValid)
#endif
    guard lhs.variableName == rhs.variableName else {
      return lhs.variableName < rhs.variableName
    }
    
    return lhs.expansionModifier < rhs.expansionModifier
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: - CustomStringConvertible
// -------------------------------------------------------------------------- //

extension URITemplateVariable : CustomStringConvertible {
  
  internal var description: String {
    "\"\(variableName)\", \(expansionModifier.description)"
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: URITemplateVariable - CustomDebugStringConvertible
// -------------------------------------------------------------------------- //

extension URITemplateVariable : CustomDebugStringConvertible {
  
  internal var debugDescription: String {
    "URITemplateVariable(variableName: \(String(reflecting: variableName)), expansionModifier: \(String(reflecting: expansionModifier)))"
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: - Core API
// -------------------------------------------------------------------------- //

extension URITemplateVariable {
  
  internal var templateRepresentation: String {
    "\(variableName.rawValue)\(expansionModifier.templateRepresentation)"
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: - Validatable
// -------------------------------------------------------------------------- //

extension URITemplateVariable {
  
  internal var isValid: Bool {
    variableName.isValid && expansionModifier.isValid
  }
  
}
