//
//  URIVariableValueDataData.swift
//

import Foundation
import HDXLCommonUtilities

// -------------------------------------------------------------------------- //
// MARK: URIVariableValueData - Definition
// -------------------------------------------------------------------------- //

/// Enumeration holding the actual data for a `URIVariableValue`. It's a bit
/// silly to make this enumeration `internal` and hide it inside a `public struct`,
/// but that's sadly the only way to enforce construction-time invariants on an
/// enumeration--if you can see an enumeration you can construct it with arbitary
/// payloads.
///
/// Keeping it internal is also the only way to hide the newtype-style wrappers
/// from the public API--which *is* another goal, here, too!
@frozen
@usableFromInline
internal enum URIVariableValueData {
  
  case undefined
  case text(URIVariableTextValue)
  case list(URIVariableListValue)
  case association(URIVariableAssociationValue)

  @usableFromInline
  internal static let emptyList: URIVariableValueData = .list(URIVariableListValue())
  
  @usableFromInline
  internal static let emptyAssociation: URIVariableValueData = .association(URIVariableAssociationValue())

  @inlinable
  internal init(from text: String) {
    // /////////////////////////////////////////////////////////////////////////
    defer { pedantic_assert(self.isValid) }
    // /////////////////////////////////////////////////////////////////////////
    self = .text(
      URIVariableTextValue(text: text)
    )
  }

  @inlinable
  internal init<S:Sequence>(from texts: S) where S.Element == String {
    // /////////////////////////////////////////////////////////////////////////
    defer { pedantic_assert(self.isValid) }
    // /////////////////////////////////////////////////////////////////////////
    self = .list(
      URIVariableListValue(
        values: texts.map() {
          URIVariableTextValue(text: $0)
        }
      )
    )
  }

  @inlinable
  internal init(singleElementListFrom text: String) {
    // /////////////////////////////////////////////////////////////////////////
    defer { pedantic_assert(self.isValid) }
    // /////////////////////////////////////////////////////////////////////////
    self = .list(
      URIVariableListValue(
        value: URIVariableTextValue(text: text)
      )
    )
  }

  @inlinable
  internal init(from pair: (String,String)) {
    // /////////////////////////////////////////////////////////////////////////
    defer { pedantic_assert(self.isValid) }
    // /////////////////////////////////////////////////////////////////////////
    self = .association(
      URIVariableAssociationValue(
        value: URIVariablePairValue(
          key: URIVariableTextValue(text: pair.0),
          value: URIVariableTextValue(text: pair.1)
        )
      )
    )
  }

