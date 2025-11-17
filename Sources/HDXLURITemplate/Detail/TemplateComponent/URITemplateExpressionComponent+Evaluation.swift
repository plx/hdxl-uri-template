
extension URITemplateExpressionComponent {
  
  @inlinable
  internal func evaluate(parameters: [String: URIVariableValue]) throws -> String {
    let expansion = try variables
      .lazy
      .map { try $0.evaluate(parameters: parameters, expansionType: expansionType) }
      .joined(separator: expansionType.separatorForExpandedVariableList)
    
    guard !expansion.isEmpty else {
      return ""
    }
    
    return "\(expansionType.prefixForExpandedVariableList)\(expansion)"
  }
  
}
