import Foundation

extension URITemplateVariable {
  
  public enum ExpansionError: Error, LocalizedError {
    case variableNotFound(String)
  }
  
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
