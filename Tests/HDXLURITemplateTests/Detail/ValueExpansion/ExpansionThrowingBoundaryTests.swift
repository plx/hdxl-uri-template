import Testing

@testable import HDXLURITemplate

@Test("Only the composite-prefix semantic boundary throws")
private func expansionThrowingBoundaryIsNarrow() throws {
  let name = URITemplateVariableName(rawValue: "value")
  let unmodifiedVariable = URITemplateVariable(
    variableName: name,
    expansionModifier: .unmodified
  )
  let prefixVariable = URITemplateVariable(
    variableName: name,
    expansionModifier: .prefix(1)
  )
  let text = URIVariableTextValue(rawValue: "text")
  let list = URIVariableListValue(strings: ["one", "two"])
  let association = try URIVariableAssociationValue(
    validatingStrings: [("key", "value")]
  )

  requireNonthrowing {
    text.escapedContents(expansionType: .simple)
  }
  requireNonthrowing {
    text.expansion(
      expansionType: .simple,
      templateVariable: unmodifiedVariable
    )
  }
  requireNonthrowing {
    text.expansion(
      expansionType: .simple,
      variableName: name,
      expansionModifier: .unmodified
    )
  }

  requireNonthrowing {
    list.expansion(
      expansionType: .query,
      templateVariable: unmodifiedVariable
    )
  }
  requireNonthrowing {
    list.expansion(
      expansionType: .query,
      variableName: name,
      expansionModifier: .explode
    )
  }
  requireNonthrowing {
    list.explodedRepresentation(
      of: text,
      expansionType: .query,
      escapedVariableName: name.escapedAsLiteral
    )
  }
  requireNonthrowing {
    list.explodedExpansion(
      expansionType: .query,
      variableName: name
    )
  }
  requireNonthrowing {
    list.unexplodedExpansion(
      expansionType: .query,
      variableName: name
    )
  }

  requireNonthrowing {
    association.expansion(
      expansionType: .query,
      templateVariable: unmodifiedVariable
    )
  }
  requireNonthrowing {
    association.expansion(
      expansionType: .query,
      variableName: name,
      expansionModifier: .explode
    )
  }
  requireNonthrowing {
    association.explodedExpansion(
      expansionType: .query,
      variableName: name
    )
  }
  requireNonthrowing {
    association.unexplodedExpansion(
      expansionType: .query,
      variableName: name
    )
  }

  let parameters = [
    name.rawValue: URIVariableValue.list(["one", "two"])
  ]
  func evaluateValue() throws(URIVariableValue.ExpansionError) -> String {
    try URIVariableValue.list(["one", "two"]).evaluate(
      expansionType: .simple,
      templateVariable: prefixVariable
    )
  }
  func evaluateVariable() throws(URIVariableValue.ExpansionError) -> String {
    try prefixVariable.evaluate(
      parameters: parameters,
      expansionType: .simple
    )
  }
  func evaluateVariableIfDefined()
    throws(URIVariableValue.ExpansionError) -> String?
  {
    try prefixVariable.evaluateIfDefined(
      parameters: parameters,
      expansionType: .simple
    )
  }
  func evaluateExpression() throws(URIVariableValue.ExpansionError) -> String {
    try URITemplateExpressionComponent(
      expansionType: .simple,
      variable: prefixVariable
    ).evaluate(parameters: parameters)
  }

  requireExpansionErrorSignature(evaluateValue)
  requireExpansionErrorSignature(evaluateVariable)
  requireExpansionErrorSignature(evaluateVariableIfDefined)
  requireExpansionErrorSignature(evaluateExpression)
}

private func requireNonthrowing<Result>(
  _ operation: () -> Result
) {
  _ = operation()
}

private func requireExpansionErrorSignature<Result>(
  _ operation: () throws(URIVariableValue.ExpansionError) -> Result
) {
  _ = operation
}
