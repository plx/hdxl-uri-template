import Testing
@testable import HDXLURITemplate

let referenceExampleSuiteNames = [
  "spec-examples",
  "spec-examples-by-section",
  "extended-tests",
  "negative-tests"
]

func allReferenceExamples(
  function: StaticString = #function,
  file: StaticString = #file,
  line: UInt = #line
) -> [CaptionedTestCase] {
  do {
    var result: [CaptionedTestCase] = []
    for filename in referenceExampleSuiteNames {
      let suite = try ReferenceExampleSuite.forSpecificationFile(
        named: filename
      )
      result.append(
        contentsOf: try suite.captionedTestCases(source: filename)
      )
    }
    return result
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
