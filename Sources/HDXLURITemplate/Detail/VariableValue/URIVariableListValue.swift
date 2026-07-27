// -------------------------------------------------------------------------- //
// MARK: URIVariableListValue - Definition
// -------------------------------------------------------------------------- //

internal struct URIVariableListValue {

  internal var storage: [URIVariableTextValue]

  internal init() {
    self.init(
      values: []
    )
  }

  internal init(value: URIVariableTextValue) {
    #if HEAVY_DEBUG
      pedanticAssert(value.isValid)
    #endif
    self.init(
      values: [value]
    )
  }

  internal init(values: [URIVariableTextValue]) {
    #if HEAVY_DEBUG
      pedanticAssert(values.allSatisfy(\.isValid))
      defer { pedanticAssert(isValid) }
    #endif
    self.storage = values
  }

  internal init(string: String) {
    self.init(
      value: URIVariableTextValue(rawValue: string)
    )
  }

  internal init(strings: [String]) {
    self.init(
      values: strings.map { URIVariableTextValue(rawValue: $0) }
    )
  }

}

// -------------------------------------------------------------------------- //
// MARK: - Synthesized Conformances
// -------------------------------------------------------------------------- //

extension URIVariableListValue: Sendable {}
extension URIVariableListValue: Equatable {}
extension URIVariableListValue: Hashable {}

// -------------------------------------------------------------------------- //
// MARK: - Comparable
// -------------------------------------------------------------------------- //

extension URIVariableListValue: Comparable {

  internal static func < (
    lhs: Self,
    rhs: Self
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

extension URIVariableListValue: CustomStringConvertible {

  internal var description: String {
    let values = storage
      .lazy
      .map { "\"\($0.description)\"" }
      .joined(separator: ", ")

    return "[ \(values) ]"
  }

}

// -------------------------------------------------------------------------- //
// MARK: - CustomDebugStringConvertible
// -------------------------------------------------------------------------- //

extension URIVariableListValue: CustomDebugStringConvertible {

  internal var debugDescription: String {
    let values = storage
      .lazy
      .map(\.debugDescription)
      .joined(separator: ", ")
    return "URIVariableListValue(values: [ \(values) ])"
  }
}

// -------------------------------------------------------------------------- //
// MARK: - Expressible
// -------------------------------------------------------------------------- //

extension URIVariableListValue: ExpressibleByArrayLiteral {

  internal init(arrayLiteral elements: URIVariableTextValue...) {
    self.init(values: elements)
  }
}

// -------------------------------------------------------------------------- //
// MARK: - Validatable
// -------------------------------------------------------------------------- //

extension URIVariableListValue {

  internal var isValid: Bool {
    storage.allSatisfy(\.isValid)
  }

}

// -------------------------------------------------------------------------- //
// MARK: - Core API
// -------------------------------------------------------------------------- //

extension URIVariableListValue {

  internal var isEmpty: Bool {
    storage.isEmpty
  }

  internal var count: Int {
    storage.count
  }

  internal subscript(index: Int) -> URIVariableTextValue {
    storage[index]
  }

}
