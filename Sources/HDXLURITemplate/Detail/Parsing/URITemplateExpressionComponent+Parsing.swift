import Foundation

extension URITemplateExpressionComponent {

  /// Errors that can occur when parsing an expression component.
  @usableFromInline
  internal enum ParseError : Error {
    /// The input string was unexpectedly empty.
    case invalidEmptyString
    /// No variables were found in the expression string.
    case noVariablesFound(String)
  }

  /// Parses an expression component from a string.
  ///
  /// The string should contain an optional expansion operator prefix followed by
  /// a comma-separated list of variable specifications.
  ///
  /// - Parameter string: The expression string to parse (without surrounding braces).
  ///
  /// - Throws: `ParseError.invalidEmptyString` if the string is empty, or
  ///   `ParseError.noVariablesFound` if no variables are present.
  @inlinable
  internal init(parsing string: String) throws {
    guard !string.isEmpty else {
      throw ParseError.invalidEmptyString
    }
    var variableListString = string
    let expansionType = try URIValueExpansionType(
      parsing: &variableListString
    )
    let variables = try variableListString
      .split(separator: ",")
      .map { segment in
        let trimmed = segment.trimmingCharacters(in: .whitespaces)
        
        return try URITemplateVariable(parsing: String(trimmed))
      }
    guard !variables.isEmpty else {
      throw ParseError.noVariablesFound(string)
    }
    self.init(
      expansionType: expansionType,
      variables: variables
    )
  }
  
}
