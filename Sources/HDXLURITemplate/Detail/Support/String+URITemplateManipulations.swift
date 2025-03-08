import Foundation

extension String {
  
  /// Utility to return the result of a mutable operation on `String`.
  @inlinable
  internal func mutated(
    by mutation: (inout String) throws -> Void
  ) rethrows -> String {
    var clone = self
    try mutation(&clone)
    return clone
  }
    
}
