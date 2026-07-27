import Foundation

struct ReferenceExampleSuite {

  var groups: [String: ReferenceExampleGroup]

  var isEmpty: Bool { groups.isEmpty }
  var count: Int { groups.count }

  init(groups: [String: ReferenceExampleGroup]) {
    self.groups = groups
  }
}

extension ReferenceExampleSuite: Sendable {}
extension ReferenceExampleSuite: Equatable {}
extension ReferenceExampleSuite: Hashable {}

extension ReferenceExampleSuite: Codable {

  func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(groups)
  }

  init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()
    self.init(groups: try container.decode([String: ReferenceExampleGroup].self))
  }

}

extension ReferenceExampleSuite {

  enum ResourceError: Error {
    case fileNotFound(String)
  }

  static func decodeSpecificationData(
    _ data: Data
  ) throws -> ReferenceExampleSuite {
    try JSONDecoder.referenceExampleJSONDecoder.decode(
      ReferenceExampleSuite.self,
      from: data
    )
  }

  static func forSpecificationFile(
    named fileName: String
  ) throws -> ReferenceExampleSuite {
    guard
      let url = Bundle.module.url(
        forResource: fileName,
        withExtension: "json"
      )
    else {
      throw ResourceError.fileNotFound(fileName)
    }

    let data = try Data(contentsOf: url)

    return try decodeSpecificationData(data)
  }

  func captionedTestCases(
    source: String
  ) throws -> [CaptionedTestCase] {
    try groups.sorted { lhs, rhs in
      lhs.key < rhs.key
    }.flatMap { groupName, group in
      Array(
        try group.captionedTestCases(
          source: source,
          caption: groupName
        )
      )
    }
  }

}
