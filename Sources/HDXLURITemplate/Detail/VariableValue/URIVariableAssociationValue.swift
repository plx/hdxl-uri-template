// -------------------------------------------------------------------------- //
// MARK: URIVariableAssociationValue - Definition
// -------------------------------------------------------------------------- //

internal struct URIVariableAssociationValue {

  internal let storage: [URIVariablePairValue]

  internal init() {
    self.storage = []
  }

  internal init(value: URIVariablePairValue) {
    #if HEAVY_DEBUG
      pedanticAssert(value.isValid)
    #endif
    self.storage = [value]
  }

  internal init<Values>(
    validating values: Values
  ) throws
  where
    Values: Sequence,
    Values.Element == URIVariablePairValue
  {
    var storage: [URIVariablePairValue] = []
    storage.reserveCapacity(values.underestimatedCount)

    var firstIndicesByKey: [URIVariableTextValue: Int] = [:]
    firstIndicesByKey.reserveCapacity(values.underestimatedCount)

    for (index, value) in values.enumerated() {
      #if HEAVY_DEBUG
        pedanticAssert(value.isValid)
      #endif
      if let firstIndex = firstIndicesByKey[value.key] {
        throw URIVariableValue.AssociationError.duplicateKey(
          firstIndex: firstIndex,
          duplicateIndex: index
        )
      }
      firstIndicesByKey[value.key] = index
      storage.append(value)
    }

    self.storage = storage
    #if HEAVY_DEBUG
      pedanticAssert(isValid)
    #endif
  }

  internal init(key: String, value: String) {
    self.init(
      value: URIVariablePairValue(
        key: URIVariableTextValue(rawValue: key),
        value: URIVariableTextValue(rawValue: value)
      )
    )
  }

  internal init<Strings>(
    validatingStrings strings: Strings
  ) throws
  where
    Strings: Sequence,
    Strings.Element == (String, String)
  {
    try self.init(
      validating: strings.lazy.map {
        URIVariablePairValue(
          key: URIVariableTextValue(rawValue: $0),
          value: URIVariableTextValue(rawValue: $1)
        )
      }
    )
  }

  internal init(
    dictionary: [String: String],
    orderingKeysWith areInIncreasingOrder: (String, String) -> Bool
  ) {
    self.storage =
      dictionary
      .sorted { lhs, rhs in
        let lhsPrecedesRhs = areInIncreasingOrder(lhs.key, rhs.key)
        let rhsPrecedesLhs = areInIncreasingOrder(rhs.key, lhs.key)
        return switch (lhsPrecedesRhs, rhsPrecedesLhs) {
        case (true, false):
          true
        case (false, true):
          false
        default:
          lhs.key < rhs.key
        }
      }
      .map {
        URIVariablePairValue(
          key: URIVariableTextValue(rawValue: $0.key),
          value: URIVariableTextValue(rawValue: $0.value)
        )
      }
    #if HEAVY_DEBUG
      pedanticAssert(isValid)
    #endif
  }

}

// -------------------------------------------------------------------------- //
// MARK: - Synthesized Conformances
// -------------------------------------------------------------------------- //

extension URIVariableAssociationValue: Sendable {}
extension URIVariableAssociationValue: Equatable {}
extension URIVariableAssociationValue: Hashable {}

// -------------------------------------------------------------------------- //
// MARK: URIVariableAssociationValue - Comparable
// -------------------------------------------------------------------------- //

extension URIVariableAssociationValue: Comparable {

  internal static func < (
    lhs: URIVariableAssociationValue,
    rhs: URIVariableAssociationValue
  ) -> Bool {
    #if HEAVY_DEBUG
      pedanticAssert(lhs.isValid)
      pedanticAssert(rhs.isValid)
    #endif
    return lhs.storage.lexicographicallyPrecedes(rhs.storage)
  }

}

// -------------------------------------------------------------------------- //
// MARK: - CustomStringConvertible
// -------------------------------------------------------------------------- //

extension URIVariableAssociationValue: CustomStringConvertible {

  internal var description: String {
    let variableDescriptions = storage
      .lazy
      .map { String(describing: $0) }
      .joined(separator: ", ")

    return "[ \(variableDescriptions) ]"
  }
}

// -------------------------------------------------------------------------- //
// MARK: - CustomDebugStringConvertible
// -------------------------------------------------------------------------- //

extension URIVariableAssociationValue: CustomDebugStringConvertible {

  internal var debugDescription: String {
    let variableDescriptions = storage
      .lazy
      .map { String(reflecting: $0) }
      .joined(separator: ", ")
    return "URIVariableAssociationValue(values: [ \(variableDescriptions) ])"
  }
}

// -------------------------------------------------------------------------- //
// MARK: - Validatable
// -------------------------------------------------------------------------- //

extension URIVariableAssociationValue {

  internal var isValid: Bool {
    storage.allSatisfy(\.isValid)
      && allKeysAreDistinct
  }

  internal var allKeysAreDistinct: Bool {
    count
      == Set(
        storage.lazy.map(\.key)
      ).count
  }

}

// -------------------------------------------------------------------------- //
// MARK: - Core API
// -------------------------------------------------------------------------- //

extension URIVariableAssociationValue {

  internal var isEmpty: Bool {
    storage.isEmpty
  }

  internal var count: Int {
    storage.count
  }

  internal subscript(index: Int) -> URIVariablePairValue {
    storage[index]
  }

  internal subscript(key: String) -> URIVariableTextValue? {
    self[URIVariableTextValue(rawValue: key)]
  }

  internal subscript(key: URIVariableTextValue) -> URIVariableTextValue? {
    storage.first(where: { key == $0.key })?.value
  }

}
