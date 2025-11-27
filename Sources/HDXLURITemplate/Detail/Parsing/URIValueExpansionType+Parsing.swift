import Foundation

extension URIValueExpansionType {

  /// Errors that can occur when parsing an expansion type.
  @usableFromInline
  internal enum ParseError : Error {
    /// The input string was unexpectedly empty.
    case invalidEmptyString
  }

  /// Parses an expansion type from the beginning of a string, modifying the string in place.
  ///
  /// Recognizes RFC 6570 expansion operators:
  /// - `+` for reserved expansion
  /// - `#` for fragment expansion
  /// - `.` for label expansion
  /// - `/` for path segment expansion
  /// - `;` for path parameter expansion
  /// - `?` for query expansion
  /// - `&` for query continuation expansion
  /// - No prefix for simple expansion
  ///
  /// - Parameter string: The string to parse; will have the operator prefix removed.
  ///
  /// - Throws: `ParseError.invalidEmptyString` if the string is empty.
  @inlinable
  internal init(parsing string: inout String) throws {
    guard !string.isEmpty else {
      throw ParseError.invalidEmptyString
    }
    if string.hasPrefix(.reservedFormatString) {
      self = .reserved
      string.conditionallyRemove(
        prefix: .reservedFormatString
      )
    } else if string.hasPrefix(.fragmentFormatString) {
      self = .fragment
      string.conditionallyRemove(
        prefix: .fragmentFormatString
      )
    } else if string.hasPrefix(.labelFormatString) {
      self = .label
      string.conditionallyRemove(
        prefix: .labelFormatString
      )
    } else if string.hasPrefix(.pathSegmentFormatString) {
      self = .pathSegment
      string.conditionallyRemove(
        prefix: .pathSegmentFormatString
      )
    } else if string.hasPrefix(.pathParameterFormatString) {
      self = .pathParameter
      string.conditionallyRemove(
        prefix: .pathParameterFormatString
      )
    } else if string.hasPrefix(.queryFormatString) {
      self = .query
      string.conditionallyRemove(
        prefix: .queryFormatString
      )
    } else if string.hasPrefix(.queryContinuationFormatString) {
      self = .queryContinuation
      string.conditionallyRemove(
        prefix: .queryContinuationFormatString
      )
    } else {
      self = .simple
      // no string modification necessary
    }
  }
  
}
