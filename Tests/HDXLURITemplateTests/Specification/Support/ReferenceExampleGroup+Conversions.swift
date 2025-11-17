import Foundation
@testable import HDXLURITemplate

extension ReferenceExampleGroup {
  
  var variableValues: [String: URIVariableValue] {
    variables.mapValues { referenceValue in
      referenceValue.variableValue
    }
  }
    
}

extension ReferenceExampleGroup {
  
  func captionedTestCases(
    source: String,
    caption: String
  ) -> some Sendable & Collection<CaptionedTestCase> {
    let parameters = variableValues
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
