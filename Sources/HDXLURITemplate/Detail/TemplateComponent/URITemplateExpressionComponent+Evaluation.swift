
extension URITemplateExpressionComponent {

  @inlinable
  internal func evaluate(parameters: [String: URIVariableValue]) throws -> String {
    let expansions = try variables
      .lazy
      .compactMap { try $0.evaluateIfDefined(parameters: parameters, expansionType: expansionType) }
    guard !expansions.isEmpty else {
      return ""
    }

    let expansion = expansions.joined(separator: expansionType.separatorForExpandedVariableList)

    return "\(expansionType.prefixForExpandedVariableList)\(expansion)"
  }

}
