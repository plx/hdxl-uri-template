import Foundation

// MARK: URITemplateVariable

@usableFromInline
internal struct URITemplateVariable {
  
  @usableFromInline
  internal var variableName: URITemplateVariableName
  
  @usableFromInline
  internal var expansionModifier: URIValueExpansionModifier
  
  @inlinable
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

// MARK: - Synthesized Conformances

extension URITemplateVariable : Sendable { }
extension URITemplateVariable : SendableMetatype { }
extension URITemplateVariable : Equatable { }
extension URITemplateVariable : Hashable { }
extension URITemplateVariable : Codable { }

// MARK: - Comparable

extension URITemplateVariable : Comparable {
  
  @inlinable
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

// MARK: - CustomStringConvertible

extension URITemplateVariable : CustomStringConvertible {
  
  @usableFromInline
  internal var description: String {
    "\"\(variableName)\", \(expansionModifier.description)"
  }
  
}

// MARK: - CustomDebugStringConvertible

extension URITemplateVariable : CustomDebugStringConvertible {
  
  @usableFromInline
  internal var debugDescription: String {
    "URITemplateVariable(variableName: \(String(reflecting: variableName)), expansionModifier: \(String(reflecting: expansionModifier)))"
  }
  
}

// MARK: - Core API

extension URITemplateVariable {
  
  @inlinable
  internal var templateRepresentation: String {
    "\(variableName.rawValue)\(expansionModifier.templateRepresentation)"
  }
  
}

// MARK: - Validatable

extension URITemplateVariable {
  
  @inlinable
  internal var isValid: Bool {
    variableName.isValid && expansionModifier.isValid
  }
  
}
