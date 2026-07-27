// -------------------------------------------------------------------------- //
// MARK: URITemplateComponentType - Definition
// -------------------------------------------------------------------------- //

internal enum URITemplateComponentType: UInt8 {

  case literal = 1
  case expression = 2

}

extension URITemplateComponentType: Sendable {}
extension URITemplateComponentType: Equatable {}
extension URITemplateComponentType: Hashable {}
extension URITemplateComponentType: Codable {}
extension URITemplateComponentType: CaseIterable {}

// -------------------------------------------------------------------------- //
// MARK: - Comparable
// -------------------------------------------------------------------------- //

extension URITemplateComponentType: Comparable {

  internal static func < (
    lhs: URITemplateComponentType,
    rhs: URITemplateComponentType
  ) -> Bool {
    lhs.rawValue < rhs.rawValue
  }

}

// -------------------------------------------------------------------------- //
// MARK: - CustomStringConvertible
// -------------------------------------------------------------------------- //

extension URITemplateComponentType: CustomStringConvertible {

  internal var description: String {
    switch self {
    case .literal:
      ".literal"
    case .expression:
      ".expression"
    }
  }

}

// -------------------------------------------------------------------------- //
// MARK: - CustomDebugStringConvertible
// -------------------------------------------------------------------------- //

extension URITemplateComponentType: CustomDebugStringConvertible {

  internal var debugDescription: String {
    switch self {
    case .literal:
      "URITemplateComponentType.literal"
    case .expression:
      "URITemplateComponentType.expression"
    }
  }

}
