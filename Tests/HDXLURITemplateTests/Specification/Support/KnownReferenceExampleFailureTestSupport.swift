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

let resolvedCONF06CaseIdentities = [
  ReferenceExampleCaseIdentity(
    source: "negative-tests",
    caption: "Failure Tests",
    template: "{ leading_space}",
    expectation: .evaluationFailure
  ),
  ReferenceExampleCaseIdentity(
    source: "negative-tests",
    caption: "Failure Tests",
    template: "{trailing_space }",
    expectation: .evaluationFailure
  ),
  ReferenceExampleCaseIdentity(
    source: "negative-tests",
    caption: "Failure Tests",
    template: "/resolution{?x, y}",
    expectation: .evaluationFailure
  )
]
