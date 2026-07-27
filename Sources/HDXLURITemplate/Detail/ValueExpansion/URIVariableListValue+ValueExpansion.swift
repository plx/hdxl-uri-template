extension URIVariableListValue {
  
  internal func expansion(
    expansionType: URIValueExpansionType,
    templateVariable: URITemplateVariable
  ) -> String {
#if HEAVY_DEBUG
    pedanticAssert(templateVariable.isValid)
    pedanticAssert(isValid)
#endif
    return expansion(
      expansionType: expansionType,
      variableName: templateVariable.variableName,
      expansionModifier: templateVariable.expansionModifier
    )
  }
  
  internal func expansion(
    expansionType: URIValueExpansionType,
    variableName: URITemplateVariableName,
    expansionModifier: URIValueExpansionModifier
  ) -> String {
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
      unexplodedExpansion(
        expansionType: expansionType,
        variableName: variableName
      )
    case .explode:
      explodedExpansion(
        expansionType: expansionType,
        variableName: variableName
      )
    case .prefix(_):
      unexplodedExpansion(
        expansionType: expansionType,
        variableName: variableName
      )
    }
  }
  
  internal func explodedRepresentation(
    of text: URIVariableTextValue,
    expansionType: URIValueExpansionType,
    escapedVariableName: String
  ) -> String {
    let escapedText = text.escapedContents(expansionType: expansionType)
    
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
      escapedText.isEmpty ? escapedVariableName : "\(escapedVariableName)=\(escapedText)"
    case .query:
      "\(escapedVariableName)=\(escapedText)"
    case .queryContinuation:
      "\(escapedVariableName)=\(escapedText)"
    }
  }
  
  internal func explodedExpansion(
    expansionType: URIValueExpansionType,
    variableName: URITemplateVariableName
  ) -> String {
#if HEAVY_DEBUG
    pedanticAssert(variableName.isValid)
    pedanticAssert(isValid)
#endif
    let escapedName = variableName.escapedAsLiteral
    return storage
      .lazy
      .map { text in
        explodedRepresentation(
          of: text,
          expansionType: expansionType,
          escapedVariableName: escapedName
        )
    }.joined(
      separator: expansionType.separatorForExpandedVariableList
    )
  }

  internal func unexplodedExpansion(
    expansionType: URIValueExpansionType,
    variableName: URITemplateVariableName
  ) -> String {
#if HEAVY_DEBUG
    pedanticAssert(variableName.isValid)
    pedanticAssert(isValid)
#endif
    let joinedValues = storage
      .lazy
      .map { text in
        text.rawValue.escaped(forValueExpansionType: expansionType)
    }.joined(
      separator: ","
    )
    switch variableName.escapedVariableName(forExpansionType: expansionType) {
    case .unnecessary:
      return joinedValues
    case .escaped(let escapedName):
      return "\(escapedName)=\(joinedValues)"
    }
  }

}
