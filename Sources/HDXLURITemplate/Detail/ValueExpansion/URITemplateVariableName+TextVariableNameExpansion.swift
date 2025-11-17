import Foundation

extension URITemplateVariableName {
  
  @usableFromInline
  internal enum TextVariableNameEscapeResult {
    case unnecessary
    case escaped(String)
    case failure
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
    guard let escapedName = rawValue.escaped(forValueExpansionType: expansionType) else {
      return .failure
    }
    return .escaped(escapedName)
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

