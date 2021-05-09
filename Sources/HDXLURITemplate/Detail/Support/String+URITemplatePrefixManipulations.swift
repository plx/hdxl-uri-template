//
//  String+URITemplatePrefixManipulations.swift
//

import Foundation
import HDXLCommonUtilities

internal extension String {
  
  /// Finds the range of `prefix` *iff* it actually is a prefix.
  ///
  /// - note: For `""` prefixes this returns `nil` (rather than, say, a `0..<0`-equivalent).
  ///
  @inlinable
  func range(forPrefix prefix: String) -> Range<String.Index>? {
    guard
      !self.isEmpty,
      !prefix.isEmpty else {
      return nil
    }
    return self.range(
      of: prefix,
      options: [.anchored]
    )
  }

  /// Returns the result of removing `prefix` iff `self` actually has `prefix` as a prefix.
  @inlinable
  func conditionallyRemoving(prefix: String) -> String {
    return self.mutated() {
      $0.conditionallyRemove(prefix: prefix)
    }
  }

  /// In-place removes `prefix` iff it's actually present as a prefix on `self`.
  @inlinable
  mutating func conditionallyRemove(prefix: String) {
    if let prefixRange = self.range(forPrefix: prefix) {
      self.removeSubrange(prefixRange)
    }
  }

}
