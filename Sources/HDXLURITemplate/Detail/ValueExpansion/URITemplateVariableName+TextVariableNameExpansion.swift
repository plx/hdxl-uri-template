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
    // Per RFC 6570 Section 2.3:
    // Variable names can only contain ALPHA, DIGIT, "_", and pct-encoded triplets.
    // All these characters are safe in URIs. Percent-encoded triplets in variable
    // names are considered essential and must not be re-encoded (per RFC 6570 Section 2.3).
    // Therefore, variable names should be used as-is without additional encoding.
    return .escaped(rawValue)
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

