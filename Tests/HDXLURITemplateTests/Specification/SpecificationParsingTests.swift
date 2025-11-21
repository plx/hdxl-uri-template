import Testing
@testable import HDXLURITemplate

@Suite
struct SpecificationParsingTests {
  
  @Test(
    arguments: [
      "extended-tests",
      "spec-examples",
      "spec-examples-by-section"
    ]
  )
  private func `can we parse embedded resources`(fileName: String) throws {
    let suite = try ReferenceExampleSuite.forSpecificationFile(named: fileName)
    #expect(!suite.isEmpty)
  }

}
