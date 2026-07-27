import Foundation
import Testing
@testable import HDXLURITemplate

@Test(
  "Can we parse embedded resources?",
  arguments: [
    "extended-tests",
    "negative-tests",
    "spec-examples",
    "spec-examples-by-section",
  ]
)
private func parseResources(fileName: String) throws {
  let suite = try ReferenceExampleSuite.forSpecificationFile(named: fileName)
  #expect(!suite.isEmpty)
}

@Test("Pinned uritemplate-test fixtures contain the expected case counts")
private func pinnedFixtureCaseCounts() throws {
  for suiteContract in referenceExampleSuiteContracts {
    let suite = try ReferenceExampleSuite.forSpecificationFile(
      named: suiteContract.name
    )
    let actualCaseCount = suite.groups.values.reduce(into: 0) { count, group in
      count += group.testCases.count
    }

    #expect(
      actualCaseCount == suiteContract.expectedCaseCount,
      """
      Expected \(suiteContract.expectedCaseCount) cases in \
      \(suiteContract.name).json; found \(actualCaseCount).
      """
    )
  }
}

@Test("Missing reference suites fail closed")
private func missingReferenceSuiteFailsClosed() {
  let missingSuiteName = "__missing-reference-suite__"
  do {
    _ = try loadReferenceExamples(
      suiteContracts: [
        ReferenceExampleSuiteContract(
          name: missingSuiteName,
          expectedCaseCount: 1
        )
      ]
    ) { suiteName in
      try ReferenceExampleSuite.forSpecificationFile(
        named: suiteName
      )
    }
    Issue.record("A missing reference suite was accepted.")
  } catch let error as ReferenceExampleSuite.ResourceError {
    guard case .fileNotFound(let fileName) = error else {
      Issue.record("Unexpected resource error: \(error)")
      return
    }
    #expect(fileName == missingSuiteName)
  } catch {
    Issue.record("Unexpected missing-suite error: \(error)")
  }
}

@Test("Zero-case reference suites fail closed")
private func zeroCaseReferenceSuiteFailsClosed() throws {
  let emptySuite = try ReferenceExampleSuite.decodeSpecificationData(
    Data("{}".utf8)
  )
  expectReferenceExampleLoadingError(
    .noCasesDiscovered(source: "empty-suite"),
    suiteContracts: [
      ReferenceExampleSuiteContract(
        name: "empty-suite",
        expectedCaseCount: 1
      )
    ],
    suiteLoader: { _ in emptySuite }
  )
}

@Test("Empty reference resources fail closed")
private func emptyReferenceResourceFailsClosed() {
  #expect(throws: DecodingError.self) {
    _ = try ReferenceExampleSuite.decodeSpecificationData(Data())
  }
}

@Test("Undecodable reference suites fail closed")
private func undecodableReferenceSuiteFailsClosed() {
  #expect(throws: DecodingError.self) {
    _ = try loadReferenceExamples(
      suiteContracts: [
        ReferenceExampleSuiteContract(
          name: "undecodable-suite",
          expectedCaseCount: 1
        )
      ]
    ) { _ in
      try ReferenceExampleSuite.decodeSpecificationData(
        Data("not JSON".utf8)
      )
    }
  }
}

@Test("Zero configured reference suites fail closed")
private func zeroConfiguredReferenceSuitesFailClosed() {
  expectReferenceExampleLoadingError(
    .noSuitesConfigured,
    suiteContracts: [],
    suiteLoader: { _ in
      Issue.record("An empty suite contract invoked the loader.")
      return ReferenceExampleSuite(groups: [:])
    }
  )
}

@Test("Reference suite loading rejects count drift and duplicate identities")
private func referenceSuiteLoadingRejectsDriftAndDuplicates() throws {
  let specExamples = try ReferenceExampleSuite.forSpecificationFile(
    named: "spec-examples"
  )
  expectReferenceExampleLoadingError(
    .unexpectedCaseCount(
      source: "spec-examples",
      expected: 63,
      observed: 64
    ),
    suiteContracts: [
      ReferenceExampleSuiteContract(
        name: "spec-examples",
        expectedCaseCount: 63
      )
    ],
    suiteLoader: { _ in specExamples }
  )

  do {
    _ = try loadReferenceExamples(
      suiteContracts: [
        ReferenceExampleSuiteContract(
          name: "spec-examples",
          expectedCaseCount: 64
        ),
        ReferenceExampleSuiteContract(
          name: "spec-examples",
          expectedCaseCount: 64
        ),
      ],
      suiteLoader: { _ in specExamples }
    )
    Issue.record("Duplicated case identities were accepted.")
  } catch let error as ReferenceExampleLoadingError {
    guard case .duplicateCaseIdentity(let identity) = error else {
      Issue.record("Unexpected duplicate-suite error: \(error)")
      return
    }
    #expect(identity.source == "spec-examples")
  } catch {
    Issue.record("Unexpected duplicate-suite error: \(error)")
  }
}

@Test("Pinned spec examples include the RFC 6570 apostrophe example")
private func pinnedSpecExamplesIncludeApostropheExample() throws {
  let suite = try ReferenceExampleSuite.forSpecificationFile(named: "spec-examples")
  let containsApostropheExample = suite.groups.values
    .lazy
    .flatMap(\.testCases)
    .contains {
      $0.template == "'{var}'"
        && $0.expectation == .exactMatch("'value'")
    }

  #expect(containsApostropheExample)
}

private func expectReferenceExampleLoadingError(
  _ expectedError: ReferenceExampleLoadingError,
  suiteContracts: [ReferenceExampleSuiteContract],
  suiteLoader: (String) throws -> ReferenceExampleSuite
) {
  do {
    _ = try loadReferenceExamples(
      suiteContracts: suiteContracts,
      suiteLoader: suiteLoader
    )
    Issue.record("Expected loading error was not thrown: \(expectedError)")
  } catch let error as ReferenceExampleLoadingError {
    #expect(error == expectedError)
  } catch {
    Issue.record("Unexpected reference-suite loading error: \(error)")
  }
}
