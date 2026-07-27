import Foundation

@testable import HDXLURITemplate

struct ReferenceExampleCaseIdentity: Hashable, Sendable {
  let source: String
  let caption: String
  let template: String
  let expectation: ReferenceExampleExpectation

  init(example: CaptionedTestCase) {
    self.init(
      source: example.source,
      caption: example.caption,
      template: example.testCase.template,
      expectation: example.testCase.expectation
    )
  }

  init(
    source: String,
    caption: String,
    template: String,
    expectation: ReferenceExampleExpectation
  ) {
    self.source = source
    self.caption = caption
    self.template = template
    self.expectation = expectation
  }

  func matches(_ example: CaptionedTestCase) -> Bool {
    self == ReferenceExampleCaseIdentity(example: example)
  }
}

struct ReferenceExampleCaseContext: Hashable, Sendable {
  let source: String
  let caption: String
  let template: String
  let parameters: [String: URIVariableValue]
  let expectation: ReferenceExampleExpectation

  init(example: CaptionedTestCase) {
    self.init(
      source: example.source,
      caption: example.caption,
      template: example.testCase.template,
      parameters: example.parameters,
      expectation: example.testCase.expectation
    )
  }

  init(
    source: String,
    caption: String,
    template: String,
    parameters: [String: URIVariableValue],
    expectation: ReferenceExampleExpectation
  ) {
    self.source = source
    self.caption = caption
    self.template = template
    self.parameters = parameters
    self.expectation = expectation
  }

  var caseIdentity: ReferenceExampleCaseIdentity {
    ReferenceExampleCaseIdentity(
      source: source,
      caption: caption,
      template: template,
      expectation: expectation
    )
  }

  var diagnosticDescription: String {
    let renderedParameters = parameters.keys.sorted().map { key in
      let value =
        parameters[key]?.fixtureDiagnosticRepresentation ?? "<missing>"
      return "  \(String(reflecting: key)): \(value)"
    }
    .joined(separator: "\n")

    return """
    - suite: \(source)
    - group: \(caption)
    - template: \(String(reflecting: template))
    - variables:
    \(renderedParameters)
    - expectation: \(expectation.diagnosticDescription)
    """
  }
}

struct ReferenceExampleBehaviorDriver: Sendable {
  let parse: @Sendable (String) throws -> URITemplate
  let expand: @Sendable (
    URITemplate,
    [String: URIVariableValue]
  ) throws -> String

  static let publicAPI = ReferenceExampleBehaviorDriver(
    parse: { source in
      try URITemplate(parsing: source)
    },
    expand: { template, parameters in
      try template.evaluateAsString(parameters: parameters)
    }
  )
}

protocol ReferenceExampleDiagnosticError:
  Error,
  CustomStringConvertible,
  LocalizedError { }

extension ReferenceExampleDiagnosticError {
  var errorDescription: String? {
    description
  }
}

struct ReferenceExampleParsingFailure: ReferenceExampleDiagnosticError {
  let context: ReferenceExampleCaseContext
  let parseError: URITemplate.ParseError

  var description: String {
    """
    A positive reference example failed during parsing.
    \(context.diagnosticDescription)
    - parse error: \(String(reflecting: parseError))
    """
  }
}

struct ReferenceExampleEvaluationFailure: ReferenceExampleDiagnosticError {
  let context: ReferenceExampleCaseContext
  let evaluationError: URITemplate.EvaluationError

  var description: String {
    """
    A positive reference example failed during evaluation.
    \(context.diagnosticDescription)
    - evaluation error: \(String(reflecting: evaluationError))
    """
  }
}

struct ReferenceExampleExactExpansionMismatch:
  ReferenceExampleDiagnosticError {
  let context: ReferenceExampleCaseContext
  let expected: String
  let observed: String

  var description: String {
    """
    A reference expansion did not exactly match its expectation.
    \(context.diagnosticDescription)
    - expected expansion: \(String(reflecting: expected))
    - observed expansion: \(String(reflecting: observed))
    """
  }
}

