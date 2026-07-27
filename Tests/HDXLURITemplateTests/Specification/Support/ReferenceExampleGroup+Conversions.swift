import Foundation
@testable import HDXLURITemplate

extension ReferenceExampleGroup {

  var variableValues: [String: URIVariableValue] {
    get throws {
      try variables.mapValues { referenceValue in
        try referenceValue.variableValue
      }
    }
  }

}

extension ReferenceExampleGroup {

  func captionedTestCases(
    source: String,
    caption: String
  ) throws -> some Sendable & Collection<CaptionedTestCase> {
    let parameters = try variableValues
    return testCases.lazy.map { testCase in
      CaptionedTestCase(
        source: source,
        caption: caption,
        parameters: parameters,
        testCase: testCase
      )
    }
  }

}
