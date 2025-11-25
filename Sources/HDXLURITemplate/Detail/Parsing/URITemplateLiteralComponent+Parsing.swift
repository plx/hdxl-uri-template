import Foundation

extension URITemplateLiteralComponent {

  /// Errors that can occur when parsing a literal component.
  @usableFromInline
  internal enum ParseError : Error {
    /// The input string was unexpectedly empty.
    case unexpectedlyEmpty
    /// The content contains invalid characters.
    case invalidContent(String)
  }

  /// Parses a literal component from a string.
  ///
  /// The string must contain only valid URI literal characters as defined by RFC 6570.
  ///
  /// - Parameter string: The literal string to parse.
  ///
  /// - Throws: `ParseError.unexpectedlyEmpty` if the string is empty, or
  ///   `ParseError.invalidContent` if the string contains invalid characters.
  @inlinable
  internal init(parsing string: String) throws {
    guard !string.isEmpty else {
      throw ParseError.unexpectedlyEmpty
    }
    guard Self.validationRegularExpression.matchesEntirety(of: string) else {
      throw ParseError.invalidContent(string)
    }
    self.init(
      rawValue: string
    )
  }
  
}
