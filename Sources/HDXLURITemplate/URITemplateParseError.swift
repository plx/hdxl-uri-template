import Foundation

// ------------------------------------------------------------------------ //
// MARK: URITemplate.ParseError - Definition
// ------------------------------------------------------------------------ //

extension URITemplate {

  /// A failure encountered while parsing URI-template source text.
  ///
  /// ``kind`` and ``sourceRange`` are the stable diagnostic contract. Default
  /// textual and Foundation diagnostics are bounded and omit source text. The
  /// stored ``template`` remains explicit recovery context and can contain
  /// sensitive application data.
  public struct ParseError:
    Error,
    Sendable,
    LocalizedError,
    CustomStringConvertible,
    CustomDebugStringConvertible
  {

    /// Stable semantic categories for URI-template parsing failures.
    public enum Kind:
      String,
      CaseIterable,
      Sendable,
      CustomStringConvertible,
      CustomDebugStringConvertible
    {
      /// An opening brace appears inside an expression.
      case unexpectedOpeningBrace

      /// A closing brace appears outside an expression.
      case unexpectedClosingBrace

      /// An expression ends without a closing brace.
      case unterminatedExpression

      /// An expression contains neither an operator nor a variable.
      case emptyExpression

      /// A comma-delimited variable position is empty.
      case emptyVariableSpecification

      /// An expression begins with an unsupported reserved operator.
      case invalidOperator

      /// Literal source contains a scalar forbidden by the grammar.
      case invalidLiteral

      /// A variable name does not match the grammar.
      case invalidVariableName

      /// A prefix or explode modifier does not match the grammar.
      case invalidModifier

      /// A percent sign is not followed by two hexadecimal digits.
      case malformedPercentEncoding

      /// The failure could not be classified more specifically.
      case other

      /// The stable raw string value of this category.
      public var description: String {
        rawValue
      }

      /// A payload-free, fully-qualified representation of this category.
      public var debugDescription: String {
        "URITemplate.ParseError.Kind.\(rawValue)"
      }

      @usableFromInline
      internal var failureReason: String {
        switch self {
        case .unexpectedOpeningBrace:
          "An opening brace appears inside an expression."
        case .unexpectedClosingBrace:
          "A closing brace appears outside an expression."
        case .unterminatedExpression:
          "An expression is missing its closing brace."
        case .emptyExpression:
          "An expression contains no operator or variable specification."
        case .emptyVariableSpecification:
          "An expression contains an empty variable specification."
        case .invalidOperator:
          "An expression begins with an unsupported operator."
        case .invalidLiteral:
          "A literal contains a character that URI-template syntax forbids."
        case .invalidVariableName:
          "A variable name does not match URI-template syntax."
        case .invalidModifier:
          "A variable modifier does not match URI-template syntax."
        case .malformedPercentEncoding:
          "A percent sign is not followed by exactly two hexadecimal digits."
        case .other:
          "The parser encountered an unclassified syntax failure."
        }
      }
    }

    /// The semantic category of this parsing failure.
    public let kind: Kind

    /// The offending range in ``template``, measured in UTF-8 bytes.
    ///
    /// The lower bound is inclusive and the upper bound is exclusive. Both are
    /// always between zero and `template.utf8.count`. A zero-length range marks
    /// an insertion point, such as the end of an unterminated expression.
    public let sourceRange: Range<Int>

    /// The source text that failed to parse.
    ///
    /// This explicit recovery context can contain sensitive literals or
    /// variable names. Do not log or reflect it without applying an
    /// application-specific policy.
    public let template: String

    @inlinable
    internal init(
      template: String,
      kind: Kind,
      sourceRange: Range<Int>
    ) {
      self.template = template
      self.kind = kind
      self.sourceRange = sourceRange
    }

    /// A bounded description that does not contain source text.
    public var errorDescription: String? {
      "The URI template could not be parsed."
    }

    /// A bounded, payload-free explanation of ``kind``.
    public var failureReason: String? {
      kind.failureReason
    }

    /// A bounded summary that does not contain source text.
    public var description: String {
      [
        errorDescription ?? "URI template parsing failed.",
        failureReason,
      ]
      .compactMap { $0 }
      .joined(separator: " ")
    }

    /// A bounded debug summary that does not contain source text.
    public var debugDescription: String {
      description
    }
  }

}
