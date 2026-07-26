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
    let renderedParameters = parameters.keys.sorted().map { key in
      let value =
        parameters[key]?.fixtureDiagnosticRepresentation ?? "<missing>"
      return "\(String(reflecting: key)): \(value)"
    }
    .joined(separator: ", ")

    return """
    `\(source)` / \(caption) / template `\(testCase.template)` / \
    expectation \(testCase.expectation.diagnosticDescription) / \
    variables [ \(renderedParameters) ]
    """
  }

}
