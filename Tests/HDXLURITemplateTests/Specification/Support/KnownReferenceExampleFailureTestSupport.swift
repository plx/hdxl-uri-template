struct FailureSignature: Hashable {
  let caseIdentity: ReferenceExampleCaseIdentity
  let backlogIdentifier: String
  let issueNumber: Int
  let expectedIssueKind: ExpectedReferenceExampleIssueKind

  init(
    caseIdentity: ReferenceExampleCaseIdentity,
    backlogIdentifier: String,
    issueNumber: Int,
    expectedIssueKind: ExpectedReferenceExampleIssueKind
  ) {
    self.caseIdentity = caseIdentity
    self.backlogIdentifier = backlogIdentifier
    self.issueNumber = issueNumber
    self.expectedIssueKind = expectedIssueKind
  }

  init(_ failure: TemporaryKnownReferenceExampleFailure) {
    self.init(
      caseIdentity: failure.caseIdentity,
      backlogIdentifier: failure.backlogIdentifier,
      issueNumber: failure.issueNumber,
      expectedIssueKind: failure.expectedIssueKind
    )
  }
}

let expectedFailureSignatures: Set<FailureSignature> = [
  FailureSignature(
    caseIdentity: ReferenceExampleCaseIdentity(
      source: "extended-tests",
      caption: "Additional Examples 8: Literal Encoding",
      template: "café/{var}",
      expectation: .exactMatch("caf%C3%A9/value")
    ),
    backlogIdentifier: "CONF-04",
    issueNumber: 25,
    expectedIssueKind: .exactExpansionMismatch(observed: "café/value")
  ),
  FailureSignature(
    caseIdentity: ReferenceExampleCaseIdentity(
      source: "negative-tests",
      caption: "Failure Tests",
      template: "{ leading_space}",
      expectation: .evaluationFailure
    ),
    backlogIdentifier: "CONF-06",
    issueNumber: 27,
    expectedIssueKind: .expectedFailureUnexpectedSuccess(
      parsedTemplateRepresentation: "{leading_space}",
      observedExpansion: ""
    )
  ),
  FailureSignature(
    caseIdentity: ReferenceExampleCaseIdentity(
      source: "negative-tests",
      caption: "Failure Tests",
      template: "{trailing_space }",
      expectation: .evaluationFailure
    ),
    backlogIdentifier: "CONF-06",
    issueNumber: 27,
    expectedIssueKind: .expectedFailureUnexpectedSuccess(
      parsedTemplateRepresentation: "{trailing_space}",
      observedExpansion: ""
    )
  ),
  FailureSignature(
    caseIdentity: ReferenceExampleCaseIdentity(
      source: "negative-tests",
      caption: "Failure Tests",
      template: "/resolution{?x, y}",
      expectation: .evaluationFailure
    ),
    backlogIdentifier: "CONF-06",
    issueNumber: 27,
    expectedIssueKind: .expectedFailureUnexpectedSuccess(
      parsedTemplateRepresentation: "/resolution{?x, y}",
      observedExpansion: "/resolution?x=1024&y=768"
    )
  ),
  FailureSignature(
    caseIdentity: ReferenceExampleCaseIdentity(
      source: "negative-tests",
      caption: "Failure Tests",
      template: "{var:01}",
      expectation: .evaluationFailure
    ),
    backlogIdentifier: "CONF-08",
    issueNumber: 29,
    expectedIssueKind: .expectedFailureUnexpectedSuccess(
      parsedTemplateRepresentation: "{var:1}",
      observedExpansion: "v"
    )
  ),
  FailureSignature(
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
  FailureSignature(
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
