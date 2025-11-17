import Foundation

struct ReferenceExampleTestCase {
  
  var template: String
  var expectation: ReferenceExampleExpectation
  
  init(template: String, expectation: ReferenceExampleExpectation) {
    self.template = template
    self.expectation = expectation
  }
}

extension ReferenceExampleTestCase: Sendable { }
extension ReferenceExampleTestCase: Equatable { }
extension ReferenceExampleTestCase: Hashable { }

extension ReferenceExampleTestCase: Codable {
  
  func encode(to encoder: any Encoder) throws {
    var container = encoder.unkeyedContainer()
    try container.encode(template)
    try container.encode(expectation)
  }
  
  init(from decoder: any Decoder) throws {
    var container = try decoder.unkeyedContainer()
    self.template = try container.decode(String.self)
    self.expectation = try container.decode(ReferenceExampleExpectation.self)
  }
}
