//
//  URIVariableTextValue+ValueExpansion.swift
//

import Foundation
import HDXLCommonUtilities

internal extension URIVariableTextValue {
  
  @usableFromInline
  enum ExpansionError : Error, LocalizedError {
    
    case unableToEscapeVariableValue(String, String, URIValueExpansionType, URIValueExpansionModifier)
    case unableToEscapeVariableName(String, URIValueExpansionType)
    
    internal var localizedDescription: String {
      get {
        switch self {
        case .unableToEscapeVariableValue(let textValue, let variableName, let expansionType, let expansionModifier):
          return """
          Unable to escape "\(textValue)" with expansion-type \(expansionType.debugDescription), expansion-modifier \(expansionModifier.debugDescription) (as variable "\(variableName)").
          """
        case .unableToEscapeVariableName(let variableName, let expansionType):
          return """
          Unable to escape variable-name "\(variableName)" with expansion-type \(expansionType.debugDescription).
          """
        }
      }
    }
  }
  
  @inlinable
  func expansion(
    expansionType: URIValueExpansionType,
    templateVariable: URITemplateVariable) throws -> String {
    // /////////////////////////////////////////////////////////////////////////
    pedantic_assert(templateVariable.isValid)
    pedantic_assert(self.isValid)
    // /////////////////////////////////////////////////////////////////////////
    return try self.expansion(
      expansionType: expansionType,
      variableName: templateVariable.variableName,
      expansionModifier: templateVariable.expansionModifier
    )
  }
  
  @inlinable
  func expansion(
    expansionType: URIValueExpansionType,
    variableName: URITemplateVariableName,
    expansionModifier: URIValueExpansionModifier) throws -> String {
    // /////////////////////////////////////////////////////////////////////////
    pedantic_assert(variableName.isValid)
    pedantic_assert(expansionModifier.isValid)
    pedantic_assert(self.isValid)
    // /////////////////////////////////////////////////////////////////////////
    guard let escapedVariableValue = self.escapedVariableValue(
      expansionType: expansionType,
      expansionModifier: expansionModifier) else {
        throw ExpansionError.unableToEscapeVariableValue(
          self.storage,
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
    expansionModifier: URIValueExpansionModifier) -> String? {
    // /////////////////////////////////////////////////////////////////////////
    pedantic_assert(expansionModifier.isValid)
    pedantic_assert(self.isValid)
    // /////////////////////////////////////////////////////////////////////////
    return self.effectiveVariableValue(
      forExpansionModifier: expansionModifier
    ).escaped(
      forValueExpansionType: expansionType
    )
  }
  
  @inlinable
  func effectiveVariableValue(
    forExpansionModifier expansionModifier: URIValueExpansionModifier) -> String {
    // /////////////////////////////////////////////////////////////////////////
    pedantic_assert(expansionModifier.isValid)
    pedantic_assert(self.isValid)
    // /////////////////////////////////////////////////////////////////////////
    switch expansionModifier {
    case .unmodified:
      return self.storage
    case .explode:
      return self.storage
    case .prefix(let codePointCount):
      return self.storage.constrained(
        toCodePointCount: codePointCount
      )
    }
  }
  
  
}
