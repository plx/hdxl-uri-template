//
//  String+URITemplateLastComponentManipulations.swift
//

import Foundation
import HDXLCommonUtilities

internal extension String {
  
  /// This method returns the *range* of the last component vis-a-vis `separator`.
  /// In other words, if you call `"abc,def,ghi".rangeOfLastComponent(forSeparator: ",")`,
  /// then you'll get the range of `ghi` (which'd be equivalent to `9..<12`, here,
  /// if `String.Index` were an `Int`).
  ///
  /// This returns `nil` whenever there's not really a last component:
  ///
  /// 1. `separator` is an empty string
  /// 2. `self` is an empty string
  /// 3. `self` ends with `separator` (e.g. for `"abc,"`, you'd get `nil` for the last `","`-separated component).
  ///
  /// Note that (1) and (2) are intuitive, but (3) is a design decision to simplify
  /// some of the downstream code.
  ///
  @inlinable
  func rangeOfLastComponent(forSeparator separator: String) -> Range<String.Index>? {
    guard
      !self.isEmpty,
      !separator.isEmpty,
      let rangeOfLastSeparator = self.range(of: separator, options: .backwards),
      rangeOfLastSeparator.upperBound < self.endIndex  else {
        return nil
    }
    return rangeOfLastSeparator.upperBound..<self.endIndex
  }
  
  @inlinable
  func lastComponent(forSeparator separator: String) -> String? {
    guard let range = self.rangeOfLastComponent(forSeparator: separator) else {
      return nil
    }
    return String(self[range])
  }
  
  @inlinable
  func removingLastComponent(forSeparator separator: String) -> String {
    return self.mutated() {
      $0.removeLastComponent(forSeparator: separator)
    }
  }
  
  @inlinable
  mutating func removeLastComponent(forSeparator separator: String) {
    if let rangeToRemove = self.rangeOfLastComponent(forSeparator: separator) {
      self.removeSubrange(rangeToRemove)
    }
  }
  
}