  @inlinable
  internal init<S:Sequence>(from pairs: S) where S.Element == (String,String) {
    // /////////////////////////////////////////////////////////////////////////
    defer { pedantic_assert(self.isValid) }
    // /////////////////////////////////////////////////////////////////////////
    self = .association(
      URIVariableAssociationValue(
        values: pairs.map() {
          URIVariablePairValue(
            key: URIVariableTextValue(text: $0),
            value: URIVariableTextValue(text: $1)
          )
        }
      )
    )
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: URIVariableValueData - Core API
// -------------------------------------------------------------------------- //

internal extension URIVariableValueData {
  
  @inlinable
  var valueType: URIVariableValueType {
    get {
      switch self {
      case .undefined:
        return .undefined
      case .text(_):
        return .text
      case .list(_):
        return .list
      case .association(_):
        return .association
      }
    }
  }
  
  @inlinable
  var isEmpty: Bool {
    get {
      switch self {
      case .undefined:
        return true
      case .text(let text):
        return text.isEmpty
      case .list(let list):
        return list.isEmpty
      case .association(let association):
        return association.isEmpty
      }
    }
  }
  
  @inlinable
  var isDefined: Bool {
    get {
      switch self {
      case .undefined:
        return false
      case .text(_):
        return true
      case .list(_):
        return true
      case .association(_):
        return true
      }
    }
  }
  
  @inlinable
  var isUndefined: Bool {
    get {
      switch self {
      case .undefined:
        return true
      case .text(_):
        return false
      case .list(_):
        return false
      case .association(_):
        return false
      }
    }
  }

  @inlinable
  var count: Int {
    get {
      switch self {
      case .undefined:
        return 0
      case .text(_):
        return 1
      case .list(let list):
        return list.count
      case .association(let association):
        return association.count
      }
    }
  }

  @inlinable
  var isUndefinedValue: Bool {
    get {
      switch self {
      case .undefined:
        return true
      default:
        return false
      }
    }
  }
  
  @inlinable
  var isTextValue: Bool {
    get {
      switch self {
      case .text(_):
        return true
      default:
        return false
      }
    }
  }
  
  @inlinable
  var isListValue: Bool {
    get {
      switch self {
      case .list(_):
        return true
      default:
        return false
      }
    }
  }
  
  @inlinable
  var isAssociationValue: Bool {
    get {
      switch self {
      case .association(_):
        return true
      default:
        return false
      }
    }
  }

}

// -------------------------------------------------------------------------- //
// MARK: URIVariableValueData - Validatable
// -------------------------------------------------------------------------- //

extension URIVariableValueData : Validatable {
  
  @inlinable
  internal var isValid: Bool {
    get {
      switch self {
      case .undefined:
        return true
      case .text(let text):
        return text.isValid
      case .list(let list):
        return list.isValid
      case .association(let association):
        return association.isValid
      }
    }
  }
    
}

// -------------------------------------------------------------------------- //
// MARK: URIVariableValueData - Equatable
// -------------------------------------------------------------------------- //

extension URIVariableValueData : Equatable {
 
  @inlinable
  internal static func ==(
    lhs: URIVariableValueData,
    rhs: URIVariableValueData) -> Bool {
    // /////////////////////////////////////////////////////////////////////////
    pedantic_assert(lhs.isValid)
    pedantic_assert(rhs.isValid)
    // /////////////////////////////////////////////////////////////////////////
    switch (lhs,rhs) {
    case (.undefined, .undefined):
      return true
    case (.text(let l), .text(let r)):
      return l == r
    case (.list(let l), .list(let r)):
      return l == r
    case (.association(let l), .association(let r)):
      return l == r
    default:
      return false
    }
  }

}


// -------------------------------------------------------------------------- //
// MARK: URIVariableValueData - Comparable
// -------------------------------------------------------------------------- //

extension URIVariableValueData : Comparable {

  @inlinable
  internal static func <(
    lhs: URIVariableValueData,
    rhs: URIVariableValueData) -> Bool {
    // /////////////////////////////////////////////////////////////////////////
    pedantic_assert(lhs.isValid)
    pedantic_assert(rhs.isValid)
    // /////////////////////////////////////////////////////////////////////////
    switch (lhs,rhs) {
    case (.undefined, .undefined):
      return false
    case (.text(let l), .text(let r)):
      return l < r
    case (.list(let l), .list(let r)):
      return l < r
    case (.association(let l), .association(let r)):
      return l < r
    default:
      return lhs.valueType < rhs.valueType
    }
  }

}

// -------------------------------------------------------------------------- //
// MARK: URIVariableValueData - Hashable
// -------------------------------------------------------------------------- //

extension URIVariableValueData : Hashable {

  @inlinable
  func hash(into hasher: inout Hasher) {
    switch self {
    case .undefined:
      URIVariableValueType.undefined.hash(into: &hasher)
    case .text(let text):
      URIVariableValueType.text.hash(into: &hasher)
      text.hash(into: &hasher)
    case .list(let list):
      URIVariableValueType.list.hash(into: &hasher)
      list.hash(into: &hasher)
    case .association(let association):
      URIVariableValueType.association.hash(into: &hasher)
      association.hash(into: &hasher)
    }
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: URIVariableValueData - CustomStringConvertible
// -------------------------------------------------------------------------- //

extension URIVariableValueData : CustomStringConvertible {

  @inlinable
  internal var description: String {
    get {
      switch self {
      case .undefined:
        return ".undefined"
      case .text(let text):
        return ".text(\"\(text.storage)\")"
      case .list(let list):
        return ".list(\(list.description))"
      case .association(let association):
        return ".association(\(association.description))"
      }
    }
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: URIVariableValueData - CustomDebugStringConvertible
// -------------------------------------------------------------------------- //

extension URIVariableValueData : CustomDebugStringConvertible {
  
  @inlinable
  internal var debugDescription: String {
    get {
      switch self {
      case .undefined:
        return "URIVariableValueData.undefined"
      case .text(let text):
        return "URIVariableValueData.text(\(text.debugDescription))"
      case .list(let list):
        return "URIVariableValueData.list(\(list.debugDescription))"
      case .association(let association):
        return "URIVariableValueData.association(\(association.debugDescription))"
      }
    }
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: URIVariableValueData - NSCoder
// -------------------------------------------------------------------------- //

extension URIVariableValueData : Codable {
  
  @usableFromInline
  internal typealias CodingKeys = StandardEnumerationCodingKeys
  
  @inlinable
  internal func encode(to encoder: Encoder) throws {
    var container = encoder.container(
      keyedBy: CodingKeys.self
    )
    try container.encode(
      self.valueType,
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
  
  @inlinable
  internal init(from decoder: Decoder) throws {
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
