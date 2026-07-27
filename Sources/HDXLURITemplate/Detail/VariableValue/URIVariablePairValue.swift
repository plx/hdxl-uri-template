
// -------------------------------------------------------------------------- //
// MARK: URIVariablePairValue - Definition
// -------------------------------------------------------------------------- //

/// Represents a single key:value pair of strings--for use within `URIVariableAssociationValue`.
@usableFromInline
internal struct URIVariablePairValue {
  
  @usableFromInline
  internal var key: URIVariableTextValue
  
  @usableFromInline
  internal var value: URIVariableTextValue
  
  @inlinable
  internal init(
    key: URIVariableTextValue,
    value: URIVariableTextValue
  ) {
#if HEAVY_DEBUG
    pedanticAssert(key.isValid)
    pedanticAssert(value.isValid)
    defer { pedanticAssert(isValid) }
#endif
    self.key = key
    self.value = value
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: - Synthesized Conformances
// -------------------------------------------------------------------------- //

extension URIVariablePairValue : Sendable { }
extension URIVariablePairValue : Equatable { }
extension URIVariablePairValue : Hashable { }
extension URIVariablePairValue : Codable { }

// -------------------------------------------------------------------------- //
// MARK: - Comparable
// -------------------------------------------------------------------------- //

extension URIVariablePairValue : Comparable {
  
  @inlinable
  internal static func <(
    lhs: URIVariablePairValue,
    rhs: URIVariablePairValue
  ) -> Bool {
#if HEAVY_DEBUG
    pedanticAssert(lhs.isValid)
    pedanticAssert(rhs.isValid)
#endif
    guard lhs.key == rhs.key else {
      return lhs.key < rhs.key
    }
    
    return lhs.value < rhs.value
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: - CustomStringConvertible
// -------------------------------------------------------------------------- //

extension URIVariablePairValue : CustomStringConvertible {
  
  @usableFromInline
  internal var description: String {
    "\"\(key.description)\":\"\(value.description)\""
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: - CustomDebugStringConvertible
// -------------------------------------------------------------------------- //

extension URIVariablePairValue : CustomDebugStringConvertible {
  
  @usableFromInline
  internal var debugDescription: String {
    "URIVariablePairValue(key: \(String(reflecting: key)), value: \(String(reflecting: value)))"
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: - ExpressibleByArrayLiteral
// -------------------------------------------------------------------------- //

extension URIVariablePairValue : ExpressibleByArrayLiteral {
  
  @inlinable
  internal init(arrayLiteral elements: URIVariableTextValue...) {
    precondition(elements.count == 2)
    self.init(
      key: elements[0],
      value: elements[1]
    )
  }
  
}


// -------------------------------------------------------------------------- //
// MARK: - Validatable
// -------------------------------------------------------------------------- //

extension URIVariablePairValue {
  
  @inlinable
  internal var isValid: Bool {
    key.isValid && value.isValid
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: - Core API
// -------------------------------------------------------------------------- //
