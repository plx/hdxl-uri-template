import Foundation

// ------------------------------------------------------------------------ //
// MARK: URITemplate.ParseError - Definition
// ------------------------------------------------------------------------ //

extension URITemplate {

  /// A failure encountered while parsing URI-template source text.
  ///
  /// Default textual and Foundation diagnostics are bounded and omit the
  /// source and nested error details. The stored recovery context remains
  /// available through explicit properties and can contain sensitive
  /// application data.
  public struct ParseError:
    Error,
    LocalizedError,
    CustomStringConvertible,
    CustomDebugStringConvertible
  {

    /// The source text that failed to parse.
    ///
    /// This explicit recovery context can contain sensitive literals or
    /// variable names. Do not log or reflect it without applying an
    /// application-specific policy.
    public let template: String

    /// The original parser failure retained for structured inspection.
    ///
    /// Its default diagnostics are redacted, but its concrete internal payload
    /// can retain source fragments for future structured error mapping.
    public let underlyingError: Error

    @inlinable
    internal init(template: String, underlyingError: Error) {
      self.template = template
      self.underlyingError = underlyingError
    }

    public var errorDescription: String? {
      "The URI template could not be parsed."
    }

    public var description: String {
      errorDescription ?? "URI template parsing failed."
    }

    public var debugDescription: String {
      description
    }
  }

}
