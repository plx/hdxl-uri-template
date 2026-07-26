import Testing
@testable import HDXLURITemplate

@Test(
  "`URITemplate` parses examples from spec.",
  arguments: allReferenceExamples()
)
private func uriTemplateParsesOK(example: CaptionedTestCase) throws {
  try withTemporaryKnownReferenceExampleFailure(
    for: example,
    verificationPhase: .parsing
  ) {
    try verifyTemplateParsing(
      source: example.source,
      caption: example.caption,
      testCase: example.testCase
    )
  }
}

@Test(
  "`URITemplate` evaluates as-expected per spec.",
  arguments: allReferenceExamples()
)
private func uriTemplateEvaluatesOK(example: CaptionedTestCase) throws {
  try withTemporaryKnownReferenceExampleFailure(
    for: example,
    verificationPhase: .expansion
  ) {
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
  testCase: ReferenceExampleTestCase
) throws {
  _ = try parseReferenceExampleTemplate(
    source: source,
    caption: caption,
    template: testCase.template
  )
}

private func verifyTemplateExpansion(
  source: String,
  caption: String,
  testCase: ReferenceExampleTestCase,
  parameters: [String: URIVariableValue],
  sourceLocation: Testing.SourceLocation = #_sourceLocation
) throws {
  let template = try parseReferenceExampleTemplate(
    source: source,
    caption: caption,
    template: testCase.template
  )
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
    guard evaluation == expectation else {
      throw ReferenceExampleExactExpansionMismatch(
        source: source,
        caption: caption,
        template: template.templateRepresentation,
        expected: expectation,
        observed: evaluation
      )
    }
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

private func parseReferenceExampleTemplate(
  source: String,
  caption: String,
  template: String
) throws -> URITemplate {
  do {
    return try URITemplate(parsing: template)
  } catch let parseError as URITemplate.ParseError {
    throw ReferenceExampleParsingFailure(
      source: source,
      caption: caption,
      template: template,
      parseError: parseError
    )
  }
}
