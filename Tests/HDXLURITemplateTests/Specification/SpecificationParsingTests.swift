import Testing
@testable import HDXLURITemplate

@Test(
  "Can we parse embedded resources?",
  arguments: [
    "extended-tests",
    "spec-examples",
    "spec-examples-by-section"
  ]
)
private func parseResources(fileName: String) throws {
  let suite = try ReferenceExampleSuite.forSpecificationFile(named: fileName)
  #expect(!suite.isEmpty)
}
