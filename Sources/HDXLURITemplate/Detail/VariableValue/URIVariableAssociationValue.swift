
// MARK: URIVariableAssociationValue

@usableFromInline
internal struct URIVariableAssociationValue {
  
  @usableFromInline
  internal var storage: [URIVariablePairValue]

  @inlinable
  internal init() {
    self.init(values: [])
  }

  @inlinable
  internal init(value: URIVariablePairValue) {
#if HEAVY_DEBUG
    pedanticAssert(value.isValid)
#endif
    self.init(
      values: [value]
    )
  }

  @inlinable
  internal init(values: [URIVariablePairValue]) {
#if HEAVY_DEBUG
    pedanticAssert(values.allSatisfy(\.isValid))
    defer { pedanticAssert(isValid) }
#endif
    self.storage = values
  }

  @inlinable
  internal init(key: String, value: String) {
    self.init(
      value: URIVariablePairValue(
        key: URIVariableTextValue(rawValue: key),
        value: URIVariableTextValue(rawValue: value)
      )
    )
  }

  @inlinable
  internal init(strings: [(String,String)]) {
    self.init(
      values: strings.map {
        URIVariablePairValue(
          key: URIVariableTextValue(rawValue: $0),
          value: URIVariableTextValue(rawValue: $1)
        )
      }
    )
  }

}

// MARK: - Synthesized Conformances

extension URIVariableAssociationValue: Sendable { }
extension URIVariableAssociationValue: SendableMetatype { }
extension URIVariableAssociationValue: Equatable { }
extension URIVariableAssociationValue: Hashable { }
extension URIVariableAssociationValue: Codable { }

// MARK: - Comparable

extension URIVariableAssociationValue : Comparable {
  
  @inlinable
  internal static func <(
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

// MARK: - CustomStringConvertible

extension URIVariableAssociationValue : CustomStringConvertible {
  
  @usableFromInline
  internal var description: String {
    let variableDescriptions = storage
      .lazy
      .map { String(describing: $0) }
      .joined(separator: ", ")
    
    return "[ \(variableDescriptions) ]"
  }
}

// MARK: - CustomDebugStringConvertible

extension URIVariableAssociationValue : CustomDebugStringConvertible {
  
  @usableFromInline
  internal var debugDescription: String {
    let variableDescriptions = storage
      .lazy
      .map { String(reflecting: $0) }
      .joined(separator: ", ")
    return "URIVariableAssociationValue(values: [ \(variableDescriptions) ])"
  }
}

// MARK: - CustomDebugStringConvertible

extension URIVariableAssociationValue: ExpressibleByArrayLiteral {
  
  @inlinable
  public init(arrayLiteral elements: URIVariablePairValue...) {
    self.init(values: elements)
  }
  
}

// MARK: - Validatable

extension URIVariableAssociationValue {
  
  @inlinable
  internal var isValid: Bool {
    storage.allSatisfy(\.isValid)
    &&
    allKeysAreDistinct
  }
  
  @inlinable
  internal var allKeysAreDistinct: Bool {
    count == Set(
      storage.lazy.map(\.key)
    ).count
  }
  
}

// MARK: - Core API

extension URIVariableAssociationValue {
  
  @inlinable
  internal var isEmpty: Bool {
    storage.isEmpty
  }
  
  @inlinable
  internal var count: Int {
    storage.count
  }
  
  @inlinable
  internal subscript(index: Int) -> URIVariablePairValue {
    storage[index]
  }
  
  @inlinable
  internal subscript(key: String) -> URIVariableTextValue? {
    self[URIVariableTextValue(rawValue: key)]
  }
  
  @inlinable
  internal subscript(key: URIVariableTextValue) -> URIVariableTextValue? {
    storage.first(where: { key == $0.key })?.value
  }
  
  @usableFromInline
  internal var errorMessageRepresentation: String {
    let memberErrorRepresentation = storage.lazy.map { $0.errorMessageRepresentation }.joined(separator: ", ")
    return "[ \(memberErrorRepresentation) ]"
  }

}

