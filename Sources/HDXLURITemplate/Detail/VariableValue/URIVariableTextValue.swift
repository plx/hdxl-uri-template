import Foundation

// MARK: URIVariableTextValue

/// Represents a flat-string, `.text` variable's value.
/// Implemented (by hand) as a minimal `newtype`-style string wrapper, with the
/// intent being that the constructor *certifies* that the wrapped string is ok.
///
/// For this specific type at this time that check is trivially `true` for any
/// string, but I'll need to re-read the spec to verify that there are, in fact,
/// no actual invariants/constraints/etc. that we need to satisfy here.
@usableFromInline
package struct URIVariableTextValue: RawRepresentable {

  @usableFromInline
  package var rawValue: String
  
  @inlinable
  package init(rawValue: String) {
    self.rawValue = rawValue
  }

}

// MARK: - Synthesized Conformances

extension URIVariableTextValue : Sendable { }
extension URIVariableTextValue : Equatable { }
extension URIVariableTextValue : Hashable { }

// MARK: - Comparable

extension URIVariableTextValue : Comparable {
  
  @inlinable
  package static func <(
    lhs: URIVariableTextValue,
    rhs: URIVariableTextValue
  ) -> Bool {
    lhs.rawValue < rhs.rawValue
  }

}


// MARK: - CustomStringConvertible

extension URIVariableTextValue : CustomStringConvertible {
  
  @usableFromInline
  package var description: String { rawValue }
  
}

// MARK: - CustomDebugStringConvertible

extension URIVariableTextValue : CustomDebugStringConvertible {
  
  @usableFromInline
  package var debugDescription: String {
    "URIVariableTextValue(rawValue: '\(rawValue)')"
  }
  
}

// MARK: - Codable

extension URIVariableTextValue : Codable {
  
  @usableFromInline
  package func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }
  
  @usableFromInline
  package init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()
    self.init(rawValue: try container.decode(String.self))
  }
  
}

// MARK: - Validatable

extension URIVariableTextValue {
  
  @inlinable
  package var isValid: Bool { true }
  
}

// MARK: - Core API

extension URIVariableTextValue {
  
  /// `true` iff we're wrapping an empty string.
  @inlinable
  package var isEmpty: Bool { rawValue.isEmpty }
  
  @usableFromInline
  package var errorMessageRepresentation: String {
    rawValue
  }
  
}

