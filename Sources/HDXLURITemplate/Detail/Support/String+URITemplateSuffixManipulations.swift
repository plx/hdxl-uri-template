//
//  String+URITemplateSuffixManipulations.swift
//

import Foundation
import HDXLCommonUtilities

internal extension String {
  
  /// Finds the range of `suffix` *iff* it actually is a suffix.
  ///
  /// - note: For `""`, returns `nil` (rather than some length-zreo range).
  ///
  @inlinable
  func range(forSuffix suffix: String) -> Range<String.Index>? {
    guard
      !self.isEmpty,
      !suffix.isEmpty else {
        return nil
    }
    return self.range(
      of: suffix,
      options: [.anchored, .backwards]
    )
  }
  
  /// Returns the result of removing `suffix` iff `self` actually has `suffix` as a suffix.
  @inlinable
  func conditionallyRemoving(suffix: String) -> String {
    return self.mutated() {
      $0.conditionallyRemove(suffix: suffix)
    }
  }
  
  /// In-place removes `suffix` iff it's actually present as a suffix on `self`.
  @inlinable
  mutating func conditionallyRemove(suffix: String) {
    if let suffixRange = self.range(forSuffix: suffix) {
      self.removeSubrange(suffixRange)
    }
  }
  
}
