enum ReferenceExampleExpectation {
  case evaluationFailure
  case exactMatch(String)
  case multiplePossibleMatches([String])
}

extension ReferenceExampleExpectation: Sendable { }
extension ReferenceExampleExpectation: Equatable { }
extension ReferenceExampleExpectation: Hashable { }

extension ReferenceExampleExpectation {

  var diagnosticDescription: String {
    switch self {
    case .evaluationFailure:
      "false (controlled parse or evaluation failure required)"
    case .exactMatch(let expected):
      String(reflecting: expected)
    case .multiplePossibleMatches(let acceptableExpansions):
      String(reflecting: acceptableExpansions)
    }
  }

}

extension ReferenceExampleExpectation: Codable {

  func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    switch self {
    case .evaluationFailure:
      try container.encode(false)
    case .exactMatch(let string):
      try container.encode(string)
    case .multiplePossibleMatches(let matches):
      try container.encode(matches)
    }
  }

  init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()
    if let sentinel = try? container.decode(Bool.self), sentinel == false {
      self = .evaluationFailure
    } else if let string = try? container.decode(String.self) {
      self = .exactMatch(string)
    } else if let possibleMatches = try? container.decode([String].self), !possibleMatches.isEmpty {
      self = .multiplePossibleMatches(possibleMatches)
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
