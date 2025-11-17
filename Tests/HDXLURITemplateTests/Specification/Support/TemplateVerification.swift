import Testing
@testable import HDXLURITemplate

func allReferenceExamples(
  function: StaticString = #function,
  file: StaticString = #file,
  line: UInt = #line
) -> some Sendable & Collection<CaptionedTestCase> {
  do {
    return try [
      "spec-examples",
      "extended-tests"
    ].lazy.flatMap { filename in
      try ReferenceExampleSuite.forSpecificationFile(
        named: filename
      ).captionedTestCases(source: filename)
    }
  }
  catch let error {
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

