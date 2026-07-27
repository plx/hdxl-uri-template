import Foundation

extension URIVariableValue {

  @usableFromInline
  internal enum ExpansionError:
    Error,
    LocalizedError,
    CustomStringConvertible,
    CustomDebugStringConvertible
  {
    case prefixModifierNotApplicable(
      variableName: String,
      expansionType: URIValueExpansionType,
      expansionModifier: URIValueExpansionModifier,
      valueType: URIVariableValueType
    )

    @usableFromInline
    internal var errorDescription: String? {
      switch self {
      case .prefixModifierNotApplicable(
        variableName: _,
        let expansionType,
        let expansionModifier,
        let valueType
      ):
        """
        Prefix modifier `\(expansionModifier.templateRepresentation)` is not \
        applicable to a \(valueType) value for \(expansionType) expansion.
        """
      }
    }

    @usableFromInline
    internal var description: String {
      errorDescription ?? "URI template value expansion failed."
    }

    @usableFromInline
    internal var debugDescription: String {
      description
    }
  }

  @inlinable
  internal func evaluate(
    expansionType: URIValueExpansionType,
    templateVariable: URITemplateVariable
  ) throws -> String {
    if templateVariable.expansionModifier.isPrefixType,
      storage.isListValue || storage.isAssociationValue
    {
      throw ExpansionError.prefixModifierNotApplicable(
        variableName: templateVariable.variableName.rawValue,
        expansionType: expansionType,
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
