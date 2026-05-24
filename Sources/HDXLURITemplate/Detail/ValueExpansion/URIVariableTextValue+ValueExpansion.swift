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
    rawValue.escaped(forValueExpansionType: expansionType)
  }
  
  @inlinable
  internal func expansion(
    expansionType: URIValueExpansionType,
    templateVariable: URITemplateVariable
  ) throws -> String {
#if HEAVY_DEBUG
    pedanticAssert(templateVariable.isValid)
    pedanticAssert(isValid)
#endif
    return try expansion(
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
#if HEAVY_DEBUG
    pedanticAssert(variableName.isValid)
    pedanticAssert(expansionModifier.isValid)
    pedanticAssert(isValid)
#endif
    let escapedVariableValue = escapedVariableValue(
      expansionType: expansionType,
      expansionModifier: expansionModifier
    )
    switch variableName.escapedVariableName(forExpansionType: expansionType) {
    case .unnecessary:
      return escapedVariableValue
    case .escaped(let variableName):
      return switch escapedVariableValue.isEmpty {
      case true:
        "\(variableName)\(expansionType.emptyValueSuffix)"
      case false:
        "\(variableName)=\(escapedVariableValue)"
      }
    }
  }
  
  @inlinable
  func escapedVariableValue(
    expansionType: URIValueExpansionType,
    expansionModifier: URIValueExpansionModifier
  ) -> String {
#if HEAVY_DEBUG
    pedanticAssert(expansionModifier.isValid)
    pedanticAssert(isValid)
#endif
    return effectiveVariableValue(
      forExpansionModifier: expansionModifier
    ).escaped(
      forValueExpansionType: expansionType
    )
  }
  
  @inlinable
  func effectiveVariableValue(
    forExpansionModifier expansionModifier: URIValueExpansionModifier
  ) -> String {
#if HEAVY_DEBUG
    pedanticAssert(expansionModifier.isValid)
    pedanticAssert(isValid)
#endif
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
