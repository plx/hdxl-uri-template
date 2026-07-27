extension URIVariableAssociationValue {

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

  internal func explodedExpansion(
    expansionType: URIValueExpansionType,
    variableName: URITemplateVariableName
  ) -> String {
    #if HEAVY_DEBUG
      pedanticAssert(variableName.isValid)
      pedanticAssert(isValid)
    #endif
    return storage
      .lazy
      .map {
        pair
        in
        let escapedKey = pair.key.rawValue.escaped(forValueExpansionType: expansionType)
        let escapedValue = pair.value.rawValue.escaped(forValueExpansionType: expansionType)

        switch escapedValue.isEmpty {
        case true:
          return "\(escapedKey)\(expansionType.emptyValueSuffix)"
        case false:
          return "\(escapedKey)=\(escapedValue)"
        }
      }
      .joined(separator: expansionType.separatorForExpandedVariableList)
  }

  internal func unexplodedExpansion(
    expansionType: URIValueExpansionType,
    variableName: URITemplateVariableName
  ) -> String {
    #if HEAVY_DEBUG
      pedanticAssert(variableName.isValid)
      pedanticAssert(isValid)
    #endif
    let joinedPairs = storage
      .lazy
      .map {
        pair
        in
        let escapedKey = pair.key.escapedContents(expansionType: expansionType)
        let escapedValue = pair.value.escapedContents(expansionType: expansionType)
        return "\(escapedKey),\(escapedValue)"
      }
      .joined(separator: ",")

    switch variableName.escapedVariableName(forExpansionType: expansionType) {
    case .unnecessary:
      return joinedPairs
    case .escaped(let escapedName):
      return "\(escapedName)=\(joinedPairs)"
    }
  }

}
