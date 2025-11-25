import Foundation

extension URITemplateVariable {

  /// Errors that can occur when parsing a variable specification.
  @usableFromInline
  internal enum ParseError : Error {
    /// The input string was unexpectedly empty.
    case invalidEmptyString
  }

  /// Parses a variable specification from a string.
  ///
  /// The string should contain a variable name optionally followed by a modifier
  /// (e.g., `:3` for prefix or `*` for explode).
  ///
  /// - Parameter string: The variable specification string to parse.
  ///
  /// - Throws: `ParseError.invalidEmptyString` if the string is empty.
  @inlinable
  internal init(parsing string: String) throws {
    guard !string.isEmpty else {
      throw ParseError.invalidEmptyString
    }
    var variableNameString: String = string
    let expansionModifier = try URIValueExpansionModifier(
      parsing: &variableNameString
    )
    let variableName = try URITemplateVariableName(
      parsing: variableNameString
    )
    self.init(
      variableName: variableName,
      expansionModifier: expansionModifier
    )
  }
  
}