struct ReferenceExampleAlternateMismatch:
  ReferenceExampleDiagnosticError {
  let context: ReferenceExampleCaseContext
  let acceptableExpansions: [String]
  let observed: String

  var description: String {
    """
    A reference expansion did not match any acceptable expansion.
    \(context.diagnosticDescription)
    - acceptable expansions: \(String(reflecting: acceptableExpansions))
    - observed expansion: \(String(reflecting: observed))
    """
  }
}

struct ReferenceExampleUnexpectedSuccess:
  ReferenceExampleDiagnosticError {
  let context: ReferenceExampleCaseContext
  let parsedTemplateRepresentation: String
  let observedExpansion: String

  var description: String {
    """
    A reference example with expectation `false` unexpectedly succeeded.
    \(context.diagnosticDescription)
    - parsed template: \(String(reflecting: parsedTemplateRepresentation))
    - observed expansion: \(String(reflecting: observedExpansion))
    """
  }
}

enum ReferenceExampleVerificationBoundary: String {
  case parsing
  case evaluation
}

struct ReferenceExampleBoundaryError:
  ReferenceExampleDiagnosticError {
  let context: ReferenceExampleCaseContext
  let boundary: ReferenceExampleVerificationBoundary
  let underlyingError: any Error

  var description: String {
    """
    A reference example produced an uncontrolled \(boundary.rawValue) error.
    \(context.diagnosticDescription)
    - underlying error: \(String(reflecting: underlyingError))
    """
  }
}

func verifyReferenceExampleBehavior(
  _ example: CaptionedTestCase,
  using driver: ReferenceExampleBehaviorDriver = .publicAPI
) throws {
  let context = ReferenceExampleCaseContext(example: example)

  switch context.expectation {
  case .evaluationFailure:
    try verifyExpectedReferenceExampleFailure(
      context,
      using: driver
    )

  case .exactMatch(let expected):
    let observed = try evaluatePositiveReferenceExample(
      context,
      using: driver
    )
    guard observed == expected else {
      throw ReferenceExampleExactExpansionMismatch(
        context: context,
        expected: expected,
        observed: observed
      )
    }

  case .multiplePossibleMatches(let acceptableExpansions):
    let observed = try evaluatePositiveReferenceExample(
      context,
      using: driver
    )
    guard acceptableExpansions.contains(observed) else {
      throw ReferenceExampleAlternateMismatch(
        context: context,
        acceptableExpansions: acceptableExpansions,
        observed: observed
      )
    }
  }
}

private func evaluatePositiveReferenceExample(
  _ context: ReferenceExampleCaseContext,
  using driver: ReferenceExampleBehaviorDriver
) throws -> String {
  let template: URITemplate
  do {
    template = try driver.parse(context.template)
  } catch let parseError as URITemplate.ParseError {
    throw ReferenceExampleParsingFailure(
      context: context,
      parseError: parseError
    )
  } catch {
    throw ReferenceExampleBoundaryError(
      context: context,
      boundary: .parsing,
      underlyingError: error
    )
  }

  do {
    return try driver.expand(template, context.parameters)
  } catch let evaluationError as URITemplate.EvaluationError {
    throw ReferenceExampleEvaluationFailure(
      context: context,
      evaluationError: evaluationError
    )
  } catch {
    throw ReferenceExampleBoundaryError(
      context: context,
      boundary: .evaluation,
      underlyingError: error
    )
  }
}

private func verifyExpectedReferenceExampleFailure(
  _ context: ReferenceExampleCaseContext,
  using driver: ReferenceExampleBehaviorDriver
) throws {
  let template: URITemplate
  do {
    template = try driver.parse(context.template)
  } catch is URITemplate.ParseError {
    return
  } catch {
    throw ReferenceExampleBoundaryError(
      context: context,
      boundary: .parsing,
      underlyingError: error
    )
  }

  let observedExpansion: String
  do {
    observedExpansion = try driver.expand(template, context.parameters)
  } catch is URITemplate.EvaluationError {
    return
  } catch {
    throw ReferenceExampleBoundaryError(
      context: context,
      boundary: .evaluation,
      underlyingError: error
    )
  }

  throw ReferenceExampleUnexpectedSuccess(
    context: context,
    parsedTemplateRepresentation: template.templateRepresentation,
    observedExpansion: observedExpansion
  )
}
