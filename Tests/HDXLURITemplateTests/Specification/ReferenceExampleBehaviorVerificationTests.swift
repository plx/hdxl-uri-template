import Testing

@testable import HDXLURITemplate

@Test("Complete runner loads all 270 pinned case instances")
private func completeRunnerLoadsEveryPinnedCaseInstance() {
  let examples = allReferenceExamples()
  let countsBySource = Dictionary(
    grouping: examples,
    by: \.source
  ).mapValues(\.count)
  let identities = Set(
    examples.map {
      ReferenceExampleCaseContext(example: $0).caseIdentity
    }
  )
  let expectationCounts = examples.reduce(
    into: [ReferenceExpectationKind: Int]()
  ) { counts, example in
    counts[ReferenceExpectationKind(example.testCase.expectation), default: 0] += 1
  }

  #expect(referenceExampleSuiteNames.count == 4)
  #expect(
    countsBySource == [
      "spec-examples": 64,
      "spec-examples-by-section": 117,
      "extended-tests": 53,
      "negative-tests": 36,
    ]
  )
  #expect(
    expectationCounts == [
      .exactMatch: 193,
      .multiplePossibleMatches: 41,
      .evaluationFailure: 36,
    ]
  )
  #expect(examples.count == 270)
  #expect(identities.count == examples.count)
}

@Test("Runner contracts lock every pinned suite count")
private func runnerContractsLockEveryPinnedSuiteCount() {
  #expect(
    referenceExampleSuiteContracts
      == [
        ReferenceExampleSuiteContract(
          name: "spec-examples",
          expectedCaseCount: 64
        ),
        ReferenceExampleSuiteContract(
          name: "spec-examples-by-section",
          expectedCaseCount: 117
        ),
        ReferenceExampleSuiteContract(
          name: "extended-tests",
          expectedCaseCount: 53
        ),
        ReferenceExampleSuiteContract(
          name: "negative-tests",
          expectedCaseCount: 36
        ),
      ]
  )
}

@Test("Duplicated examples retain suite-qualified identities")
private func duplicatedExamplesRetainSuiteQualifiedIdentities() {
  let duplicatedExamples = allReferenceExamples().filter {
    $0.testCase.template == "{var}"
      && $0.testCase.expectation == .exactMatch("value")
  }

  #expect(duplicatedExamples.count == 2)
  #expect(
    Set(duplicatedExamples.map(\.source))
      == ["spec-examples", "spec-examples-by-section"]
  )
  #expect(
    Set(duplicatedExamples.map(ReferenceExampleCaseIdentity.init)).count
      == 2
  )
}

@Test("Exact string expectations require exact expansion")
private func exactStringExpectationRequiresExactExpansion() throws {
  try verifyReferenceExampleBehavior(
    syntheticExample(
      template: "{var}",
      expectation: .exactMatch("value")
    )
  )

  do {
    try verifyReferenceExampleBehavior(
      syntheticExample(
        template: "{var}",
        expectation: .exactMatch("different")
      )
    )
    Issue.record("A deliberately changed exact expectation passed.")
  } catch let mismatch as ReferenceExampleExactExpansionMismatch {
    #expect(mismatch.expected == "different")
    #expect(mismatch.observed == "value")
    #expect(mismatch.context.source == "synthetic-suite")
    #expect(mismatch.context.caption == "Synthetic Group")
    #expect(mismatch.context.template == "{var}")
    #expect(mismatch.context.parameters == ["var": .text("value")])
    #expect(mismatch.context.expectation == .exactMatch("different"))
  } catch {
    Issue.record("Unexpected failure type: \(error)")
  }
}

@Test("Array expectations accept any listed expansion")
private func alternateExpectationsAcceptAnyListedExpansion() throws {
  try verifyReferenceExampleBehavior(
    syntheticExample(
      template: "{var}",
      expectation: .multiplePossibleMatches(["other", "value"])
    )
  )

  do {
    try verifyReferenceExampleBehavior(
      syntheticExample(
        template: "{var}",
        expectation: .multiplePossibleMatches(["other", "another"])
      )
    )
    Issue.record("An expansion outside the accepted array passed.")
  } catch let mismatch as ReferenceExampleAlternateMismatch {
    #expect(mismatch.acceptableExpansions == ["other", "another"])
    #expect(mismatch.observed == "value")
  } catch {
    Issue.record("Unexpected failure type: \(error)")
  }
}

@Test("`false` accepts a controlled public parse rejection")
private func falseExpectationAcceptsControlledParseRejection() throws {
  try verifyReferenceExampleBehavior(
    syntheticExample(
      template: "{",
      expectation: .evaluationFailure
    )
  )
}

@Test("`false` accepts a controlled public evaluation rejection")
private func falseExpectationAcceptsControlledEvaluationRejection() throws {
  let driver = ReferenceExampleBehaviorDriver(
    parse: { source in
      try URITemplate(parsing: source)
    },
    expand: { template, parameters in
      throw URITemplate.EvaluationError(
        template: template,
        parameters: parameters
      )
    }
  )

  try verifyReferenceExampleBehavior(
    syntheticExample(
      template: "{var}",
      expectation: .evaluationFailure
    ),
    using: driver
  )
}

