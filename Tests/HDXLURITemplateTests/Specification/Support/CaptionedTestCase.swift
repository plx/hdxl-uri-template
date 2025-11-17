import Testing

@testable import HDXLURITemplate

struct CaptionedTestCase {
  
  var source: String
  var caption: String
  var parameters: [String: URIVariableValue]
  var testCase: ReferenceExampleTestCase
  
}

extension CaptionedTestCase: Sendable { }
extension CaptionedTestCase: Equatable { }
extension CaptionedTestCase: Hashable { }
extension CaptionedTestCase: Codable { }

extension CaptionedTestCase: CustomTestStringConvertible {
  
  var testDescription: String {
    "`\(source)` \(caption): `\(testCase.template)` @ \(parameters.errorMessageRepresentation)"
  }
  
}

