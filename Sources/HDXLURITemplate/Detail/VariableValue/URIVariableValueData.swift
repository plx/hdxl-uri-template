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
internal enum URIVariableValueData {

  case undefined
  case text(URIVariableTextValue)
  case list(URIVariableListValue)
  case association(URIVariableAssociationValue)

  internal static let emptyList: URIVariableValueData = .list(URIVariableListValue())

  internal static let emptyAssociation: URIVariableValueData = .association(
    URIVariableAssociationValue()
  )

  internal init(from text: String) {
    #if HEAVY_DEBUG
      defer { pedanticAssert(isValid) }
    #endif
    self = .text(
      URIVariableTextValue(rawValue: text)
    )
  }

  internal init<S: Sequence>(from texts: S) where S.Element == String {
    #if HEAVY_DEBUG
      defer { pedanticAssert(isValid) }
    #endif
    self = .list(
      URIVariableListValue(
        values: texts.map {
          URIVariableTextValue(rawValue: $0)
        }
      )
    )
  }

  internal init(singleElementListFrom text: String) {
    #if HEAVY_DEBUG
      defer { pedanticAssert(isValid) }
    #endif
    self = .list(
      URIVariableListValue(
        value: URIVariableTextValue(rawValue: text)
      )
    )
  }

  internal init(from pair: (String, String)) {
    #if HEAVY_DEBUG
      defer { pedanticAssert(isValid) }
    #endif
    self = .association(
      URIVariableAssociationValue(
        value: URIVariablePairValue(
          key: URIVariableTextValue(rawValue: pair.0),
          value: URIVariableTextValue(rawValue: pair.1)
        )
      )
    )
  }

  internal init<S: Sequence>(
    validating pairs: S
  ) throws where S.Element == (String, String) {
    self = .association(
      try URIVariableAssociationValue(
        validatingStrings: pairs
      )
    )
    #if HEAVY_DEBUG
      pedanticAssert(isValid)
    #endif
  }

  internal init(
    dictionary: [String: String],
    orderingKeysWith areInIncreasingOrder: (String, String) -> Bool
  ) {
    self = .association(
      URIVariableAssociationValue(
        dictionary: dictionary,
        orderingKeysWith: areInIncreasingOrder
      )
    )
    #if HEAVY_DEBUG
      pedanticAssert(isValid)
    #endif
  }

}

// -------------------------------------------------------------------------- //
// MARK: - Synthesized Conformances
// -------------------------------------------------------------------------- //

extension URIVariableValueData: Sendable {}
extension URIVariableValueData: Equatable {}
extension URIVariableValueData: Hashable {}

// -------------------------------------------------------------------------- //
// MARK: URIVariableValueData - CustomStringConvertible
// -------------------------------------------------------------------------- //

extension URIVariableValueData: CustomStringConvertible {

  internal var description: String {
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

// -------------------------------------------------------------------------- //
// MARK: URIVariableValueData - CustomDebugStringConvertible
// -------------------------------------------------------------------------- //

extension URIVariableValueData: CustomDebugStringConvertible {

  internal var debugDescription: String {
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

// -------------------------------------------------------------------------- //
// MARK: URIVariableValueData - Core API
// -------------------------------------------------------------------------- //

extension URIVariableValueData {

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

  internal var isUndefinedValue: Bool {
    switch self {
    case .undefined:
      true
    default:
      false
    }
  }

  internal var isTextValue: Bool {
    switch self {
    case .text(_):
      true
    default:
      false
    }
  }

  internal var isListValue: Bool {
    switch self {
    case .list(_):
      true
    default:
      false
    }
  }

  internal var isAssociationValue: Bool {
    switch self {
    case .association(_):
      true
    default:
      false
    }
  }

}

// -------------------------------------------------------------------------- //
// MARK: - Validatable
// -------------------------------------------------------------------------- //

extension URIVariableValueData {

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
