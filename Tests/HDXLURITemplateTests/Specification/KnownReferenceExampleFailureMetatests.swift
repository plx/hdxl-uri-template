import Testing

@testable import HDXLURITemplate

@Test("Strict mode selects no temporary failures")
private func strictModeBypassesTemporaryLedger() throws {
  let examples = allReferenceExamples()
  let entry = syntheticKnownFailure
  let example = try syntheticPinnedExample()

  #expect(temporaryKnownReferenceExampleFailures.isEmpty)
  for example in examples {
    #expect(
      temporaryKnownReferenceExampleFailure(
        for: example,
        mode: .strict
      ) == nil
    )
  }

  #expect(
    temporaryKnownReferenceExampleFailure(
      for: example,
      mode: .strict,
      entries: [entry]
    ) == nil
  )
  #expect(throws: SyntheticKnownFailureProbeError.self) {
    try withTemporaryKnownReferenceExampleFailure(
      for: example,
      mode: .strict,
      entries: [entry]
    ) {
      throw SyntheticKnownFailureProbeError()
    }
  }
}

@Test("Temporary ledger fails when a known failure unexpectedly passes")
private func temporaryLedgerRejectsUnexpectedPass() async throws {
  let entry = syntheticKnownFailure
  let example = try syntheticPinnedExample()
  let currentTest = try #require(Test.current)
  let currentTestCase = Test.Case.current

  try await confirmation(
    "Captured fail-closed known-issue signal"
  ) { capturedSignal in
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
        mode: .temporaryLedger,
        entries: [entry]
      ) { }
    }
  }
}

@Test("Temporary ledger rejects an unrelated failure")
private func temporaryLedgerRejectsUnrelatedFailure() async throws {
  let entry = syntheticKnownFailure
  let example = try syntheticPinnedExample()
  let currentTest = try #require(Test.current)
  let currentTestCase = Test.Case.current

  await confirmation(
    "Captured fail-closed known-issue signal"
  ) { capturedSignal in
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
          mode: .temporaryLedger,
          entries: [entry]
        ) {
          throw SyntheticKnownFailureProbeError()
        }
      }
      Issue.record("An unrelated failure was hidden by the ledger.")
    } catch is SyntheticKnownFailureProbeError {
      // The unmatched error must escape the known-issue scope.
    } catch {
      Issue.record("Unexpected failure type: \(error)")
    }
  }
}

private let syntheticKnownFailure = TemporaryKnownReferenceExampleFailure(
  caseIdentity: ReferenceExampleCaseIdentity(
    source: "negative-tests",
    caption: "Failure Tests",
    template: "{keys:1}",
    expectation: .evaluationFailure
  ),
  backlogIdentifier: "SYNTHETIC",
  issueNumber: 33,
  expectedIssueKind: .expectedFailureUnexpectedSuccess(
    parsedTemplateRepresentation: "{keys:1}",
    observedExpansion: "comma,%2C,dot,.,semi,%3B"
  )
)

private func syntheticPinnedExample() throws -> CaptionedTestCase {
  try #require(
    allReferenceExamples().first(
      where: syntheticKnownFailure.caseIdentity.matches
    )
  )
}

private struct SyntheticKnownFailureProbeError: Error { }
