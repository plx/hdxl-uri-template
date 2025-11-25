extension URITemplateExpressionComponent {

  /// Evaluates this expression component with the given parameters.
  ///
  /// - Parameter parameters: A dictionary mapping variable names to their values.
  ///
  /// - Returns: The expanded string for this expression.
  ///
  /// - Throws: An error if variable evaluation fails.
  @inlinable
  package func evaluate(parameters: [String: URIVariableValue]) throws -> String {
    var expansions: [String] = []
    for variable in variables {
      let expansion = try variable.evaluate(
        parameters: parameters,
        expansionType: expansionType
      )
      if !expansion.isEmpty {
        expansions.append(expansion)
      }
    }

    let joinedExpansions = expansions.joined(separator: expansionType.separatorForExpandedVariableList)
    return switch joinedExpansions.isEmpty {
    case true:
      ""
    case false:
      "\(expansionType.prefixForExpandedVariableList)\(joinedExpansions)"
    }
  }
  
}
