import Foundation

extension String {
  
  /// Convenience to get at the code-point count.
  @inlinable
  internal var codePointCount: Int {
    unicodeScalars.count
  }
  
  /// Returns `self` after being truncated to `codePointCount` code points.
  ///
  /// This truncation isn't useful for arbitrary strings, but it's fine for what
  /// we use it for within the URI template implementation.
  @inlinable
  internal func constrained(toCodePointCount codePointCount: Int) -> String {
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
  internal mutating func constrain(toCodePointCount codePointCount: Int) {
    self = constrained(toCodePointCount: codePointCount)
  }
  
}
