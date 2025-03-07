import Foundation

internal extension URIVariableListValue {
  
  @usableFromInline
  enum ExpansionError : Error, LocalizedError {
    case internalValueFailedToEscape([String], String, String, URIValueExpansionType)
    case unableToEscapeVariableName(String, URIValueExpansionType)
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
    guard !isEmpty else {
      return ""
    }
    switch expansionModifier {
    case .unmodified:
      return try unexplodedExpansion(
        expansionType: expansionType,
        variableName: variableName
      )
    case .explode:
      return try explodedExpansion(
        expansionType: expansionType,
        variableName: variableName
      )
    case .prefix(_):
      return try unexplodedExpansion(
        expansionType: expansionType,
        variableName: variableName
      )
    }
  }
  
  @inlinable
  func explodedExpansion(
    expansionType: URIValueExpansionType,
    variableName: URITemplateVariableName
  ) throws -> String {
#if HEAVY_DEBUG
    pedanticAssert(variableName.isValid)
    pedanticAssert(isValid)
#endif
    // we inline this logic instead of using `variableName.escapedVariableName`
    // because the code flow is a bit weird (despite originally intending to do it like that...)
    guard let escapedName = variableName.storage.escaped(forValueExpansionType: expansionType) else {
      throw ExpansionError.unableToEscapeVariableName(
        variableName.storage,
        expansionType
      )
    }
    return try storage
      .lazy
      .map() {
        (text)
        in
        guard let escapedValue = text.storage.escaped(forValueExpansionType: expansionType) else {
          throw ExpansionError.internalValueFailedToEscape(
            storage.map({$0.storage}),
            text.storage,
            variableName.storage,
            expansionType
          )
        }
        return "\(escapedName)=\(escapedValue)"
    }.joined(
      separator: expansionType.separatorForExpandedVariableList
    )
  }

  @inlinable
  func unexplodedExpansion(
    expansionType: URIValueExpansionType,
    variableName: URITemplateVariableName
  ) throws -> String {
#if HEAVY_DEBUG
    pedanticAssert(variableName.isValid)
    pedanticAssert(isValid)
#endif
    let joinedValues = try storage
      .lazy
      .map() {
        (text)
        in
        guard let escaped = text.storage.escaped(forValueExpansionType: expansionType) else {
          throw ExpansionError.internalValueFailedToEscape(
            storage.map({$0.storage}),
            text.storage,
            variableName.storage,
            expansionType
          )
        }
        return escaped
    }.joined(
      separator: expansionType.separatorForExpandedVariableList
    )
    switch variableName.escapedVariableName(forExpansionType: expansionType) {
    case .unnecessary:
      return joinedValues
    case .escaped(let escapedName):
      return "\(escapedName)=\(joinedValues)"
    case .failure:
      throw ExpansionError.unableToEscapeVariableName(
        variableName.storage,
        expansionType
      )
    }
  }

}

