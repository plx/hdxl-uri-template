import Foundation

// RFC-derived Code Components in this file are attributed in
// THIRD_PARTY_NOTICES.md.

extension URITemplateVariableName {

  internal enum TextVariableNameEscapeResult {
    case unnecessary
    case escaped(String)
  }

  internal func escapedVariableName(
    forExpansionType expansionType: URIValueExpansionType,
    forced: Bool = false
  ) -> TextVariableNameEscapeResult {
#if HEAVY_DEBUG
    pedanticAssert(isValid)
#endif
    guard forced || shouldEscapeName(forExpansionType: expansionType) else {
      return .unnecessary
    }
    return .escaped(escapedAsLiteral)
  }

  internal var escapedAsLiteral: String {
    rawValue.escaped(forValueExpansionType: .reserved)
  }

  internal func shouldEscapeName(
    forExpansionType expansionType: URIValueExpansionType
  ) -> Bool {
    switch expansionType {
    case .simple:
      false
    case .reserved:
      false
    case .fragment:
      false
    case .label:
      false
    case .pathSegment:
      false
    case .pathParameter:
      true
    case .query:
      true
    case .queryContinuation:
      true
    }
  }

}
