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
      value.isDefined
    else {
      return nil
    }

    // Empty text values still expand (e.g. "?empty="). Empty composites are
    // normally omitted, but a prefix modifier must reach the semantic value
    // boundary so it can fail instead of being mistaken for undefined.
    guard
      value.isTextValue
        || !value.isEmpty
        || expansionModifier.isPrefixType
    else {
      return nil
    }

    return try value.evaluate(
      expansionType: expansionType,
      templateVariable: self
    )
  }

}
