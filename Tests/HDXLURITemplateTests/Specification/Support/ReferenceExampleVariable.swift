enum ReferenceExampleVariable {
  case value(ReferenceExamplePrimitiveJSONValue)
  case list([ReferenceExamplePrimitiveJSONValue])
  case association([String: ReferenceExamplePrimitiveJSONValue])
}

extension ReferenceExampleVariable: Sendable {}
extension ReferenceExampleVariable: Equatable {}
extension ReferenceExampleVariable: Hashable {}

extension ReferenceExampleVariable: Codable {

  func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    switch self {
    case .value(let value):
      try container.encode(value)
    case .list(let array):
      try container.encode(array)
    case .association(let dictionary):
      try container.encode(dictionary)
    }
  }

  init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()
    if let array = try? container.decode([ReferenceExamplePrimitiveJSONValue].self) {
      self = .list(array)
    } else if let dictionary = try? container.decode(
      [String: ReferenceExamplePrimitiveJSONValue].self
    ) {
      self = .association(dictionary)
    } else if let value = try? container.decode(ReferenceExamplePrimitiveJSONValue.self) {
      self = .value(value)
    } else {
      throw DecodingError.dataCorrupted(
        DecodingError.Context(
          codingPath: decoder.codingPath,
          debugDescription: "Unsupported JSON type"
        )
      )
    }
  }

}
