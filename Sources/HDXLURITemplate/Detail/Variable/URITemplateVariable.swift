import Foundation

// MARK: URITemplateVariable

/// Represents a single variable within a URI template expression.
///
/// A variable consists of a name and an optional expansion modifier (prefix or explode).
@usableFromInline
package struct URITemplateVariable {

  /// The variable's name.
  @usableFromInline
  package var variableName: URITemplateVariableName

  /// The expansion modifier (unmodified, prefix, or explode).
  @usableFromInline
  package var expansionModifier: URIValueExpansionModifier

  /// Creates a template variable with the given name and modifier.
  ///
  /// - Parameters:
  ///   - variableName: The variable's name.
  ///   - expansionModifier: The expansion modifier to apply.
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

  /// The template string representation of this variable.
  @inlinable
  package var templateRepresentation: String {
    "\(variableName.rawValue)\(expansionModifier.templateRepresentation)"
  }

  @inlinable
  package var underestimatedExpansionLength: Int {
    0 // TODO: more-informed estimation
  }

}

// MARK: - Validatable

extension URITemplateVariable {

  /// Indicates whether both the variable name and modifier are valid.
  @inlinable
  package var isValid: Bool {
    variableName.isValid && expansionModifier.isValid
  }

}
