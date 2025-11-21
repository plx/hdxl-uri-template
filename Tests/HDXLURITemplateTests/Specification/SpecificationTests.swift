import Testing
@testable import HDXLURITemplate

@Suite
struct SpecificationTests {

  @Test(arguments: allReferenceExamples())
  private func `spec examples parse`(example: CaptionedTestCase) throws {
    try verifyTemplateParsing(
      source: example.source,
      caption: example.caption,
      testCase: example.testCase
    )
  }
  
  @Test(arguments: allReferenceExamples())
  private func `evaluation matches spec`(example: CaptionedTestCase) throws {
    try verifyTemplateExpansion(
      source: example.source,
      caption: example.caption,
      testCase: example.testCase,
      parameters: example.parameters
    )
  }

}

// MARK: - Verifications

private func verifyTemplateParsing(
  source: String,
  caption: String,
  testCase: ReferenceExampleTestCase,
  sourceLocation: Testing.SourceLocation = #_sourceLocation
) throws {
  #expect(
    throws: Never.self,
    """
    Unexpected failure to parse reference-example template: `\(testCase.template)`
    
    - template: \(testCase.template)
    - source: \(source)
    - caption: \(caption)
    """
  ) {
    let _ = try URITemplate(parsing: testCase.template)
  }
}

private func verifyTemplateExpansion(
  source: String,
  caption: String,
  testCase: ReferenceExampleTestCase,
  parameters: [String: URIVariableValue],
  sourceLocation: Testing.SourceLocation = #_sourceLocation
) throws {
  let template = try URITemplate(parsing: testCase.template)
  switch testCase.expectation {
  case .evaluationFailure:
    #expect(
      throws: URITemplate.EvaluationError.self,
      sourceLocation: sourceLocation
    ) {
      try template.evaluate(parameters: parameters)
    }
  case .exactMatch(let expectation):
    let evaluation = try template.evaluateAsString(parameters: parameters)
    #expect(
      evaluation == expectation,
      """
      Template-expansion didn't match expectation.
      
      - template: \(template.templateRepresentation)
      - parameters: \(parameters.errorMessageRepresentation)
      - expected: \(expectation)
      - observed: \(evaluation)
      - source: \(source)
      - caption: \(caption)
      """,
      sourceLocation: sourceLocation
    )
  case .multiplePossibleMatches(let acceptableExpansions):
    let evaluation = try template.evaluateAsString(parameters: parameters)
    let options = acceptableExpansions
      .lazy
      .map { "            \($0)"}
      .joined(separator: "\n")
    #expect(
      acceptableExpansions.contains(evaluation),
      """
      Template-expansion didn't match expectation.
      
      - template: \(template.templateRepresentation)
      - parameters: \(parameters.errorMessageRepresentation)
      - observed: \(evaluation)
      - expected: 
      \(options)
      - source: \(source)
      - caption: \(caption)
      """,
      sourceLocation: sourceLocation
    )
  }
}
