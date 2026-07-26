import Testing

@testable import HDXLURITemplate

@Test("Temporary conformance ledger is exactly the seven audited cases")
private func temporaryConformanceLedgerIsExactAndUnique() {
  let entries = temporaryKnownReferenceExampleFailures
  let caseIdentities = Set(entries.map(\.caseIdentity))
  let signatures = Set(entries.map(FailureSignature.init))

  #expect(entries.count == 7)
  #expect(caseIdentities.count == entries.count)
  #expect(signatures == expectedFailureSignatures)
  #expect(
    Dictionary(grouping: entries, by: \.issueNumber).mapValues(\.count)
      == [25: 1, 27: 3, 29: 1, 33: 2]
  )
  #expect(
    Set(entries.map(\.backlogIdentifier))
      == ["CONF-04", "CONF-06", "CONF-08", "CONF-09"]
  )
  #expect(
    entries.allSatisfy {
      $0.comment.contains($0.backlogIdentifier)
        && $0.comment.contains("#\($0.issueNumber)")
        && $0.comment.contains($0.issueURL)
    }
  )
}

@Test("Each temporary ledger identity selects exactly one pinned case")
private func temporaryLedgerIdentitiesAreSuiteQualified() {
  let examples = allReferenceExamples()

  for entry in temporaryKnownReferenceExampleFailures {
    #expect(
      examples.filter(entry.matches).count == 1,
      "Ledger identity must select one case: \(entry.caseIdentity)"
    )
  }
}

@Test("Every temporary ledger entry retains its exact current failure")
private func temporaryLedgerRetainsExactFailureEvidence() {
  let examples = allReferenceExamples()

  for entry in temporaryKnownReferenceExampleFailures {
    guard let example = examples.first(where: entry.matches) else {
      Issue.record("Missing pinned case for \(entry.caseIdentity)")
      continue
    }

    do {
      try verifyReferenceExampleBehavior(example)
      Issue.record(
        "Temporary failure unexpectedly passed: \(entry.caseIdentity)"
      )
    } catch {
      #expect(
        entry.expectedIssueKind.matches(
          error,
          caseIdentity: entry.caseIdentity
        ),
        "Observed failure drifted for \(entry.caseIdentity): \(error)"
      )
    }
  }
}

@Test("Resolved CONF-03 examples pass without temporary ledger entries")
private func resolvedCONF03ExamplesAreOrdinaryPasses() throws {
  for caseIdentity in resolvedCONF03CaseIdentities {
    let example = try pinnedExample(matching: caseIdentity)

    #expect(
      temporaryKnownReferenceExampleFailure(
        for: example,
        mode: .temporaryLedger
      ) == nil
    )
    try verifyReferenceExampleBehavior(example)
  }
}

@Test("Strict mode is command-selectable")
private func strictModeIsCommandSelectable() {
  #expect(
    ReferenceExampleKnownFailureMode.resolved(environment: [:])
      == .temporaryLedger
  )
  #expect(
    ReferenceExampleKnownFailureMode.resolved(
      environment: [
        ReferenceExampleKnownFailureMode.strictEnvironmentVariable: "0"
      ]
    ) == .temporaryLedger
  )
  #expect(
    ReferenceExampleKnownFailureMode.resolved(
      environment: [
        ReferenceExampleKnownFailureMode.strictEnvironmentVariable: "1"
      ]
    ) == .strict
  )
}

@Test("Strict mode selects no temporary failures and exposes known errors")
private func strictModeBypassesTemporaryLedger() {
  let examples = allReferenceExamples()

  for entry in temporaryKnownReferenceExampleFailures {
    guard let example = examples.first(where: entry.matches) else {
      Issue.record("Missing pinned case for \(entry.caseIdentity)")
      continue
    }
    #expect(
      temporaryKnownReferenceExampleFailure(
        for: example,
        mode: .strict
      ) == nil
    )
  }

  let entry = temporaryKnownReferenceExampleFailures[0]
  guard let example = examples.first(where: entry.matches) else {
    Issue.record("Missing pinned case for \(entry.caseIdentity)")
    return
  }

  do {
    try withTemporaryKnownReferenceExampleFailure(
      for: example,
      mode: .strict
    ) {
      try verifyReferenceExampleBehavior(example)
    }
    Issue.record("Strict mode hid a ledgered failure.")
  } catch {
    #expect(
      entry.expectedIssueKind.matches(
        error,
        caseIdentity: entry.caseIdentity
      )
    )
  }
}

@Test("Temporary ledger fails when a known failure unexpectedly passes")
private func temporaryLedgerRejectsUnexpectedPass() async throws {
  let entry = temporaryKnownReferenceExampleFailures[0]
  let example = try pinnedExample(matching: entry.caseIdentity)
  let currentTest = try #require(Test.current)
  let currentTestCase = Test.Case.current

  try await confirmation("Captured fail-closed known-issue signal") { capturedSignal in
    let issueHandler = IssueHandlingTrait.compactMapIssues { issue in
      guard
        case .knownIssueNotRecorded = issue.kind,
        issue.comments.map(\.rawValue) == [entry.comment]
      else {
        return issue
      }
      capturedSignal()
      return nil
    }

    try await issueHandler.provideScope(
      for: currentTest,
      testCase: currentTestCase
    ) {
      withTemporaryKnownReferenceExampleFailure(
        for: example,
        mode: .temporaryLedger
      ) { }
    }
  }
}

