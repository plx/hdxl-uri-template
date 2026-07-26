import Testing

@testable import HDXLURITemplate

enum ReferenceExampleVerificationPhase: String, Hashable, Sendable {
  case parsing
  case expansion
}

enum ExpectedReferenceExampleIssueKind: Hashable, Sendable {
  case parseError(invalidLiteralContent: String)
  case exactExpansionMismatch(observed: String)

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
        failure.source == caseIdentity.source,
        failure.caption == caseIdentity.caption,
        failure.template == caseIdentity.template,
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
        failure.source == caseIdentity.source,
        failure.caption == caseIdentity.caption,
        failure.template == caseIdentity.template,
        case .exactMatch(let expected) = caseIdentity.expectation
      else {
        return false
      }
      return failure.expected == expected
        && failure.observed == observed
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

struct ReferenceExampleParsingFailure: Error {
  let source: String
  let caption: String
  let template: String
  let parseError: URITemplate.ParseError
}

struct ReferenceExampleExactExpansionMismatch: Error {
  let source: String
  let caption: String
  let template: String
  let expected: String
  let observed: String
}

struct TemporaryKnownReferenceExampleFailure: Sendable {
  let caseIdentity: ReferenceExampleCaseIdentity
  let verificationPhase: ReferenceExampleVerificationPhase
  let backlogIdentifier: String
  let issueNumber: Int
  let expectedIssueKind: ExpectedReferenceExampleIssueKind

  var issueURL: String {
    "https://github.com/plx/hdxl-uri-template/issues/\(issueNumber)"
  }

  var comment: String {
    "\(backlogIdentifier)/#\(issueNumber): \(issueURL)"
  }

  func matches(
    _ example: CaptionedTestCase,
    verificationPhase: ReferenceExampleVerificationPhase
  ) -> Bool {
    self.verificationPhase == verificationPhase
      && caseIdentity.matches(example)
  }
}

let temporaryKnownReferenceExampleFailures: [TemporaryKnownReferenceExampleFailure] = [
  TemporaryKnownReferenceExampleFailure(
    caseIdentity: ReferenceExampleCaseIdentity(
      source: "spec-examples",
      caption: "Level 1 Examples",
      template: "'{var}'",
      expectation: .exactMatch("'value'")
    ),
    verificationPhase: .parsing,
    backlogIdentifier: "CONF-03",
    issueNumber: 18,
    expectedIssueKind: .parseError(invalidLiteralContent: "'")
  ),
  TemporaryKnownReferenceExampleFailure(
    caseIdentity: ReferenceExampleCaseIdentity(
      source: "spec-examples",
      caption: "Level 1 Examples",
      template: "'{var}'",
      expectation: .exactMatch("'value'")
    ),
    verificationPhase: .expansion,
    backlogIdentifier: "CONF-03",
    issueNumber: 18,
    expectedIssueKind: .parseError(invalidLiteralContent: "'")
  ),
  TemporaryKnownReferenceExampleFailure(
    caseIdentity: ReferenceExampleCaseIdentity(
      source: "extended-tests",
      caption: "Additional Examples 8: Literal Encoding",
      template: "café/{var}",
      expectation: .exactMatch("caf%C3%A9/value")
    ),
    verificationPhase: .expansion,
    backlogIdentifier: "CONF-04",
    issueNumber: 25,
    expectedIssueKind: .exactExpansionMismatch(observed: "café/value")
  )
]

func withTemporaryKnownReferenceExampleFailure(
  for example: CaptionedTestCase,
  verificationPhase: ReferenceExampleVerificationPhase,
  sourceLocation: Testing.SourceLocation = #_sourceLocation,
  _ body: () throws -> Void
) rethrows {
  guard
    let knownFailure = temporaryKnownReferenceExampleFailures.first(
      where: {
        $0.matches(
          example,
          verificationPhase: verificationPhase
        )
      }
    )
  else {
    try body()
    return
  }

  try withKnownIssue(
    Comment(rawValue: knownFailure.comment),
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
