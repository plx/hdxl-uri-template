// MARK: URITemplateComponentType

@usableFromInline
package enum URITemplateComponentType : UInt8 {
  
  case literal = 1
  case expression = 2
  
}

// MARK: - Synthesized Conformances

extension URITemplateComponentType : Sendable { }
extension URITemplateComponentType : Equatable { }
extension URITemplateComponentType : Hashable { }
extension URITemplateComponentType : Codable { }
extension URITemplateComponentType : CaseIterable { }

// MARK: - Comparable

extension URITemplateComponentType : Comparable {

  @inlinable
  package static func <(
    lhs: URITemplateComponentType,
    rhs: URITemplateComponentType
  ) -> Bool {
    lhs.rawValue < rhs.rawValue
  }

}

// MARK: - CustomStringConvertible

extension URITemplateComponentType : CustomStringConvertible {

  @usableFromInline
  package var description: String {
    switch self {
    case .literal:
      ".literal"
    case .expression:
      ".expression"
    }
  }
  
}

// MARK: - CustomDebugStringConvertible

extension URITemplateComponentType : CustomDebugStringConvertible {
  
  @usableFromInline
  package var debugDescription: String {
    switch self {
    case .literal:
      "URITemplateComponentType.literal"
    case .expression:
      "URITemplateComponentType.expression"
    }
  }
  
}
