import Testing

@testable import HDXLURITemplate

@Test("Temporary fixture-activation known failures are exact and unique")
private func temporaryFixtureActivationKnownFailuresAreExactAndUnique() {
  let entries = temporaryKnownReferenceExampleFailures
  let caseIdentities = Set(entries.map(\.caseIdentity))
  let verificationKeys = Set(
    entries.map {
      VerificationKey(
        caseIdentity: $0.caseIdentity,
        verificationPhase: $0.verificationPhase
      )
    }
  )
  let signatures = Set(entries.map(FailureSignature.init))

  #expect(entries.count == 3)
  #expect(caseIdentities.count == 2)
  #expect(verificationKeys.count == entries.count)
  #expect(signatures == expectedFixtureActivationSignatures)
  #expect(Set(entries.map(\.issueNumber)) == [18, 25])
  #expect(Set(entries.map(\.backlogIdentifier)) == ["CONF-03", "CONF-04"])
  #expect(
    entries.filter { $0.verificationPhase == .parsing }.count == 1
  )
  #expect(
    entries.filter { $0.verificationPhase == .expansion }.count == 2
  )
}

@Test("Temporary parse matcher accepts only the audited apostrophe failure")
private func temporaryParseMatcherIsExact() {
  let issueKind = ExpectedReferenceExampleIssueKind.parseError(
    invalidLiteralContent: "'"
  )
  let exactFailure = ReferenceExampleParsingFailure(
    source: apostropheCaseIdentity.source,
    caption: apostropheCaseIdentity.caption,
    template: apostropheCaseIdentity.template,
    parseError: URITemplate.ParseError(
      template: apostropheCaseIdentity.template,
      underlyingError: URITemplateLiteralComponent.ParseError.invalidContent(
        "'"
      )
    )
  )
  let wrongUnderlyingFailure = ReferenceExampleParsingFailure(
    source: apostropheCaseIdentity.source,
    caption: apostropheCaseIdentity.caption,
    template: apostropheCaseIdentity.template,
    parseError: URITemplate.ParseError(
      template: apostropheCaseIdentity.template,
      underlyingError: URITemplateLiteralComponent.ParseError.invalidContent(
        "\""
      )
    )
  )

  #expect(
    issueKind.matches(exactFailure, caseIdentity: apostropheCaseIdentity)
  )
  #expect(
    !issueKind.matches(
      wrongUnderlyingFailure,
      caseIdentity: apostropheCaseIdentity
    )
  )
  #expect(
    !issueKind.matches(
      FixtureActivationMatcherProbeError(),
      caseIdentity: apostropheCaseIdentity
    )
  )
}

@Test("Temporary expansion matcher accepts only the audited observed output")
private func temporaryExpansionMatcherIsExact() {
  let issueKind = ExpectedReferenceExampleIssueKind.exactExpansionMismatch(
    observed: "café/value"
  )
  let exactFailure = ReferenceExampleExactExpansionMismatch(
    source: cafeCaseIdentity.source,
    caption: cafeCaseIdentity.caption,
    template: cafeCaseIdentity.template,
    expected: "caf%C3%A9/value",
    observed: "café/value"
  )
  let differentWrongOutput = ReferenceExampleExactExpansionMismatch(
    source: cafeCaseIdentity.source,
    caption: cafeCaseIdentity.caption,
    template: cafeCaseIdentity.template,
    expected: "caf%C3%A9/value",
    observed: "cafe/value"
  )
  let wrongSource = ReferenceExampleExactExpansionMismatch(
    source: "spec-examples",
    caption: cafeCaseIdentity.caption,
    template: cafeCaseIdentity.template,
    expected: "caf%C3%A9/value",
    observed: "café/value"
  )

  #expect(issueKind.matches(exactFailure, caseIdentity: cafeCaseIdentity))
  #expect(
    !issueKind.matches(differentWrongOutput, caseIdentity: cafeCaseIdentity)
  )
  #expect(!issueKind.matches(wrongSource, caseIdentity: cafeCaseIdentity))
  #expect(
    !issueKind.matches(
      FixtureActivationMatcherProbeError(),
      caseIdentity: cafeCaseIdentity
    )
  )
}

private struct VerificationKey: Hashable {
  let caseIdentity: ReferenceExampleCaseIdentity
  let verificationPhase: ReferenceExampleVerificationPhase
}

private struct FailureSignature: Hashable, Sendable {
  let caseIdentity: ReferenceExampleCaseIdentity
  let verificationPhase: ReferenceExampleVerificationPhase
  let backlogIdentifier: String
  let issueNumber: Int
  let expectedIssueKind: ExpectedReferenceExampleIssueKind

  init(
    caseIdentity: ReferenceExampleCaseIdentity,
    verificationPhase: ReferenceExampleVerificationPhase,
    backlogIdentifier: String,
    issueNumber: Int,
    expectedIssueKind: ExpectedReferenceExampleIssueKind
  ) {
    self.caseIdentity = caseIdentity
    self.verificationPhase = verificationPhase
    self.backlogIdentifier = backlogIdentifier
    self.issueNumber = issueNumber
    self.expectedIssueKind = expectedIssueKind
  }

  init(_ failure: TemporaryKnownReferenceExampleFailure) {
    self.init(
      caseIdentity: failure.caseIdentity,
      verificationPhase: failure.verificationPhase,
      backlogIdentifier: failure.backlogIdentifier,
      issueNumber: failure.issueNumber,
      expectedIssueKind: failure.expectedIssueKind
    )
  }
}

private let expectedFixtureActivationSignatures: Set<FailureSignature> = [
  FailureSignature(
    caseIdentity: apostropheCaseIdentity,
    verificationPhase: .parsing,
    backlogIdentifier: "CONF-03",
    issueNumber: 18,
    expectedIssueKind: .parseError(invalidLiteralContent: "'")
  ),
  FailureSignature(
    caseIdentity: apostropheCaseIdentity,
    verificationPhase: .expansion,
    backlogIdentifier: "CONF-03",
    issueNumber: 18,
    expectedIssueKind: .parseError(invalidLiteralContent: "'")
  ),
  FailureSignature(
    caseIdentity: cafeCaseIdentity,
    verificationPhase: .expansion,
    backlogIdentifier: "CONF-04",
    issueNumber: 25,
    expectedIssueKind: .exactExpansionMismatch(observed: "café/value")
  )
]

private let apostropheCaseIdentity = ReferenceExampleCaseIdentity(
  source: "spec-examples",
  caption: "Level 1 Examples",
  template: "'{var}'",
  expectation: .exactMatch("'value'")
)

private let cafeCaseIdentity = ReferenceExampleCaseIdentity(
  source: "extended-tests",
  caption: "Additional Examples 8: Literal Encoding",
  template: "café/{var}",
  expectation: .exactMatch("caf%C3%A9/value")
)

private struct FixtureActivationMatcherProbeError: Error {}
