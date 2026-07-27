import Foundation

/// Supplies bounded, payload-free default text for internal errors that retain
/// source fragments as structured recovery context.
internal protocol RedactedDiagnosticError:
  Error,
  LocalizedError,
  CustomStringConvertible,
  CustomDebugStringConvertible
{
  var redactedDiagnosticDescription: String { get }
}

extension RedactedDiagnosticError {
  internal var errorDescription: String? {
    redactedDiagnosticDescription
  }

  internal var description: String {
    redactedDiagnosticDescription
  }

  internal var debugDescription: String {
    redactedDiagnosticDescription
  }
}

extension URITemplateExpressionComponent.ParseError:
  RedactedDiagnosticError
{
  internal var redactedDiagnosticDescription: String {
    switch self {
    case .invalidEmptyString:
      "The URI template expression is empty."
    case .noVariablesFound:
      "The URI template expression contains no variables."
    }
  }
}

extension URITemplateLiteralComponent.ParseError: RedactedDiagnosticError {
  internal var redactedDiagnosticDescription: String {
    switch self {
    case .unexpectedlyEmpty:
      "The URI template literal is empty."
    case .invalidContent:
      "The URI template literal contains invalid content."
    }
  }
}

extension URITemplateVariableName.ParseError: RedactedDiagnosticError {
  internal var redactedDiagnosticDescription: String {
    switch self {
    case .invalidEmptyName:
      "The URI template variable name is empty."
    case .invalidNameContents:
      "The URI template variable name contains invalid content."
    }
  }
}

extension URIValueExpansionModifier.ParseError: RedactedDiagnosticError {
  internal var redactedDiagnosticDescription: String {
    "The URI template prefix modifier is invalid."
  }
}

extension URIValueExpansionType.ParseError: RedactedDiagnosticError {
  internal var redactedDiagnosticDescription: String {
    "The URI template expansion is empty."
  }
}

extension URITemplateVariable.ParseError: RedactedDiagnosticError {
  internal var redactedDiagnosticDescription: String {
    "The URI template variable specification is empty."
  }
}
