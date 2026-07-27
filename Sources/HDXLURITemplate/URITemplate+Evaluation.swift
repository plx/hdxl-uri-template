import Foundation

extension URITemplate {

  /// A failure encountered while evaluating a parsed URI template.
  ///
  /// Default textual and Foundation diagnostics are bounded and omit the
  /// template, parameters, variable names, rendered output, and nested error
  /// details. The stored recovery context remains available through explicit
  /// properties and can contain sensitive application data.
  public struct EvaluationError:
    Error,
    LocalizedError,
    CustomStringConvertible,
    CustomDebugStringConvertible
  {
    /// A payload-free evaluation-failure category that is safe to log.
    public enum Kind:
      Sendable,
      Equatable,
      CustomStringConvertible,
      CustomDebugStringConvertible
    {
      case prefixModifierNotApplicable
      case invalidURL
      case other

      public var description: String {
        switch self {
        case .prefixModifierNotApplicable:
          "prefixModifierNotApplicable"
        case .invalidURL:
          "invalidURL"
        case .other:
          "other"
        }
      }

      public var debugDescription: String {
        "URITemplate.EvaluationError.Kind.\(description)"
      }
    }

    internal struct DiagnosticContext: Sendable {
      internal let kind: Kind

      internal let failingVariableName: String?

      internal let expressionOperatorToken: String?

      internal let expressionTypeName: String?

      internal let prefixModifierCodePointCount: Int?

      internal let failingValueType: URIVariableValueType?

      internal static let other = DiagnosticContext(kind: .other)

      internal static let invalidURL = DiagnosticContext(kind: .invalidURL)

      internal init(
        kind: Kind,
        failingVariableName: String? = nil,
        expressionOperatorToken: String? = nil,
        expressionTypeName: String? = nil,
        prefixModifierCodePointCount: Int? = nil,
        failingValueType: URIVariableValueType? = nil
      ) {
        self.kind = kind
        self.failingVariableName = failingVariableName
        self.expressionOperatorToken = expressionOperatorToken
        self.expressionTypeName = expressionTypeName
        self.prefixModifierCodePointCount = prefixModifierCodePointCount
        self.failingValueType = failingValueType
      }
    }

    /// The template being evaluated.
    ///
    /// This explicit recovery context can contain sensitive source text. Do
    /// not log or reflect it without applying an application-specific policy.
    public let template: URITemplate

    /// The parameters supplied to evaluation.
    ///
    /// Parameter names and text, list, and association values can all be
    /// sensitive. Do not log or reflect this explicit recovery context without
    /// applying an application-specific policy.
    public let parameters: [String: URIVariableValue]

    /// The original failure retained for structured inspection.
    ///
    /// Its default diagnostics are redacted for failures produced by this
    /// package, but callers should not assume arbitrary nested errors are safe
    /// to log.
    public let underlyingError: Error?

    internal let diagnosticContext: DiagnosticContext

    internal init(
      template: URITemplate,
      parameters: [String: URIVariableValue],
      underlyingError: Error? = nil,
      diagnosticContext: DiagnosticContext = .other
    ) {
      self.template = template
      self.parameters = parameters
      self.underlyingError = underlyingError
      self.diagnosticContext = diagnosticContext
    }

    /// The payload-free category for this failure.
    public var kind: Kind {
      diagnosticContext.kind
    }

    /// The variable involved in a known expansion failure, when available.
    ///
    /// Variable names are application-controlled and may themselves be
    /// sensitive. This property is deliberate recovery context and is never
    /// included in this error's default diagnostics.
    public var failingVariableName: String? {
      diagnosticContext.failingVariableName
    }

    /// The exact URI-template expression-operator token, when available.
    ///
    /// The empty string represents simple expansion; `nil` means no expression
    /// context applies to this failure.
    public var expressionOperatorToken: String? {
      diagnosticContext.expressionOperatorToken
    }

    /// The RFC 6570 prefix modifier's requested Unicode code-point count.
    public var prefixModifierCodePointCount: Int? {
      diagnosticContext.prefixModifierCodePointCount
    }

    /// The variable-value flavor involved in a known expansion failure.
    public var failingValueType: URIVariableValueType? {
      diagnosticContext.failingValueType
    }

    public var errorDescription: String? {
      "The URI template could not be evaluated."
    }

    /// A bounded, payload-free explanation of the failure category.
    public var failureReason: String? {
      switch diagnosticContext.kind {
      case .prefixModifierNotApplicable:
        guard
          let prefixModifierCodePointCount =
            diagnosticContext.prefixModifierCodePointCount,
          let expressionTypeName = diagnosticContext.expressionTypeName,
          let failingValueType = diagnosticContext.failingValueType
        else {
          return "A prefix modifier is not applicable to a composite value."
        }
        return """
          Prefix modifier `:\(prefixModifierCodePointCount)` is not applicable \
          to a \(failingValueType) value for \(expressionTypeName) expansion.
          """
      case .invalidURL:
        return "The rendered URI template is not a valid URL."
      case .other:
        return "No more specific evaluation failure category is available."
      }
    }

    public var description: String {
      let headline =
        errorDescription ?? "The URI template could not be evaluated."
      guard let failureReason else {
        return headline
      }
      return "\(headline) \(failureReason)"
    }

    public var debugDescription: String {
      description
    }

    internal static func makeExpansionDiagnosticContext(
      for underlyingError: Error?
    ) -> DiagnosticContext {
      if let expansionError =
        underlyingError as? URIVariableValue.ExpansionError,
        case .prefixModifierNotApplicable(
          let variableName,
          let expansionType,
          let expansionModifier,
          let valueType
        ) = expansionError
      {
        let prefixModifierCodePointCount: Int? =
          switch expansionModifier {
          case .prefix(let prefixLength):
            prefixLength
          case .unmodified, .explode:
            nil
          }
        return DiagnosticContext(
          kind: .prefixModifierNotApplicable,
          failingVariableName: variableName,
          expressionOperatorToken: expansionType.formatString,
          expressionTypeName: expansionType.description,
          prefixModifierCodePointCount: prefixModifierCodePointCount,
          failingValueType: valueType
        )
      }
      return .other
    }
  }

