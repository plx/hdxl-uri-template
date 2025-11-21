import Foundation

// MARK: URITemplateVariable

@usableFromInline
package struct URITemplateVariable {
  
  @usableFromInline
  package var variableName: URITemplateVariableName
  
  @usableFromInline
  package var expansionModifier: URIValueExpansionModifier
  
  @inlinable
  package init(
    variableName: URITemplateVariableName,
    expansionModifier: URIValueExpansionModifier
  ) {
    self.variableName = variableName
    self.expansionModifier = expansionModifier
  }
  
}

// MARK: - Synthesized Conformances

extension URITemplateVariable : Sendable { }
extension URITemplateVariable : Equatable { }
extension URITemplateVariable : Hashable { }
extension URITemplateVariable : Codable { }

// MARK: - Comparable

extension URITemplateVariable : Comparable {
  
  @inlinable
  package static func <(
    lhs: URITemplateVariable,
    rhs: URITemplateVariable
  ) -> Bool {
    guard lhs.variableName == rhs.variableName else {
      return lhs.variableName < rhs.variableName
    }
    
    return lhs.expansionModifier < rhs.expansionModifier
  }
  
}

// MARK: - CustomStringConvertible

extension URITemplateVariable : CustomStringConvertible {
  
  @usableFromInline
  package var description: String {
    "\"\(variableName)\", \(expansionModifier.description)"
  }
  
}

// MARK: - CustomDebugStringConvertible

extension URITemplateVariable : CustomDebugStringConvertible {
  
  @usableFromInline
  package var debugDescription: String {
    "URITemplateVariable(variableName: \(String(reflecting: variableName)), expansionModifier: \(String(reflecting: expansionModifier)))"
  }
  
}

// MARK: - Core API

extension URITemplateVariable {
  
  @inlinable
  package var templateRepresentation: String {
    "\(variableName.rawValue)\(expansionModifier.templateRepresentation)"
  }
  
}

// MARK: - Validatable

extension URITemplateVariable {
  
  @inlinable
  package var isValid: Bool {
    variableName.isValid && expansionModifier.isValid
  }
  
}
