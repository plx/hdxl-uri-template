import Testing

@testable import HDXLURITemplate

@Test("Temporary conformance ledger is empty")
private func temporaryConformanceLedgerIsExactAndUnique() {
  let entries = temporaryKnownReferenceExampleFailures
  let caseIdentities = Set(entries.map(\.caseIdentity))
  let signatures = Set(entries.map(FailureSignature.init))

  #expect(entries.isEmpty)
  #expect(caseIdentities.count == entries.count)
  #expect(signatures == expectedFailureSignatures)
  #expect(
    Dictionary(grouping: entries, by: \.issueNumber).isEmpty
  )
  #expect(
    Set(entries.map(\.backlogIdentifier)).isEmpty
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

@Test("Resolved CONF-04 example passes without a temporary ledger entry")
private func resolvedCONF04ExampleIsAnOrdinaryPass() throws {
  let example = try pinnedExample(matching: resolvedCONF04CaseIdentity)

  #expect(
    temporaryKnownReferenceExampleFailure(
      for: example,
      mode: .temporaryLedger
    ) == nil
  )
  try verifyReferenceExampleBehavior(example)
}

@Test("Resolved CONF-06 examples pass without temporary ledger entries")
private func resolvedCONF06ExamplesAreOrdinaryPasses() throws {
  for caseIdentity in resolvedCONF06CaseIdentities {
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

private let resolvedCONF04CaseIdentity = ReferenceExampleCaseIdentity(
  source: "extended-tests",
  caption: "Additional Examples 8: Literal Encoding",
  template: "café/{var}",
  expectation: .exactMatch("caf%C3%A9/value")
)

@Test("Known expansion matcher rejects different output")
private func knownExpansionMatcherIsExact() throws {
  let expectedIssueKind = ExpectedReferenceExampleIssueKind
    .exactExpansionMismatch(observed: "café/value")
  let example = try pinnedExample(
    matching: resolvedCONF04CaseIdentity
  )
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
    expectedIssueKind.matches(
      exactFailure,
      caseIdentity: resolvedCONF04CaseIdentity
    )
  )
  #expect(
    !expectedIssueKind.matches(
      differentWrongOutput,
      caseIdentity: resolvedCONF04CaseIdentity
    )
  )
}

@Test("Known negative matcher rejects changed success evidence")
private func knownNegativeMatcherIsExact() throws {
  let caseIdentity = ReferenceExampleCaseIdentity(
    source: "negative-tests",
    caption: "Failure Tests",
    template: "{keys:1}",
    expectation: .evaluationFailure
  )
  let expectedIssueKind = ExpectedReferenceExampleIssueKind
    .expectedFailureUnexpectedSuccess(
      parsedTemplateRepresentation: "{keys:1}",
      observedExpansion: "comma,%2C,dot,.,semi,%3B"
  )
  let example = try pinnedExample(matching: caseIdentity)
  let context = ReferenceExampleCaseContext(example: example)
  let exactFailure = ReferenceExampleUnexpectedSuccess(
    context: context,
    parsedTemplateRepresentation: "{keys:1}",
    observedExpansion: "comma,%2C,dot,.,semi,%3B"
  )
  let changedRepresentation = ReferenceExampleUnexpectedSuccess(
    context: context,
    parsedTemplateRepresentation: "{keys:01}",
    observedExpansion: "comma,%2C,dot,.,semi,%3B"
  )
  let changedExpansion = ReferenceExampleUnexpectedSuccess(
    context: context,
    parsedTemplateRepresentation: "{keys:1}",
    observedExpansion: "comma,%2C,dot,.,semi,;"
  )

  #expect(
    expectedIssueKind.matches(
      exactFailure,
      caseIdentity: caseIdentity
    )
  )
  #expect(
    !expectedIssueKind.matches(
      changedRepresentation,
      caseIdentity: caseIdentity
    )
  )
  #expect(
    !expectedIssueKind.matches(
      changedExpansion,
      caseIdentity: caseIdentity
    )
  )
}

private func pinnedExample(
  matching identity: ReferenceExampleCaseIdentity
) throws -> CaptionedTestCase {
  try #require(allReferenceExamples().first(where: identity.matches))
}

private struct KnownFailureMatcherProbeError: Error { }
