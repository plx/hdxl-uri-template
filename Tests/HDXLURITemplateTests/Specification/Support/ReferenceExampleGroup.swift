import Foundation

struct ReferenceExampleGroup {
  
  var level: Int = 4
  var variables: [String: ReferenceExampleVariable]
  var testCases: [ReferenceExampleTestCase]
  
  init(
    level: Int,
    variables: [String : ReferenceExampleVariable],
    testCases: [ReferenceExampleTestCase]
  ) {
    self.level = level
    self.variables = variables
    self.testCases = testCases
  }
  
}

extension ReferenceExampleGroup: Sendable { }
extension ReferenceExampleGroup: Equatable { }
extension ReferenceExampleGroup: Hashable { }

extension ReferenceExampleGroup: Codable {
  
  enum CodingKeys: String, CodingKey {
    case level
    case variables
    case testCases = "testcases"
  }
  
  func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(self.level, forKey: .level)
    try container.encode(self.variables, forKey: .variables)
    try container.encode(self.testCases, forKey: .testCases)
  }
  
  init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.level = (try? container.decode(Int.self, forKey: .level)) ?? 4
    self.variables = try container.decode([String : ReferenceExampleVariable].self, forKey: .variables)
    self.testCases = try container.decode([ReferenceExampleTestCase].self, forKey: .testCases)
  }
}
