//
//  String+URITemplateLengthManipulations.swift
//

import Foundation

internal extension String {
  
  /// Convenience to get at the code-point count.
  @inlinable
  var codePointCount: Int {
    unicodeScalars.count
  }
  
  /// Returns `self` after being truncated to `codePointCount` code points.
  ///
  /// This truncation isn't useful for arbitrary strings, but it's fine for what
  /// we use it for within the URI template implementation.
  @inlinable
  func constrained(toCodePointCount codePointCount: Int) -> String {
    #if HEAVY_DEBUG
    pedanticAssert(codePointCount >= 0)
    #endif
    guard codePointCount >= 0 else {
      return ""
    }
    let scalars = unicodeScalars
    guard codePointCount < scalars.count else {
      return self
    }
    
    return String(
      scalars[
        scalars.startIndex
          ..<
        scalars.index(
          scalars.startIndex,
          offsetBy: codePointCount
        )
      ]
    )
  }
  
  /// In-place truncates `self` to be no longer than `codePointCount` code points.
  ///
  /// This truncation isn't useful for arbitrary strings, but it's fine for what
  /// we use it for within the URI template implementation.
  @inlinable
  mutating func constrain(toCodePointCount codePointCount: Int) {
#if HEAVY_DEBUG
    pedanticAssert(codePointCount >= 0)
#endif
    self = constrained(toCodePointCount: codePointCount)
  }
  
}
