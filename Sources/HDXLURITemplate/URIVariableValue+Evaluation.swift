
extension URIVariableValue {
  
  @inlinable
  internal func evaluate(
    expansionType: URIValueExpansionType,
    templateVariable: URITemplateVariable
  ) throws -> String {
    switch storage {
    case .undefined:
      ""
    case .text(let textValue):
      try textValue.expansion(
        expansionType: expansionType,
        templateVariable: templateVariable
      )
    case .list(let listValue):
      try listValue.expansion(
        expansionType: expansionType,
        templateVariable: templateVariable
      )
    case .association(let association):
      try association.expansion(
        expansionType: expansionType,
        templateVariable: templateVariable
      )
    }
  }
  
}