@Test("`false` rejects an unexpected successful expansion")
private func falseExpectationRejectsUnexpectedSuccess() {
  let example = syntheticExample(
    template: "{var}",
    expectation: .evaluationFailure
  )

  do {
    try verifyReferenceExampleBehavior(example)
    Issue.record("An unlisted successful `false` case passed.")
  } catch let failure as ReferenceExampleUnexpectedSuccess {
    #expect(failure.parsedTemplateRepresentation == "{var}")
    #expect(failure.observedExpansion == "value")
    #expect(failure.context.expectation == .evaluationFailure)
  } catch {
    Issue.record("Unexpected failure type: \(error)")
  }
}

@Test("`false` rejects non-public errors at either boundary")
private func falseExpectationRejectsUncontrolledErrors() {
  let example = syntheticExample(
    template: "{var}",
    expectation: .evaluationFailure
  )
  let uncontrolledParseDriver = ReferenceExampleBehaviorDriver(
    parse: { _ in
      throw BehaviorVerificationProbeError()
    },
    expand: { _, _ in
      "unreachable"
    }
  )
  let uncontrolledEvaluationDriver = ReferenceExampleBehaviorDriver(
    parse: { source in
      try URITemplate(parsing: source)
    },
    expand: { _, _ in
      throw BehaviorVerificationProbeError()
    }
  )

  expectUnexpectedBoundaryFailure(
    for: example,
    using: uncontrolledParseDriver,
    at: .parsing
  )
  expectUnexpectedBoundaryFailure(
    for: example,
    using: uncontrolledEvaluationDriver,
    at: .evaluation
  )
}

@Test("Positive parse errors retain complete case diagnostics")
private func positiveParseErrorsRetainCompleteDiagnostics() {
  let parsingExample = syntheticExample(
    template: "{",
    expectation: .exactMatch("unused")
  )
  do {
    try verifyReferenceExampleBehavior(parsingExample)
    Issue.record("Invalid positive template unexpectedly parsed.")
  } catch let failure as ReferenceExampleParsingFailure {
    #expect(
      failure.context
        == ReferenceExampleCaseContext(example: parsingExample)
    )
    #expect(failure.parseError.template == "{")
    #expect(failure.description.contains("synthetic-suite"))
    #expect(failure.description.contains("Synthetic Group"))
    #expect(failure.description.contains("\"var\""))
    #expect(failure.description.contains("\"unused\""))
  } catch {
    Issue.record("Unexpected failure type: \(error)")
  }
}

@Test("Positive evaluation errors retain complete case diagnostics")
private func positiveEvaluationErrorsRetainCompleteDiagnostics() {
  let evaluationExample = syntheticExample(
    template: "{var}",
    expectation: .exactMatch("value")
  )
  let driver = ReferenceExampleBehaviorDriver(
    parse: { source in
      try URITemplate(parsing: source)
    },
    expand: { template, parameters in
      throw URITemplate.EvaluationError(
        template: template,
        parameters: parameters
      )
    }
  )
  do {
    try verifyReferenceExampleBehavior(
      evaluationExample,
      using: driver
    )
    Issue.record("Injected positive evaluation rejection passed.")
  } catch let failure as ReferenceExampleEvaluationFailure {
    #expect(
      failure.context
        == ReferenceExampleCaseContext(example: evaluationExample)
    )
    #expect(failure.description.contains("synthetic-suite"))
    #expect(failure.description.contains("Synthetic Group"))
    #expect(failure.description.contains("\"var\""))
    #expect(failure.description.contains("\"value\""))
  } catch {
    Issue.record("Unexpected failure type: \(error)")
  }
}

private func syntheticExample(
  template: String,
  expectation: ReferenceExampleExpectation
) -> CaptionedTestCase {
  CaptionedTestCase(
    source: "synthetic-suite",
    caption: "Synthetic Group",
    parameters: ["var": .text("value")],
    testCase: ReferenceExampleTestCase(
      template: template,
      expectation: expectation
    )
  )
}

private func expectUnexpectedBoundaryFailure(
  for example: CaptionedTestCase,
  using driver: ReferenceExampleBehaviorDriver,
  at expectedBoundary: ReferenceExampleVerificationBoundary
) {
  do {
    try verifyReferenceExampleBehavior(example, using: driver)
    Issue.record(
      "An uncontrolled \(expectedBoundary.rawValue) error was accepted."
    )
  } catch let failure as ReferenceExampleBoundaryError {
    #expect(failure.boundary == expectedBoundary)
    #expect(failure.context == ReferenceExampleCaseContext(example: example))
    #expect(failure.underlyingError is BehaviorVerificationProbeError)
  } catch {
    Issue.record("Unexpected failure type: \(error)")
  }
}

private struct BehaviorVerificationProbeError: Error {}

private enum ReferenceExpectationKind: Hashable {
  case evaluationFailure
  case exactMatch
  case multiplePossibleMatches

  init(_ expectation: ReferenceExampleExpectation) {
    switch expectation {
    case .evaluationFailure:
      self = .evaluationFailure
    case .exactMatch:
      self = .exactMatch
    case .multiplePossibleMatches:
      self = .multiplePossibleMatches
    }
  }
}
