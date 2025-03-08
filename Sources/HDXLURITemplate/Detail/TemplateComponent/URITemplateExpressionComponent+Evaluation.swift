
//extension URITemplateExpressionComponent {
//  
//  @inlinable
//  internal func evaluate(parameters: [String: URIVariableValue]) throws -> String {
//    let expansion = try variables
//      .lazy
//      .map { try $0.evaluate(parameters: parameters) }
//      .joined(separator: expansionType.separatorForExpandedVariableList)
//    
//    return "\(expansionType.prefixForExpandedVariableList)\(expansion)"
//  }
//  
//}
