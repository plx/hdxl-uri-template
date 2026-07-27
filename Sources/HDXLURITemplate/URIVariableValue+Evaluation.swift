import Foundation

extension URIVariableValue {

  internal enum ExpansionError:
    Error,
    LocalizedError,
    CustomStringConvertible,
    CustomDebugStringConvertible
  {
    case prefixModifierNotApplicable(
      variableName: String,
      expansionType: URIValueExpansionType,
      prefixModifierCodePointCount: Int,
      valueType: URIVariableValueType
    )

    private var diagnosticDescription: String {
      switch self {
      case .prefixModifierNotApplicable(
        variableName: _,
        let expansionType,
        let prefixModifierCodePointCount,
        let valueType
      ):
        """
        Prefix modifier `:\(prefixModifierCodePointCount)` is not \
        applicable to a \(valueType) value for \(expansionType) expansion.
        """
      }
    }

    internal var errorDescription: String? {
      diagnosticDescription
    }

    internal var description: String {
      diagnosticDescription
    }

    internal var debugDescription: String {
      description
    }
  }

  internal func evaluate(
    expansionType: URIValueExpansionType,
    templateVariable: URITemplateVariable
  ) throws(ExpansionError) -> String {
    if case .prefix(let prefixModifierCodePointCount) =
      templateVariable.expansionModifier,
      storage.isListValue || storage.isAssociationValue
    {
      throw ExpansionError.prefixModifierNotApplicable(
        variableName: templateVariable.variableName.rawValue,
        expansionType: expansionType,
        prefixModifierCodePointCount: prefixModifierCodePointCount,
        valueType: storage.valueType
      )
    }

    return switch storage {
    case .undefined:
      ""
    case .text(let textValue):
      textValue.expansion(
        expansionType: expansionType,
        templateVariable: templateVariable
      )
    case .list(let listValue):
      listValue.expansion(
        expansionType: expansionType,
        templateVariable: templateVariable
      )
    case .association(let association):
      association.expansion(
        expansionType: expansionType,
        templateVariable: templateVariable
      )
    }
  }

}
