import Foundation

extension URIVariableAssociationValue {

  @usableFromInline
  internal enum ExpansionError : Error, LocalizedError {
    case internalAssociationKeyFailedToEscape([(String,String)], String, String, URIValueExpansionType)
    case internalAssociationValueFailedToEscape([(String,String)], String, String, URIValueExpansionType)
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
  internal func expansion(
    expansionType: URIValueExpansionType,
    variableName: URITemplateVariableName,
    expansionModifier: URIValueExpansionModifier
  ) throws -> String {
#if HEAVY_DEBUG
    pedanticAssert(variableName.isValid)
    pedanticAssert(expansionModifier.isValid)
    pedanticAssert(isValid)
#endif
    guard !isEmpty else {
      return ""
    }
    return switch expansionModifier {
    case .unmodified:
      try unexplodedExpansion(
        expansionType: expansionType,
        variableName: variableName
      )
    case .explode:
      try explodedExpansion(
        expansionType: expansionType,
        variableName: variableName
      )
    case .prefix(_):
      try unexplodedExpansion(
        expansionType: expansionType,
        variableName: variableName
      )
    }
  }

  @inlinable
  internal func explodedExpansion(
    expansionType: URIValueExpansionType,
    variableName: URITemplateVariableName
  ) throws -> String {
#if HEAVY_DEBUG
    pedanticAssert(variableName.isValid)
    pedanticAssert(isValid)
#endif
    return try storage
      .lazy
      .map {
        pair
        in
        guard let escapedKey = pair.key.rawValue.escaped(forValueExpansionType: expansionType) else {
          throw ExpansionError.internalAssociationKeyFailedToEscape(
            storage.map({ ($0.key.rawValue, $0.value.rawValue) }),
            pair.key.rawValue,
            variableName.rawValue,
            expansionType
          )
        }
        guard let escapedValue = pair.value.rawValue.escaped(forValueExpansionType: expansionType) else {
          throw ExpansionError.internalAssociationValueFailedToEscape(
            storage.map({ ($0.key.rawValue, $0.value.rawValue) }),
            pair.key.rawValue,
            variableName.rawValue,
            expansionType
          )
        }

        switch escapedValue.isEmpty {
        case true:
          return "\(escapedKey)\(expansionType.emptyValueSuffix)"
        case false:
          return "\(escapedKey)=\(escapedValue)"
        }
      }
      .joined(separator: expansionType.separatorForExpandedVariableList)
  }

  @inlinable
  internal func unexplodedExpansion(
    expansionType: URIValueExpansionType,
    variableName: URITemplateVariableName
  ) throws -> String {
#if HEAVY_DEBUG
    pedanticAssert(variableName.isValid)
    pedanticAssert(isValid)
#endif
    let joinedPairs = try storage
      .lazy
      .map {
        pair
        in
        let escapedKey = try pair.key.escapedContents(expansionType: expansionType)
        /*else {
          throw ExpansionError.internalAssociationKeyFailedToEscape(
            storage.map({ ($0.key.rawValue, $0.value.rawValue) }),
            pair.key.rawValue,
            variableName.rawValue,
            expansionType
          )
        }*/
        let escapedValue = try pair.value.escapedContents(expansionType: expansionType)
        /*else {
          throw ExpansionError.internalAssociationValueFailedToEscape(
            storage.map({ ($0.key.rawValue, $0.value.rawValue) }),
            pair.key.rawValue,
            variableName.rawValue,
            expansionType
          )
        }*/
        return "\(escapedKey),\(escapedValue)"
      }
      .joined(separator: ",")

    switch variableName.escapedVariableName(forExpansionType: expansionType) {
    case .unnecessary:
      return joinedPairs
    case .escaped(let escapedName):
      return "\(escapedName)=\(joinedPairs)"
    case .failure:
      throw URIVariableTextValue.ExpansionError.unableToEscapeVariableName(
        variableName.rawValue,
        expansionType
      )
    }
  }

}
