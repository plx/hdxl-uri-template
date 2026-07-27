import Foundation

extension String {

  /// Finds the range of `prefix` *iff* it actually is a prefix.
  ///
  /// - note: For `""` prefixes this returns `nil` (rather than, say, a `0..<0`-equivalent).
  ///
  internal func range(forPrefix prefix: String) -> Range<String.Index>? {
    guard
      !isEmpty,
      !prefix.isEmpty
    else {
      return nil
    }
    return range(
      of: prefix,
      options: [.anchored]
    )
  }

  /// Returns the result of removing `prefix` iff `self` actually has `prefix` as a prefix.
  internal func conditionallyRemoving(prefix: String) -> String {
    mutated {
      $0.conditionallyRemove(prefix: prefix)
    }
  }

  /// In-place removes `prefix` iff it's actually present as a prefix on `self`.
  mutating func conditionallyRemove(prefix: String) {
    if let prefixRange = range(forPrefix: prefix) {
      removeSubrange(prefixRange)
    }
  }

}
