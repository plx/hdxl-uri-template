import Foundation

// MARK: URIVariableListValue

@usableFromInline
package struct URIVariableListValue {
  
  @usableFromInline
  package var storage: [URIVariableTextValue]
  
  @inlinable
  package init() {
    self.init(
      values: []
    )
  }

  @inlinable
  package init(value: URIVariableTextValue) {
    self.init(
      values: [value]
    )
  }

  @inlinable
  package init(values: [URIVariableTextValue]) {
    self.storage = values
  }

  @inlinable
  package init(string: String) {
    self.init(
      value: URIVariableTextValue(rawValue: string)
    )
  }

  @inlinable
  package init(strings: [String]) {
    self.init(
      values: strings.map { URIVariableTextValue(rawValue: $0)}
    )
  }

}

// MARK: - Synthesized Conformances

extension URIVariableListValue: Sendable { }
extension URIVariableListValue: Equatable { }
extension URIVariableListValue: Hashable { }

// MARK: - Comparable

extension URIVariableListValue : Comparable {
  
  @inlinable
  package static func <(
    lhs: Self,
    rhs: Self
  ) -> Bool {
    lhs.storage.lexicographicallyPrecedes(rhs.storage)
  }
  
}

// MARK: - CustomStringConvertible

extension URIVariableListValue : CustomStringConvertible {
  
  @usableFromInline
  package var description: String {
    let values = storage
      .lazy
      .map(\.description)
      .joined(separator: ", ")
    
    return "[ \(values) ]"
  }
  
}

// MARK: - CustomDebugStringConvertible

extension URIVariableListValue : CustomDebugStringConvertible {
  
  @usableFromInline
  package var debugDescription: String {
    let values = storage
      .lazy
      .map(\.debugDescription)
      .joined(separator: ", ")
    return "URIVariableListValue(values: [ \(values) ])"
  }
}

// MARK: - Codable

extension URIVariableListValue : Codable {

  @usableFromInline
  package func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(storage)
  }
  
  @usableFromInline
  package init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()
    self.init(values: try container.decode([URIVariableTextValue].self))
  }
  
}

// MARK: - Validatable

extension URIVariableListValue {
  
  @inlinable
  internal var isValid: Bool {
    storage.allSatisfy(\.isValid)
  }
  
}

// MARK: - Core API

extension URIVariableListValue {
  
  @inlinable
  package var isEmpty: Bool {
    storage.isEmpty
  }
  
  @inlinable
  package var count: Int {
    storage.count
  }
  
  @inlinable
  package subscript(index: Int) -> URIVariableTextValue {
    storage[index]
  }
  
  @usableFromInline
  package var errorMessageRepresentation: String {
    let memberErrorRepresentation = storage.lazy.map { $0.errorMessageRepresentation }.joined(separator: ", ")
    return "[ \(memberErrorRepresentation) ]"
  }
  
}

