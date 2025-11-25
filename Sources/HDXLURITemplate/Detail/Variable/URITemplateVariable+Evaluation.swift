import Foundation

extension URITemplateVariable {

  /// Errors that can occur during variable expansion.
  public enum ExpansionError: Error, LocalizedError {
    /// The variable was not found in the parameters dictionary.
    case variableNotFound(String)
  }

  /// Evaluates this variable with the given parameters and expansion type.
  ///
  /// - Parameters:
  ///   - parameters: A dictionary mapping variable names to their values.
  ///   - expansionType: The expansion type determining how the value is formatted.
  ///
  /// - Returns: The expanded string, or empty string if the variable is undefined.
  ///
  /// - Throws: An error if expansion fails.
  @inlinable
  package func evaluate(
    parameters: [String: URIVariableValue],
    expansionType: URIValueExpansionType
  ) throws -> String {
    // Per RFC 6570 Section 3.2.1: undefined variables should be omitted from expansion
    guard let value = parameters[variableName.rawValue] else {
      return ""
    }

    return try value.evaluate(
      expansionType: expansionType,
      templateVariable: self
    )
  }
  
}
