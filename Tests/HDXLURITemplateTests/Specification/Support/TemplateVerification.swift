import Testing
@testable import HDXLURITemplate

struct ReferenceExampleSuiteContract: Hashable, Sendable {
  let name: String
  let expectedCaseCount: Int
}

let referenceExampleSuiteContracts = [
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
  )
]

let referenceExampleSuiteNames = referenceExampleSuiteContracts.map(\.name)

enum ReferenceExampleLoadingError: Error, Equatable {
  case noSuitesConfigured
  case noCasesDiscovered(source: String)
  case unexpectedCaseCount(
    source: String,
    expected: Int,
    observed: Int
  )
  case duplicateCaseIdentity(ReferenceExampleCaseIdentity)
}

func loadReferenceExamples(
  suiteContracts: [ReferenceExampleSuiteContract],
  suiteLoader: (String) throws -> ReferenceExampleSuite
) throws -> [CaptionedTestCase] {
  guard !suiteContracts.isEmpty else {
    throw ReferenceExampleLoadingError.noSuitesConfigured
  }

  var result: [CaptionedTestCase] = []
  var caseIdentities: Set<ReferenceExampleCaseIdentity> = []
  for suiteContract in suiteContracts {
    let suite = try suiteLoader(suiteContract.name)
    let suiteExamples = try suite.captionedTestCases(
      source: suiteContract.name
    )
    guard !suiteExamples.isEmpty else {
      throw ReferenceExampleLoadingError.noCasesDiscovered(
        source: suiteContract.name
      )
    }
    guard suiteExamples.count == suiteContract.expectedCaseCount else {
      throw ReferenceExampleLoadingError.unexpectedCaseCount(
        source: suiteContract.name,
        expected: suiteContract.expectedCaseCount,
        observed: suiteExamples.count
      )
    }

    for example in suiteExamples {
      let caseIdentity = ReferenceExampleCaseIdentity(example: example)
      guard caseIdentities.insert(caseIdentity).inserted else {
        throw ReferenceExampleLoadingError.duplicateCaseIdentity(
          caseIdentity
        )
      }
    }
    result.append(contentsOf: suiteExamples)
  }
  return result
}

func allReferenceExamples(
  function: StaticString = #function,
  file: StaticString = #file,
  line: UInt = #line
) -> [CaptionedTestCase] {
  do {
    return try loadReferenceExamples(
      suiteContracts: referenceExampleSuiteContracts
    ) { suiteName in
      try ReferenceExampleSuite.forSpecificationFile(
        named: suiteName
      )
    }
  } catch let error {
    fatalError(
      """
      Unable to load built-in test examples b/c \(String(reflecting: error))!

      - function: \(function)
      - file: \(file)
      - line: \(line)
      """,
      file: file,
      line: line
    )
  }
}