  public func evaluateAsString(
    parameters: [String: URIVariableValue]
  ) throws -> String {
    // This `do`/`catch` is the public failure boundary for evaluation: any
    // error surfaced while expanding a component is re-thrown as an
    // `EvaluationError` carrying the template and parameters, so callers get
    // a uniform error type with diagnostic context (see `SpecificationTests`'
    // `.evaluationFailure` expectation). Composite values with prefix
    // modifiers are one controlled downstream failure surfaced here.
    // That failure is rejected after both the modifier and runtime value
    // flavor are known.
    do {
      var result: String = ""
      for component in storage.components {
        switch component {
        case .literal(let literal):
          result.append(contentsOf: literal.expansionRepresentation)
        case .expression(let expression):
          result.append(contentsOf: try expression.evaluate(parameters: parameters))
        }
      }

      return result
    } catch let error {
      throw EvaluationError(
        template: self,
        parameters: parameters,
        underlyingError: error,
        diagnosticContext:
          EvaluationError.makeExpansionDiagnosticContext(for: error)
      )
    }
  }

  public func evaluate(parameters: [String: URIVariableValue]) throws -> URL {
    let stringResult = try evaluateAsString(parameters: parameters)
    guard let url = URL(string: stringResult) else {
      // A successfully-rendered template can still fail to produce a valid
      // `URL` (e.g. an empty expansion, or literal text `URL` rejects). Wrap
      // this as an `EvaluationError` — like expansion failures — so the
      // public `evaluate(parameters:)` surfaces one consistent error type.
      throw EvaluationError(
        template: self,
        parameters: parameters,
        underlyingError: URLError(
          .badURL,
          userInfo: [
            NSLocalizedDescriptionKey:
              "The rendered URI template is not a valid URL."
          ]
        ),
        diagnosticContext: .invalidURL
      )
    }
    return url
  }

}
