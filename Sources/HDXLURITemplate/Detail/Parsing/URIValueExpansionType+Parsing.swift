//
//  URIValueExpansionType+Parsing.swift
//

import Foundation
import HDXLCommonUtilities

internal extension URIValueExpansionType {
  
  @usableFromInline
  enum ParseError : Error {
    case invalidEmptyString
  }
  
  @inlinable
  init(parsing string: inout String) throws {
    guard !string.isEmpty else {
      throw ParseError.invalidEmptyString
    }
    if string.hasPrefix(Self.reservedFormatString) {
      self = .reserved
      string.conditionallyRemove(
        prefix: Self.reservedFormatString
      )
    } else if string.hasPrefix(Self.fragmentFormatString) {
      self = .fragment
      string.conditionallyRemove(
        prefix: Self.fragmentFormatString
      )
    } else if string.hasPrefix(Self.labelFormatString) {
      self = .label
      string.conditionallyRemove(
        prefix: Self.labelFormatString
      )
    } else if string.hasPrefix(Self.pathSegmentFormatString) {
      self = .pathSegment
      string.conditionallyRemove(
        prefix: Self.pathSegmentFormatString
      )
    } else if string.hasPrefix(Self.pathParameterFormatString) {
      self = .pathParameter
      string.conditionallyRemove(
        prefix: Self.pathParameterFormatString
      )
    } else if string.hasPrefix(Self.queryFormatString) {
      self = .query
      string.conditionallyRemove(
        prefix: Self.queryFormatString
      )
    } else if string.hasPrefix(Self.queryContinuationFormatString) {
      self = .queryContinuation
      string.conditionallyRemove(
        prefix: Self.queryContinuationFormatString
      )
    } else {
      self = .simple
      // no string modification necessary
    }
  }
  
}
