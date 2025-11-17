import Foundation

// -------------------------------------------------------------------------- //
// MARK: URIVariableListValue - Definition
// -------------------------------------------------------------------------- //

@usableFromInline
internal struct URIVariableListValue {
  
  @usableFromInline
  internal var storage: [URIVariableTextValue]
  
  @inlinable
  internal init() {
    self.init(
      values: []
    )
  }

  @inlinable
  internal init(value: URIVariableTextValue) {
#if HEAVY_DEBUG
    pedanticAssert(value.isValid)
#endif
    self.init(
      values: [value]
    )
  }

  @inlinable
  internal init(values: [URIVariableTextValue]) {
#if HEAVY_DEBUG
    pedanticAssert(values.allSatisfy(\.isValid))
    defer { pedanticAssert(isValid)}
#endif
    self.storage = values
  }

  @inlinable
  internal init(string: String) {
    self.init(
      value: URIVariableTextValue(rawValue: string)
    )
  }

  @inlinable
  internal init(strings: [String]) {
    self.init(
      values: strings.map { URIVariableTextValue(rawValue: $0)}
    )
  }

}

// -------------------------------------------------------------------------- //
// MARK: - Synthesized Conformances
// -------------------------------------------------------------------------- //

extension URIVariableListValue: Sendable { }
extension URIVariableListValue: Equatable { }
extension URIVariableListValue: Hashable { }

// -------------------------------------------------------------------------- //
// MARK: - Comparable
// -------------------------------------------------------------------------- //

extension URIVariableListValue : Comparable {
  
  @inlinable
  internal static func <(
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

extension URIVariableListValue : CustomStringConvertible {
  
  @usableFromInline
  internal var description: String {
    let values = storage
      .lazy
      .map(\.description)
      .joined(separator: ", ")
    
    return "[ \(values) ]"
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: - CustomDebugStringConvertible
// -------------------------------------------------------------------------- //

extension URIVariableListValue : CustomDebugStringConvertible {
  
  @usableFromInline
  internal var debugDescription: String {
    let values = storage
      .lazy
      .map(\.debugDescription)
      .joined(separator: ", ")
    return "URIVariableListValue(values: [ \(values) ])"
  }
}

// -------------------------------------------------------------------------- //
// MARK: - Codable
// -------------------------------------------------------------------------- //

extension URIVariableListValue : Codable {

  @usableFromInline
  internal func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(storage)
  }
  
  @usableFromInline
  internal init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()
    self.init(values: try container.decode([URIVariableTextValue].self))
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: - Expressible
// -------------------------------------------------------------------------- //

extension URIVariableListValue : ExpressibleByArrayLiteral {
  
  @inlinable
  internal init(arrayLiteral elements: URIVariableTextValue...) {
    self.init(values: elements)
  }
}

// -------------------------------------------------------------------------- //
// MARK: - Validatable
// -------------------------------------------------------------------------- //

extension URIVariableListValue {
  
  @inlinable
  internal var isValid: Bool {
    storage.allSatisfy(\.isValid)
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: - Core API
// -------------------------------------------------------------------------- //

extension URIVariableListValue {
  
  @inlinable
  internal var isEmpty: Bool {
    storage.isEmpty
  }
  
  @inlinable
  internal var count: Int {
    storage.count
  }
  
  @inlinable
  internal subscript(index: Int) -> URIVariableTextValue {
    storage[index]
  }
  
  @usableFromInline
  internal var errorMessageRepresentation: String {
    let memberErrorRepresentation = storage.lazy.map { $0.errorMessageRepresentation }.joined(separator: ", ")
    return "[ \(memberErrorRepresentation) ]"
  }
  
}

