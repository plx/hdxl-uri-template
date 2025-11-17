import Foundation

extension URITemplateVariable {
  
  public enum ExpansionError: Error, LocalizedError {
    case variableNotFound(String)
  }
  
  @inlinable
  internal func evaluate(
    parameters: [String: URIVariableValue],
    expansionType: URIValueExpansionType
  ) throws -> String {
    guard let value = parameters[variableName.rawValue] else {
      throw ExpansionError.variableNotFound(variableName.rawValue)
    }
    
    return try value.evaluate(
      expansionType: expansionType,
      templateVariable: self
    )
  }
  
}
