extension URITemplateExpressionComponent {

  internal func evaluate(
    parameters: [String: URIVariableValue]
  ) throws(URIVariableValue.ExpansionError) -> String {
    var expansions: [String] = []
    for variable in variables {
      if let expansion = try variable.evaluateIfDefined(
        parameters: parameters,
        expansionType: expansionType
      ) {
        expansions.append(expansion)
      }
    }
    guard !expansions.isEmpty else {
      return ""
    }

    let expansion = expansions.joined(separator: expansionType.separatorForExpandedVariableList)

    return "\(expansionType.prefixForExpandedVariableList)\(expansion)"
  }

}
