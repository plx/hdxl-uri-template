
// MARK: URIVariableValueData

/// Enumeration holding the actual data for a `URIVariableValue`. It's a bit
/// silly to make this enumeration `internal` and hide it inside a `public struct`,
/// but that's sadly the only way to enforce construction-time invariants on an
/// enumeration--if you can see an enumeration you can construct it with arbitary
/// payloads.
///
/// Keeping it internal is also the only way to hide the newtype-style wrappers
/// from the public API--which *is* another goal, here, too!
@usableFromInline
package enum URIVariableValueData {
  
  case undefined
  case text(URIVariableTextValue)
  case list(URIVariableListValue)
  case association(URIVariableAssociationValue)

  @usableFromInline
  package static let emptyList: URIVariableValueData = .list(URIVariableListValue())
  
  @usableFromInline
  package static let emptyAssociation: URIVariableValueData = .association(URIVariableAssociationValue())

  @inlinable
  package init(from text: String) {
    self = .text(
      URIVariableTextValue(rawValue: text)
    )
  }

  @inlinable
  internal init<S:Sequence>(from texts: S) where S.Element == String {
    self = .list(
      URIVariableListValue(
        values: texts.map() {
          URIVariableTextValue(rawValue: $0)
        }
      )
    )
  }

  @inlinable
  internal init(singleElementListFrom text: String) {
    self = .list(
      URIVariableListValue(
        value: URIVariableTextValue(rawValue: text)
      )
    )
  }

  @inlinable
  internal init(from pair: (String,String)) {
    self = .association(
      URIVariableAssociationValue(
        value: URIVariablePairValue(
          key: URIVariableTextValue(rawValue: pair.0),
          value: URIVariableTextValue(rawValue: pair.1)
        )
      )
    )
  }

  @inlinable
  internal init<S:Sequence>(from pairs: S) where S.Element == (String,String) {
    self = .association(
      URIVariableAssociationValue(
        values: pairs.map() {
          URIVariablePairValue(
            key: URIVariableTextValue(rawValue: $0),
            value: URIVariableTextValue(rawValue: $1)
          )
        }
      )
    )
  }
  
}

// MARK: - Synthesized Conformances

extension URIVariableValueData : Sendable { }
extension URIVariableValueData : Equatable { }
extension URIVariableValueData : Hashable { }

// MARK: - Comparable

extension URIVariableValueData : Comparable {
  
  @inlinable
  package static func <(
    lhs: URIVariableValueData,
    rhs: URIVariableValueData
  ) -> Bool {
    return switch (lhs,rhs) {
    case (.undefined, .undefined):
      false
    case (.text(let l), .text(let r)):
      l < r
    case (.list(let l), .list(let r)):
      l < r
    case (.association(let l), .association(let r)):
      l < r
    default:
      lhs.valueType < rhs.valueType
    }
  }
  
}

// MARK: - CustomStringConvertible

extension URIVariableValueData : CustomStringConvertible {
  
  @usableFromInline
  package var description: String {
    switch self {
    case .undefined:
      ".undefined"
    case .text(let text):
      ".text(\"\(text.rawValue)\")"
    case .list(let list):
      ".list(\(list.description))"
    case .association(let association):
      ".association(\(association.description))"
    }
  }
  
}

// MARK: - CustomDebugStringConvertible

extension URIVariableValueData : CustomDebugStringConvertible {
  
  @usableFromInline
  package var debugDescription: String {
    switch self {
    case .undefined:
      "URIVariableValueData.undefined"
    case .text(let text):
      "URIVariableValueData.text(\(text.debugDescription))"
    case .list(let list):
      "URIVariableValueData.list(\(list.debugDescription))"
    case .association(let association):
      "URIVariableValueData.association(\(association.debugDescription))"
    }
  }
  
}

// MARK: - Codable

extension URIVariableValueData : Codable {
  
  @usableFromInline
  internal typealias CodingKeys = StandardEnumerationCodingKeys
  
  @usableFromInline
  package func encode(to encoder: Encoder) throws {
    var container = encoder.container(
      keyedBy: CodingKeys.self
    )
    try container.encode(
      valueType,
      forKey: .type
    )
    switch self {
    case .undefined:
      ()
    case .text(let text):
      try container.encode(
        text,
        forKey: .data
      )
    case .list(let list):
      try container.encode(
        list,
        forKey: .data
      )
    case .association(let association):
      try container.encode(
        association,
        forKey: .data
      )
    }
  }
  
  @usableFromInline
  package init(from decoder: Decoder) throws {
    let container = try decoder.container(
      keyedBy: CodingKeys.self
    )
    let type = try container.decode(
      URIVariableValueType.self,
      forKey: .type
    )
    switch type {
    case .undefined:
      self = .undefined
    case .text:
      self = .text(
        try container.decode(
          URIVariableTextValue.self,
          forKey: .data
        )
      )
    case .list:
      self = .list(
        try container.decode(
          URIVariableListValue.self,
          forKey: .data
        )
      )
    case .association:
      self = .association(
        try container.decode(
          URIVariableAssociationValue.self,
          forKey: .data
        )
      )
    }
  }
  
}

// MARK: - Core API

extension URIVariableValueData {
  
  @inlinable
  internal var valueType: URIVariableValueType {
    switch self {
    case .undefined:
      .undefined
    case .text(_):
      .text
    case .list(_):
      .list
    case .association(_):
      .association
    }
  }
  
  @inlinable
  internal var isEmpty: Bool {
    switch self {
    case .undefined:
      true
    case .text(let text):
      text.isEmpty
    case .list(let list):
      list.isEmpty
    case .association(let association):
      association.isEmpty
    }
  }
  
  @inlinable
  internal var isDefined: Bool {
    switch self {
    case .undefined:
      false
    case .text(_):
      true
    case .list(_):
      true
    case .association(_):
      true
    }
  }
  
  @inlinable
  internal var isUndefined: Bool {
    switch self {
    case .undefined:
      true
    case .text(_):
      false
    case .list(_):
      false
    case .association(_):
      false
    }
  }

  @inlinable
  internal var count: Int {
    switch self {
    case .undefined:
      0
    case .text(_):
      1
    case .list(let list):
      list.count
    case .association(let association):
      association.count
    }
  }

  @inlinable
  internal var isUndefinedValue: Bool {
    switch self {
    case .undefined:
      true
    default:
      false
    }
  }
  
  @inlinable
  internal var isTextValue: Bool {
    switch self {
    case .text(_):
      true
    default:
      false
    }
  }
  
  @inlinable
  internal var isListValue: Bool {
    switch self {
    case .list(_):
      true
    default:
      false
    }
  }
  
  @inlinable
  internal var isAssociationValue: Bool {
    switch self {
    case .association(_):
      true
    default:
      false
    }
  }
  
  @usableFromInline
  internal var errorMessageRepresentation: String {
    switch self {
    case .undefined:
      ".undefined"
    case .text(let text):
      text.errorMessageRepresentation
    case .list(let list):
      list.errorMessageRepresentation
    case .association(let association):
      association.errorMessageRepresentation
    }
  }


}

// MARK: - Validatable

extension URIVariableValueData {
  
  @inlinable
  internal var isValid: Bool {
    switch self {
    case .undefined:
      true
    case .text(let text):
      text.isValid
    case .list(let list):
      list.isValid
    case .association(let association):
      association.isValid
    }
  }
    
}
