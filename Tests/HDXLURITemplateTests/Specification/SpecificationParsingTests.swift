import Testing
@testable import HDXLURITemplate

@Test(
  "Can we parse embedded resources?",
  arguments: [
    "extended-tests",
    "negative-tests",
    "spec-examples",
    "spec-examples-by-section"
  ]
)
private func parseResources(fileName: String) throws {
  let suite = try ReferenceExampleSuite.forSpecificationFile(named: fileName)
  #expect(!suite.isEmpty)
}

@Test("Pinned uritemplate-test fixtures contain the expected case counts")
private func pinnedFixtureCaseCounts() throws {
  let expectedCaseCounts = [
    "spec-examples": 64,
    "spec-examples-by-section": 117,
    "extended-tests": 53,
    "negative-tests": 36
  ]

  for (fileName, expectedCaseCount) in expectedCaseCounts {
    let suite = try ReferenceExampleSuite.forSpecificationFile(named: fileName)
    let actualCaseCount = suite.groups.values.reduce(into: 0) { count, group in
      count += group.testCases.count
    }

    #expect(
      actualCaseCount == expectedCaseCount,
      "Expected \(expectedCaseCount) cases in \(fileName).json; found \(actualCaseCount)."
    )
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
