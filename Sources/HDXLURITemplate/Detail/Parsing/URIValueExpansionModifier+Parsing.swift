import Foundation

extension URIValueExpansionModifier {

  /// Errors that can occur when parsing an expansion modifier.
  @usableFromInline
  internal enum ParseError : Error {
    /// The prefix length specification was invalid.
    case invalidPrefixSpecification(String)
  }

  /// Parses an expansion modifier from the end of a string, modifying the string in place.
  ///
  /// Recognizes:
  /// - `*` suffix for explode modifier
  /// - `:N` suffix for prefix modifier (where N is 1-9999)
  /// - No suffix for unmodified
  ///
  /// - Parameter string: The string to parse; will have the modifier suffix removed.
  ///
  /// - Throws: `ParseError.invalidPrefixSpecification` if a prefix modifier is malformed.
  @inlinable
  internal init(parsing string: inout String) throws {
    if string.hasSuffix("*") {
      self = .explode
      string.conditionallyRemove(suffix: "*")
    } else if let colonIndex = string.lastIndex(of: ":") {
      guard (2...5).contains(
        string.distance(
          from: colonIndex,
          to: string.endIndex
        )
      ),
      let prefixLength = Int(
        string[
          string.index(after: colonIndex)
            ..<
          string.endIndex
        ]
      ),
      Self.rangeOfValidPrefixCodePointCounts.contains(prefixLength) else {
        throw ParseError.invalidPrefixSpecification(
          String(
            string[
              colonIndex
                ..<
                string.endIndex
            ]
          )
        )
      }
      self = .prefix(prefixLength)
      string.removeSubrange(
        colonIndex
          ..<
        string.endIndex
      )
    } else {
      self = .unmodified
      // no need to update the string
    }
  }
  
}
