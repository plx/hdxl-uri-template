
// MARK: URIVariableAssociationValue

@usableFromInline
package struct URIVariableAssociationValue {
  
  @usableFromInline
  package var storage: [URIVariablePairValue]

  @inlinable
  internal init() {
    self.init(values: [])
  }

  @inlinable
  package init(value: URIVariablePairValue) {
    self.init(
      values: [value]
    )
  }

  @inlinable
  package init(values: [URIVariablePairValue]) {
    self.storage = values
  }

  @inlinable
  package init(key: String, value: String) {
    self.init(
      value: URIVariablePairValue(
        key: URIVariableTextValue(rawValue: key),
        value: URIVariableTextValue(rawValue: value)
      )
    )
  }

  @inlinable
  package init(strings: [(String,String)]) {
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
extension URIVariableAssociationValue: Equatable { }
extension URIVariableAssociationValue: Hashable { }
extension URIVariableAssociationValue: Codable { }

// MARK: - Comparable

extension URIVariableAssociationValue : Comparable {
  
  @inlinable
  package static func <(
    lhs: URIVariableAssociationValue,
    rhs: URIVariableAssociationValue
  ) -> Bool {
    lhs.storage.lexicographicallyPrecedes(rhs.storage)
  }
  
}

// MARK: - CustomStringConvertible

extension URIVariableAssociationValue : CustomStringConvertible {
  
  @usableFromInline
  package var description: String {
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
  package var debugDescription: String {
    let variableDescriptions = storage
      .lazy
      .map { String(reflecting: $0) }
      .joined(separator: ", ")
    return "URIVariableAssociationValue(values: [ \(variableDescriptions) ])"
  }
}

// MARK: - Validatable

extension URIVariableAssociationValue {
  
  @inlinable
  package var isValid: Bool {
    storage.allSatisfy(\.isValid)
    &&
    allKeysAreDistinct
  }
  
  @inlinable
  package var allKeysAreDistinct: Bool {
    count == Set(
      storage.lazy.map(\.key)
    ).count
  }
  
}

// MARK: - Core API

extension URIVariableAssociationValue {
  
  @inlinable
  package var isEmpty: Bool {
    storage.isEmpty
  }
  
  @inlinable
  package var count: Int {
    storage.count
  }
  
  @inlinable
  package subscript(index: Int) -> URIVariablePairValue {
    storage[index]
  }
  
  @inlinable
  package subscript(key: String) -> URIVariableTextValue? {
    self[URIVariableTextValue(rawValue: key)]
  }
  
  @inlinable
  package subscript(key: URIVariableTextValue) -> URIVariableTextValue? {
    storage.first(where: { key == $0.key })?.value
  }
  
  @usableFromInline
  package var errorMessageRepresentation: String {
    let memberErrorRepresentation = storage.lazy.map { $0.errorMessageRepresentation }.joined(separator: ", ")
    return "[ \(memberErrorRepresentation) ]"
  }

}

