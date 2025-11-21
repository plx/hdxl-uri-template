import Foundation

extension URIVariableTextValue {
  
  @usableFromInline
  internal enum ExpansionError : Error, LocalizedError {
    
    case unableToEscapeVariableValue(String, String, URIValueExpansionType, URIValueExpansionModifier)
    case unableToEscapeVariableName(String, URIValueExpansionType)
    case unableToEscapeTextValue(String, URIValueExpansionType)
    
    @usableFromInline
    internal var localizedDescription: String {
      switch self {
      case .unableToEscapeVariableValue(let textValue, let variableName, let expansionType, let expansionModifier):
        """
        Unable to escape "\(textValue)" with expansion-type \(expansionType.debugDescription), expansion-modifier \(expansionModifier.debugDescription) (as variable "\(variableName)").
        """
      case .unableToEscapeVariableName(let variableName, let expansionType):
        """
        Unable to escape variable-name "\(variableName)" with expansion-type \(expansionType.debugDescription).
        """
      case .unableToEscapeTextValue(let textContent, let expansionType):
        """
        Unable to escape text "\(textContent)" with expansion-type \(expansionType.debugDescription).
        """
      }
    }
  }
  
  @inlinable
  internal func escapedContents(
    expansionType: URIValueExpansionType
  ) throws -> String {
    guard let result = rawValue.escaped(forValueExpansionType: expansionType) else {
      throw ExpansionError.unableToEscapeTextValue(rawValue, expansionType)
    }
    
    return result
  }
  
  @inlinable
  internal func expansion(
    expansionType: URIValueExpansionType,
    templateVariable: URITemplateVariable
  ) throws -> String {
    try expansion(
      expansionType: expansionType,
      variableName: templateVariable.variableName,
      expansionModifier: templateVariable.expansionModifier
    )
  }
  
  @inlinable
  func expansion(
    expansionType: URIValueExpansionType,
    variableName: URITemplateVariableName,
    expansionModifier: URIValueExpansionModifier
  ) throws -> String {
    guard
      let escapedVariableValue = escapedVariableValue(
        expansionType: expansionType,
        expansionModifier: expansionModifier
      )
    else {
      throw ExpansionError.unableToEscapeVariableValue(
        rawValue,
        variableName.rawValue,
        expansionType,
        expansionModifier
      )
    }
    switch variableName.escapedVariableName(forExpansionType: expansionType) {
    case .unnecessary:
      return escapedVariableValue
    case .escaped(let variableName):
      return switch (escapedVariableValue.isEmpty, expansionType) {
        // RFC 6570 Section 3.2.7: Path-style parameters omit the "=" for empty values
        case (true, .pathParameter):
          variableName
        case (true, _):
          "\(variableName)="
        case (false, _):
          "\(variableName)=\(escapedVariableValue)"
      }
    case .failure:
      throw ExpansionError.unableToEscapeVariableName(
        variableName.rawValue,
        expansionType
      )
    }
  }
  
  @inlinable
  func escapedVariableValue(
    expansionType: URIValueExpansionType,
    expansionModifier: URIValueExpansionModifier
  ) -> String? {
    effectiveVariableValue(
      forExpansionModifier: expansionModifier
    ).escaped(
      forValueExpansionType: expansionType
    )
  }
  
  @inlinable
  func effectiveVariableValue(
    forExpansionModifier expansionModifier: URIValueExpansionModifier
  ) -> String {
    return switch expansionModifier {
    case .unmodified:
      rawValue
    case .explode:
      rawValue
    case .prefix(let codePointCount):
      rawValue.constrained(
        toCodePointCount: codePointCount
      )
    }
  }
  
  
}
