import Foundation

extension URIVariableListValue {
  
  @usableFromInline
  internal enum ExpansionError : Error, LocalizedError {
    case internalValueFailedToEscape([String], String, String, URIValueExpansionType)
    case unableToEscapeVariableName(String, URIValueExpansionType)
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
  internal func expansion(
    expansionType: URIValueExpansionType,
    variableName: URITemplateVariableName,
    expansionModifier: URIValueExpansionModifier
  ) throws -> String {
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
  internal func explodedRepresentation(
    of text: URIVariableTextValue,
    expansionType: URIValueExpansionType,
    escapedVariableName: String
  ) throws -> String {
    let escapedText = try text.escapedContents(expansionType: expansionType)
    
    return switch expansionType {
    case .simple:
      escapedText
    case .reserved:
      escapedText
    case .fragment:
      escapedText
    case .label:
      escapedText
    case .pathSegment:
      escapedText
    case .pathParameter:
      "\(escapedVariableName)=\(escapedText)"
    case .query:
      "\(escapedVariableName)=\(escapedText)"
    case .queryContinuation:
      "\(escapedVariableName)=\(escapedText)"
    }
  }
  
  @inlinable
  internal func explodedExpansion(
    expansionType: URIValueExpansionType,
    variableName: URITemplateVariableName
  ) throws -> String {
    // we inline this logic instead of using `variableName.escapedVariableName`
    // because the code flow is a bit weird (despite originally intending to do it like that...)
    guard let escapedName = variableName.rawValue.escaped(forValueExpansionType: expansionType) else {
      throw ExpansionError.unableToEscapeVariableName(
        variableName.rawValue,
        expansionType
      )
    }
    return try storage
      .lazy
      .map { text in
        try explodedRepresentation(
          of: text,
          expansionType: expansionType,
          escapedVariableName: escapedName
        )
    }.joined(
      separator: expansionType.separatorForExpandedVariableList
    )
  }

  @inlinable
  internal func unexplodedExpansion(
    expansionType: URIValueExpansionType,
    variableName: URITemplateVariableName
  ) throws -> String {
    let joinedValues = try storage
      .lazy
      .map { text in
        guard let escaped = text.rawValue.escaped(forValueExpansionType: expansionType) else {
          throw ExpansionError.internalValueFailedToEscape(
            storage.map({$0.rawValue}),
            text.rawValue,
            variableName.rawValue,
            expansionType
          )
        }
        return escaped
    }.joined(
      separator: ","
    )
    switch variableName.escapedVariableName(forExpansionType: expansionType) {
    case .unnecessary:
      return joinedValues
    case .escaped(let escapedName):
      return "\(escapedName)=\(joinedValues)"
    case .failure:
      throw ExpansionError.unableToEscapeVariableName(
        variableName.rawValue,
        expansionType
      )
    }
  }

}

