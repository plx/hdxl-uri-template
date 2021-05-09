//
//  CharacterSet+URITemplateUtilities.swift
//

import Foundation
import HDXLCommonUtilities

internal extension CharacterSet {
  
  @inlinable
  init(unionOf characterSets: [CharacterSet]) {
    self.init()
    for characterSet in characterSets {
      self.formUnion(characterSet)
    }
  }
  
  @inlinable
  init(charactersIn range: ClosedRange<UnicodeScalar>) {
    guard
      let upperBoundSuccessor = UnicodeScalar(
        range.upperBound.value + 1
      ) else {
        preconditionFailure("Can't convert closed range \(String(reflecting: range)) to open range!")
    }
    self.init(
      charactersIn: range.lowerBound..<upperBoundSuccessor
    )
  }
  
  @inlinable
  init(unionOf ranges: [Range<UnicodeScalar>]) {
    self.init()
    for range in ranges {
      self.insert(charactersIn: range)
    }
  }
  
  @inlinable
  init(unionOf ranges: [ClosedRange<UnicodeScalar>]) {
    self.init()
    for range in ranges {
      self.insert(
        charactersIn: range
      )
    }
  }
  
}
