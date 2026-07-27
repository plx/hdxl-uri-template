import Foundation

extension String {
  
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
  func rangeOfLastComponent(forSeparator separator: String) -> Range<String.Index>? {
    guard
      !isEmpty,
      !separator.isEmpty,
      let rangeOfLastSeparator = range(of: separator, options: .backwards),
      rangeOfLastSeparator.upperBound < endIndex
    else {
        return nil
    }
    return rangeOfLastSeparator.upperBound..<endIndex
  }
  
  func lastComponent(forSeparator separator: String) -> String? {
    guard let range = rangeOfLastComponent(forSeparator: separator) else {
      return nil
    }
    return String(self[range])
  }
  
  func removingLastComponent(forSeparator separator: String) -> String {
    mutated {
      $0.removeLastComponent(forSeparator: separator)
    }
  }
  
  mutating func removeLastComponent(forSeparator separator: String) {
    if let rangeToRemove = rangeOfLastComponent(forSeparator: separator) {
      removeSubrange(rangeToRemove)
    }
  }
  
}
