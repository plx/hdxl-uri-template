
import Foundation

extension URIVariableValue {

  @usableFromInline
  internal enum ExpansionError: Error, LocalizedError {
    case prefixModifierNotApplicable(
      variableName: String,
      expansionModifier: URIValueExpansionModifier,
      valueType: URIVariableValueType
    )

    @usableFromInline
    internal var errorDescription: String? {
      switch self {
      case .prefixModifierNotApplicable(
        let variableName,
        let expansionModifier,
        let valueType
      ):
        """
        Prefix modifier `\(expansionModifier.templateRepresentation)` is not \
        applicable to \(valueType) value for variable `\(variableName)`.
        """
      }
    }
  }
  
  @inlinable
  internal func evaluate(
    expansionType: URIValueExpansionType,
    templateVariable: URITemplateVariable
  ) throws -> String {
    if
      templateVariable.expansionModifier.isPrefixType,
      storage.isListValue || storage.isAssociationValue {
      throw ExpansionError.prefixModifierNotApplicable(
        variableName: templateVariable.variableName.rawValue,
        expansionModifier: templateVariable.expansionModifier,
        valueType: storage.valueType
      )
    }

    return switch storage {
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
