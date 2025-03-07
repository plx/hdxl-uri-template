import Foundation

extension URIVariableTextValue {
  
  @usableFromInline
  internal enum ExpansionError : Error, LocalizedError {
    
    case unableToEscapeVariableValue(String, String, URIValueExpansionType, URIValueExpansionModifier)
    case unableToEscapeVariableName(String, URIValueExpansionType)
    
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
      }
    }
  }
  
  @inlinable
  func expansion(
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
    guard let escapedVariableValue = escapedVariableValue(
      expansionType: expansionType,
      expansionModifier: expansionModifier) else {
        throw ExpansionError.unableToEscapeVariableValue(
          storage,
          variableName.storage,
          expansionType,
          expansionModifier
        )
    }
    switch variableName.escapedVariableName(forExpansionType: expansionType) {
    case .unnecessary:
      return escapedVariableValue
    case .escaped(let variableName):
      switch escapedVariableValue.isEmpty {
      case true:
        return variableName
      case false:
        return "\(variableName)=\(escapedVariableValue)"
      }
    case .failure:
      throw ExpansionError.unableToEscapeVariableName(
        variableName.storage,
        expansionType
      )
    }
  }
  
  @inlinable
  func escapedVariableValue(
    expansionType: URIValueExpansionType,
    expansionModifier: URIValueExpansionModifier
  ) -> String? {
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
    switch expansionModifier {
    case .unmodified:
      return storage
    case .explode:
      return storage
    case .prefix(let codePointCount):
      return storage.constrained(
        toCodePointCount: codePointCount
      )
    }
  }
  
  
}
