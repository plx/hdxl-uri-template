enum ReferenceExamplePrimitiveJSONValue {
  case string(String)
  case boolean(Bool)
  case integer(Int)
  case double(Double)
  case null
}

extension ReferenceExamplePrimitiveJSONValue: Sendable {}
extension ReferenceExamplePrimitiveJSONValue: Equatable {}
extension ReferenceExamplePrimitiveJSONValue: Hashable {}

extension ReferenceExamplePrimitiveJSONValue: Codable {

  func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    switch self {
    case .string(let value):
      try container.encode(value)
    case .boolean(let value):
      try container.encode(value)
    case .integer(let value):
      try container.encode(value)
    case .double(let value):
      try container.encode(value)
    case .null:
      try container.encodeNil()
    }
  }

  init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()
    guard !container.decodeNil() else {
      self = .null
      return
    }

    if let string = try? container.decode(String.self) {
      self = .string(string)
    } else if let boolean = try? container.decode(Bool.self) {
      self = .boolean(boolean)
    } else if let integer = try? container.decode(Int.self) {
      self = .integer(integer)
    } else if let float = try? container.decode(Double.self) {
      self = .double(float)
    } else if let array = try? container.decode([Self].self) {
      print("failure (unexpected-array) @ \(container.codingPath): \(array)")
      throw DecodingError.dataCorrupted(
        DecodingError.Context(
          codingPath: decoder.codingPath,
          debugDescription: "Unsupported JSON type \(String(reflecting: container))!"
        )
      )
    } else if let dictionary = try? container.decode([String: Self].self) {
      print("failure (unexpected-dictionary) @ \(container.codingPath): \(dictionary)")
      throw DecodingError.dataCorrupted(
        DecodingError.Context(
          codingPath: decoder.codingPath,
          debugDescription: "Unsupported JSON type \(String(reflecting: container))!"
        )
      )
    } else {
      print("failure (unknown-type) @ \(container.codingPath): \(container), \(decoder)")
      throw DecodingError.dataCorrupted(
        DecodingError.Context(
          codingPath: decoder.codingPath,
          debugDescription: "Unsupported JSON type \(String(reflecting: container))!"
        )
      )
    }
  }

}
