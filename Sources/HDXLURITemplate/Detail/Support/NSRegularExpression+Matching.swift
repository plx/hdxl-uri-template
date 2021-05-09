//
//  NSRegularExpression+Matching.swift
//

import Foundation
import HDXLCommonUtilities

internal extension NSRegularExpression {
  
  @inlinable
  func matchesEntirety(of string: String) -> Bool {
    let completeRange = NSRange(
      string.startIndex..<string.endIndex,
      in: string
    )
    return completeRange == self.rangeOfFirstMatch(
      in: string,
      options: .anchored,
      range: completeRange
    )
  }
  
}
