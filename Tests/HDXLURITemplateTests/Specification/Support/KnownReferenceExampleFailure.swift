import Foundation
import Testing

@testable import HDXLURITemplate

enum ReferenceExampleKnownFailureMode: Equatable, Sendable {
  case temporaryLedger
  case strict

  static let strictEnvironmentVariable =
    "HDXL_URI_TEMPLATE_STRICT_CONFORMANCE"

  static func resolved(
    environment: [String: String]
  ) -> ReferenceExampleKnownFailureMode {
    environment[strictEnvironmentVariable] == "1"
      ? .strict
      : .temporaryLedger
  }
}

// Set `HDXL_URI_TEMPLATE_STRICT_CONFORMANCE=1` to bypass the ledger.
let referenceExampleKnownFailureMode: ReferenceExampleKnownFailureMode =
  .resolved(environment: ProcessInfo.processInfo.environment)

enum ExpectedReferenceExampleIssueKind: Hashable, Sendable {
  case parseError(invalidLiteralContent: String)
  case exactExpansionMismatch(observed: String)
  case expectedFailureUnexpectedSuccess(
    parsedTemplateRepresentation: String,
    observedExpansion: String
  )

  func matches(
    _ issue: Testing.Issue,
    caseIdentity: ReferenceExampleCaseIdentity
  ) -> Bool {
    guard case .errorCaught(let error) = issue.kind else {
      return false
    }
    return matches(error, caseIdentity: caseIdentity)
  }

  func matches(
    _ error: any Error,
    caseIdentity: ReferenceExampleCaseIdentity
  ) -> Bool {
    switch self {
    case .parseError(let invalidLiteralContent):
      guard
        let failure = error as? ReferenceExampleParsingFailure,
        failure.context.caseIdentity == caseIdentity,
        failure.parseError.template == caseIdentity.template,
        let underlyingError = failure.parseError.underlyingError
          as? URITemplateLiteralComponent.ParseError,
        case .invalidContent(let observedInvalidContent) = underlyingError
      else {
        return false
      }
      return observedInvalidContent == invalidLiteralContent

    case .exactExpansionMismatch(let observed):
      guard
        let failure = error as? ReferenceExampleExactExpansionMismatch,
        failure.context.caseIdentity == caseIdentity,
        case .exactMatch(let expected) = caseIdentity.expectation
      else {
        return false
      }
      return failure.expected == expected
        && failure.observed == observed

    case .expectedFailureUnexpectedSuccess(
      let parsedTemplateRepresentation,
      let observedExpansion
    ):
      guard
        caseIdentity.expectation == .evaluationFailure,
        let failure =
          error as? ReferenceExampleUnexpectedSuccess,
        failure.context.caseIdentity == caseIdentity
      else {
        return false
      }
      return failure.parsedTemplateRepresentation
          == parsedTemplateRepresentation
        && failure.observedExpansion == observedExpansion
    }
  }
}

struct ReferenceExampleCaseIdentity: Hashable, Sendable {
  let source: String
  let caption: String
  let template: String
  let expectation: ReferenceExampleExpectation

  func matches(_ example: CaptionedTestCase) -> Bool {
    source == example.source
      && caption == example.caption
      && template == example.testCase.template
      && expectation == example.testCase.expectation
  }
}

struct TemporaryKnownReferenceExampleFailure: Sendable {
  let caseIdentity: ReferenceExampleCaseIdentity
  let backlogIdentifier: String
  let issueNumber: Int
  let expectedIssueKind: ExpectedReferenceExampleIssueKind

  var issueURL: String {
    "https://github.com/plx/hdxl-uri-template/issues/\(issueNumber)"
  }

  var comment: String {
    "\(backlogIdentifier)/#\(issueNumber): \(issueURL)"
  }

  func matches(_ example: CaptionedTestCase) -> Bool {
    caseIdentity.matches(example)
  }
}

let temporaryKnownReferenceExampleFailures:
  [TemporaryKnownReferenceExampleFailure] = [
    TemporaryKnownReferenceExampleFailure(
      caseIdentity: ReferenceExampleCaseIdentity(
        source: "negative-tests",
        caption: "Failure Tests",
        template: "{keys:1}",
        expectation: .evaluationFailure
      ),
      backlogIdentifier: "CONF-09",
      issueNumber: 33,
      expectedIssueKind: .expectedFailureUnexpectedSuccess(
        parsedTemplateRepresentation: "{keys:1}",
        observedExpansion: "comma,%2C,dot,.,semi,%3B"
      )
    ),
    TemporaryKnownReferenceExampleFailure(
      caseIdentity: ReferenceExampleCaseIdentity(
        source: "negative-tests",
        caption: "Failure Tests",
        template: "{+keys:1}",
        expectation: .evaluationFailure
      ),
      backlogIdentifier: "CONF-09",
      issueNumber: 33,
      expectedIssueKind: .expectedFailureUnexpectedSuccess(
        parsedTemplateRepresentation: "{+keys:1}",
        observedExpansion: "comma,,,dot,.,semi,;"
      )
    )
  ]

func temporaryKnownReferenceExampleFailure(
  for example: CaptionedTestCase,
  mode: ReferenceExampleKnownFailureMode
) -> TemporaryKnownReferenceExampleFailure? {
  guard mode == .temporaryLedger else {
    return nil
  }
  return temporaryKnownReferenceExampleFailures.first {
    $0.matches(example)
  }
}

func withTemporaryKnownReferenceExampleFailure(
  for example: CaptionedTestCase,
  mode: ReferenceExampleKnownFailureMode,
  sourceLocation: Testing.SourceLocation = #_sourceLocation,
  _ body: () throws -> Void
) rethrows {
  guard
    let knownFailure = temporaryKnownReferenceExampleFailure(
      for: example,
      mode: mode
    )
  else {
    try body()
    return
  }

  try withKnownIssue(
    Comment(rawValue: knownFailure.comment),
    isIntermittent: false,
    sourceLocation: sourceLocation,
    body,
    matching: { issue in
      knownFailure.expectedIssueKind.matches(
        issue,
        caseIdentity: knownFailure.caseIdentity
      )
    }
  )
}
