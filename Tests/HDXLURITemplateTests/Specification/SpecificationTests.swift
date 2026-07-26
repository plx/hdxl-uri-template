import Testing
@testable import HDXLURITemplate

@Test(
  "`URITemplate` matches every pinned reference example.",
  arguments: allReferenceExamples()
)
private func uriTemplateMatchesReferenceExample(
  example: CaptionedTestCase
) throws {
  try withTemporaryKnownReferenceExampleFailure(
    for: example,
    mode: referenceExampleKnownFailureMode
  ) {
    try verifyReferenceExampleBehavior(example)
  }
}
