//
//  URITemplateVariableName+TextVariableNameExpansion.swift
//

import Foundation
import HDXLCommonUtilities

internal extension URITemplateVariableName {
  
  @usableFromInline
  enum TextVariableNameEscapeResult {
    case unnecessary
    case escaped(String)
    case failure
  }

  @inlinable
  func escapedVariableName(
    forExpansionType expansionType: URIValueExpansionType,
    forced: Bool = false) -> TextVariableNameEscapeResult {
    // /////////////////////////////////////////////////////////////////////////
    pedantic_assert(self.isValid)
    // /////////////////////////////////////////////////////////////////////////
    guard forced || self.shouldEscapeName(forExpansionType: expansionType) else {
      return .unnecessary
    }
    guard let escapedName = self.storage.escaped(forValueExpansionType: expansionType) else {
      return .failure
    }
    return .escaped(escapedName)
  }
  
  @inlinable
  func shouldEscapeName(
    forExpansionType expansionType: URIValueExpansionType) -> Bool {
    switch expansionType {
    case .simple:
      return false
    case .reserved:
      return false
    case .fragment:
      return false
    case .label:
      return false
    case .pathSegment:
      return false
    case .pathParameter:
      return true
    case .query:
      return true
    case .queryContinuation:
      return true
    }
  }
  
}

