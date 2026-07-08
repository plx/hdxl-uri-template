import Foundation

extension URITemplateVariableName {

  @usableFromInline
  internal enum TextVariableNameEscapeResult {
    case unnecessary
    case escaped(String)
  }

  @inlinable
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

  @inlinable
  internal var escapedAsLiteral: String {
    rawValue.escaped(forValueExpansionType: .reserved)
  }

  @inlinable
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
