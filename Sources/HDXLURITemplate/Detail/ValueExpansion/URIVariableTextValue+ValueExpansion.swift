import Foundation

extension URIVariableTextValue {
  
  internal enum ExpansionError : Error, LocalizedError {
    
    case unableToEscapeVariableValue(String, String, URIValueExpansionType, URIValueExpansionModifier)
    case unableToEscapeVariableName(String, URIValueExpansionType)
    case unableToEscapeTextValue(String, URIValueExpansionType)
  }
  
  internal func escapedContents(
    expansionType: URIValueExpansionType
  ) throws -> String {
    rawValue.escaped(forValueExpansionType: expansionType)
  }
  
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
  
  func escapedVariableValue(
    expansionType: URIValueExpansionType,
    expansionModifier: URIValueExpansionModifier
  ) -> String {
#if HEAVY_DEBUG
    pedanticAssert(expansionModifier.isValid)
    pedanticAssert(isValid)
#endif
    return switch expansionModifier {
    case .unmodified, .explode:
      rawValue.escaped(
        forValueExpansionType: expansionType
      )
    case .prefix(let codePointCount):
      rawValue.escaped(
        forValueExpansionType: expansionType,
        maximumDecodedCodePointCount: codePointCount
      )
    }
  }
  
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
        toDecodedURIValueCodePointCount: codePointCount
      )
    }
  }
  
  
}
