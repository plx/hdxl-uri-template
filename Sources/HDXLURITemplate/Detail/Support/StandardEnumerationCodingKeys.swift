//
//  StandardEnumerationCodingKeys.swift
//

import Foundation
import HDXLCommonUtilities

@usableFromInline
internal enum StandardEnumerationCodingKeys : String, CodingKey, CaseIterable {
  
  case type = "type"
  case data = "data"
  
  @inlinable
  internal var intValue: Int? {
    get {
      switch self {
      case .type:
        return 0
      case .data:
        return 1
      }
    }
  }
  
  @inlinable
  internal init?(intValue: Int) {
    switch intValue {
    case 0:
      self = .type
    case 1:
      self = .data
    default:
      return nil
    }
  }
  
  @usableFromInline
  internal typealias AllCases = [StandardEnumerationCodingKeys]
  
  @usableFromInline
  internal static let allCases: AllCases = [ .type, .data ]
  
}
