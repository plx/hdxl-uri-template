
// MARK: URIVariablePairValue

/// Represents a single key:value pair of strings--for use within `URIVariableAssociationValue`.
@usableFromInline
package struct URIVariablePairValue {
  
  @usableFromInline
  package var key: URIVariableTextValue
  
  @usableFromInline
  package var value: URIVariableTextValue
  
  @inlinable
  package init(
    key: URIVariableTextValue,
    value: URIVariableTextValue
  ) {
    self.key = key
    self.value = value
  }
  
}

// MARK: - Synthesized Conformances

extension URIVariablePairValue : Sendable { }
extension URIVariablePairValue : Equatable { }
extension URIVariablePairValue : Hashable { }
extension URIVariablePairValue : Codable { }

// MARK: - Comparable

extension URIVariablePairValue : Comparable {
  
  @inlinable
  package static func <(
    lhs: URIVariablePairValue,
    rhs: URIVariablePairValue
  ) -> Bool {
    guard lhs.key == rhs.key else {
      return lhs.key < rhs.key
    }
    
    return lhs.value < rhs.value
  }
  
}

// MARK: - CustomStringConvertible

extension URIVariablePairValue : CustomStringConvertible {
  
  @usableFromInline
  package var description: String {
    "\"\(key.description)\":\"\(value.description)\""
  }
  
}

// MARK: - CustomDebugStringConvertible

extension URIVariablePairValue : CustomDebugStringConvertible {
  
  @usableFromInline
  package var debugDescription: String {
    "URIVariablePairValue(key: \(String(reflecting: key)), value: \(String(reflecting: value)))"
  }
  
}

// MARK: - Validatable

extension URIVariablePairValue {
  
  @inlinable
  package var isValid: Bool {
    key.isValid && value.isValid
  }
  
}

// MARK: - Core API

extension URIVariablePairValue {
  
  @usableFromInline
  package var errorMessageRepresentation: String {
    "\(key.errorMessageRepresentation): \(value.errorMessageRepresentation)"
  }

}
