import Foundation

extension String {
  
  /// Finds the range of `suffix` *iff* it actually is a suffix.
  ///
  /// - note: For `""`, returns `nil` (rather than some length-zreo range).
  ///
  internal func range(forSuffix suffix: String) -> Range<String.Index>? {
    guard
      !isEmpty,
      !suffix.isEmpty
    else {
      return nil
    }
    return range(
      of: suffix,
      options: [.anchored, .backwards]
    )
  }
  
  /// Returns the result of removing `suffix` iff `self` actually has `suffix` as a suffix.
  internal func conditionallyRemoving(suffix: String) -> String {
    mutated {
      $0.conditionallyRemove(suffix: suffix)
    }
  }
  
  /// In-place removes `suffix` iff it's actually present as a suffix on `self`.
  internal mutating func conditionallyRemove(suffix: String) {
    if let suffixRange = range(forSuffix: suffix) {
      removeSubrange(suffixRange)
    }
  }
  
}
