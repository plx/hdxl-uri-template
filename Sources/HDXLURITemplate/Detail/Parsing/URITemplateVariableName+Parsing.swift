import Foundation

extension URITemplateVariableName {

  /// Errors that can occur when parsing a variable name.
  @usableFromInline
  internal enum ParseError : Error {
    /// The variable name was empty.
    case invalidEmptyName
    /// The variable name contains invalid characters.
    case invalidNameContents(String)
  }

  /// Parses a variable name from a string.
  ///
  /// Variable names must conform to RFC 6570 naming rules.
  ///
  /// - Parameter string: The variable name string to parse.
  ///
  /// - Throws: `ParseError.invalidEmptyName` if the string is empty, or
  ///   `ParseError.invalidNameContents` if the name contains invalid characters.
  @inlinable
  internal init(parsing string: String) throws {
    guard !string.isEmpty else {
      throw ParseError.invalidEmptyName
    }
    guard URITemplateVariableName
      .validationRegularExpression
      .matchesEntirety(of: string)
    else {
      throw ParseError.invalidNameContents(string)
    }
    self.init(rawValue: string)
  }
  
}
