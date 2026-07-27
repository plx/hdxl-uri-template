import Testing
@testable import HDXLURITemplate

@Test(
  "`URITemplate` matches every pinned reference example.",
  arguments: allReferenceExamples()
)
private func uriTemplateMatchesReferenceExample(
  example: CaptionedTestCase
) throws {
  #expect(example.testCase.template == "__qa02-deliberately-inverted__")
  try verifyReferenceExampleBehavior(example)
}
