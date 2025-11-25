import Foundation

// MARK: URITemplate.ParseError

extension URITemplate {

  /// Error thrown when parsing a URI template string fails.
  ///
  /// Contains the original template string and the underlying parsing error.
  public struct ParseError : Error, LocalizedError {

    /// The template string that failed to parse.
    public let template: String
    /// The underlying error that caused the parsing failure.
    public let underlyingError: Error

    @inlinable
    internal init(
      template: String,
      underlyingError: Error
    ) {
      self.template = template
      self.underlyingError = underlyingError
    }

    public var localizedDescription: String {
      """
      Couldn't parse template-string "\(template)" due to underlying-error: \(underlyingError.bestAvailableExplanation)
      """
    }
    
  }

}