@Test("Temporary ledger rejects an unrelated failure")
private func temporaryLedgerRejectsUnrelatedFailure() async throws {
  let entry = temporaryKnownReferenceExampleFailures[0]
  let example = try pinnedExample(matching: entry.caseIdentity)
  let currentTest = try #require(Test.current)
  let currentTestCase = Test.Case.current

  await confirmation("Captured fail-closed known-issue signal") { capturedSignal in
    let issueHandler = IssueHandlingTrait.compactMapIssues { issue in
      guard
        case .knownIssueNotRecorded = issue.kind,
        issue.comments.map(\.rawValue) == [entry.comment]
      else {
        return issue
      }
      capturedSignal()
      return nil
    }

    do {
      try await issueHandler.provideScope(
        for: currentTest,
        testCase: currentTestCase
      ) {
        try withTemporaryKnownReferenceExampleFailure(
          for: example,
          mode: .temporaryLedger
        ) {
          throw KnownFailureMatcherProbeError()
        }
      }
      Issue.record("An unrelated failure was hidden by the ledger.")
    } catch is KnownFailureMatcherProbeError {
      // The unmatched error must escape the known-issue scope.
    } catch {
      Issue.record("Unexpected failure type: \(error)")
    }
  }
}

@Test("Known parse matcher rejects different failures")
private func knownParseMatcherIsExact() throws {
  let caseIdentity = try #require(resolvedCONF03CaseIdentities.first)
  let expectedIssueKind = ExpectedReferenceExampleIssueKind.parseError(
    invalidLiteralContent: "'"
  )
  let example = try pinnedExample(matching: caseIdentity)
  let context = ReferenceExampleCaseContext(example: example)
  let exactFailure = ReferenceExampleParsingFailure(
    context: context,
    parseError: URITemplate.ParseError(
      template: caseIdentity.template,
      underlyingError: URITemplateLiteralComponent.ParseError.invalidContent(
        "'"
      )
    )
  )
  let wrongUnderlyingFailure = ReferenceExampleParsingFailure(
    context: context,
    parseError: URITemplate.ParseError(
      template: caseIdentity.template,
      underlyingError: URITemplateLiteralComponent.ParseError.invalidContent(
        "\""
      )
    )
  )

  #expect(
    expectedIssueKind.matches(
      exactFailure,
      caseIdentity: caseIdentity
    )
  )
  #expect(
    !expectedIssueKind.matches(
      wrongUnderlyingFailure,
      caseIdentity: caseIdentity
    )
  )
  #expect(
    !expectedIssueKind.matches(
      KnownFailureMatcherProbeError(),
      caseIdentity: caseIdentity
    )
  )
}

private let resolvedCONF03CaseIdentities = [
  ReferenceExampleCaseIdentity(
    source: "spec-examples",
    caption: "Level 1 Examples",
    template: "'{var}'",
    expectation: .exactMatch("'value'")
  ),
  ReferenceExampleCaseIdentity(
    source: "spec-examples-by-section",
    caption: "2.1 Literals",
    template: "'{count}'",
    expectation: .exactMatch("'one,two,three'")
  )
]

@Test("Known expansion matcher rejects different output")
private func knownExpansionMatcherIsExact() throws {
  let entry = try #require(
    temporaryKnownReferenceExampleFailures.first {
      $0.caseIdentity.source == "extended-tests"
    }
  )
  let example = try pinnedExample(matching: entry.caseIdentity)
  let context = ReferenceExampleCaseContext(example: example)
  let exactFailure = ReferenceExampleExactExpansionMismatch(
    context: context,
    expected: "caf%C3%A9/value",
    observed: "café/value"
  )
  let differentWrongOutput = ReferenceExampleExactExpansionMismatch(
    context: context,
    expected: "caf%C3%A9/value",
    observed: "cafe/value"
  )

  #expect(
    entry.expectedIssueKind.matches(
      exactFailure,
      caseIdentity: entry.caseIdentity
    )
  )
  #expect(
    !entry.expectedIssueKind.matches(
      differentWrongOutput,
      caseIdentity: entry.caseIdentity
    )
  )
}

@Test("Known negative matcher rejects changed success evidence")
private func knownNegativeMatcherIsExact() throws {
  let entry = try #require(
    temporaryKnownReferenceExampleFailures.first {
      $0.caseIdentity.template == "{var:01}"
    }
  )
  let example = try pinnedExample(matching: entry.caseIdentity)
  let context = ReferenceExampleCaseContext(example: example)
  let exactFailure = ReferenceExampleUnexpectedSuccess(
    context: context,
    parsedTemplateRepresentation: "{var:1}",
    observedExpansion: "v"
  )
  let changedRepresentation = ReferenceExampleUnexpectedSuccess(
    context: context,
    parsedTemplateRepresentation: "{var:01}",
    observedExpansion: "v"
  )
  let changedExpansion = ReferenceExampleUnexpectedSuccess(
    context: context,
    parsedTemplateRepresentation: "{var:1}",
    observedExpansion: "va"
  )

  #expect(
    entry.expectedIssueKind.matches(
      exactFailure,
      caseIdentity: entry.caseIdentity
    )
  )
  #expect(
    !entry.expectedIssueKind.matches(
      changedRepresentation,
      caseIdentity: entry.caseIdentity
    )
  )
  #expect(
    !entry.expectedIssueKind.matches(
      changedExpansion,
      caseIdentity: entry.caseIdentity
    )
  )
}

private func pinnedExample(
  matching identity: ReferenceExampleCaseIdentity
) throws -> CaptionedTestCase {
  try #require(allReferenceExamples().first(where: identity.matches))
}

private struct KnownFailureMatcherProbeError: Error { }
