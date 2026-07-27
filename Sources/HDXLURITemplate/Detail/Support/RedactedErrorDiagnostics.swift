import Foundation

/// Supplies bounded, payload-free default text for internal errors that retain
/// source fragments as structured recovery context.
@usableFromInline
internal protocol RedactedDiagnosticError:
  Error,
  LocalizedError,
  CustomStringConvertible,
  CustomDebugStringConvertible
{
  var redactedDiagnosticDescription: String { get }
}

extension RedactedDiagnosticError {
  @usableFromInline
  internal var errorDescription: String? {
    redactedDiagnosticDescription
  }

  @usableFromInline
  internal var description: String {
    redactedDiagnosticDescription
  }

  @usableFromInline
  internal var debugDescription: String {
    redactedDiagnosticDescription
  }
}

extension URITemplateExpressionComponent.ParseError:
  RedactedDiagnosticError
{
  @usableFromInline
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
  @usableFromInline
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
  @usableFromInline
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
  @usableFromInline
  internal var redactedDiagnosticDescription: String {
    "The URI template prefix modifier is invalid."
  }
}

extension URIValueExpansionType.ParseError: RedactedDiagnosticError {
  @usableFromInline
  internal var redactedDiagnosticDescription: String {
    "The URI template expansion is empty."
  }
}

extension URITemplateVariable.ParseError: RedactedDiagnosticError {
  @usableFromInline
  internal var redactedDiagnosticDescription: String {
    "The URI template variable specification is empty."
  }
}

extension URIVariableTextValue.ExpansionError: RedactedDiagnosticError {
  @usableFromInline
  internal var redactedDiagnosticDescription: String {
    switch self {
    case .unableToEscapeVariableValue:
      "Unable to escape a variable value during URI template expansion."
    case .unableToEscapeVariableName:
      "Unable to escape variable-name during URI template expansion."
    case .unableToEscapeTextValue:
      "Unable to escape text during URI template expansion."
    }
  }
}

extension URIVariableListValue.ExpansionError: RedactedDiagnosticError {
  @usableFromInline
  internal var redactedDiagnosticDescription: String {
    "Unable to expand a list value safely."
  }
}

extension URIVariableAssociationValue.ExpansionError:
  RedactedDiagnosticError
{
  @usableFromInline
  internal var redactedDiagnosticDescription: String {
    "Unable to expand an association value safely."
  }
}
