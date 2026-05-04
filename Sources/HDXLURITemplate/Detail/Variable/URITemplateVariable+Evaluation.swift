import Foundation

extension URITemplateVariable {

  @inlinable
  internal func evaluate(
    parameters: [String: URIVariableValue],
    expansionType: URIValueExpansionType
  ) throws -> String {
    guard let expansion = try evaluateIfDefined(
      parameters: parameters,
      expansionType: expansionType
    ) else {
      return ""
    }

    return expansion
  }

  @inlinable
  internal func evaluateIfDefined(
    parameters: [String: URIVariableValue],
    expansionType: URIValueExpansionType
  ) throws -> String? {
    guard
      let value = parameters[variableName.rawValue],
      value.isDefined,
      value.isTextValue || !value.isEmpty
    else {
      return nil
    }

    return try value.evaluate(
      expansionType: expansionType,
      templateVariable: self
    )
  }

}
