import Foundation
// TODO: RawRepresentable

// -------------------------------------------------------------------------- //
// MARK: URIVariableTextValue - Definition
// -------------------------------------------------------------------------- //

/// Represents a flat-string, `.text` variable's value.
/// Implemented (by hand) as a minimal `newtype`-style string wrapper, with the
/// intent being that the constructor *certifies* that the wrapped string is ok.
///
/// For this specific type at this time that check is trivially `true` for any
/// string, but I'll need to re-read the spec to verify that there are, in fact,
/// no actual invariants/constraints/etc. that we need to satisfy here.
@usableFromInline
internal struct URIVariableTextValue: RawRepresentable {

  @usableFromInline
  internal var rawValue: String
  
  @inlinable
  internal init(rawValue: String) {
#if HEAVY_DEBUG
    defer { pedanticAssert(isValid) }
#endif
    self.rawValue = rawValue
  }

}

// -------------------------------------------------------------------------- //
// MARK: - Synthesized Conformances
// -------------------------------------------------------------------------- //

extension URIVariableTextValue : Sendable { }
extension URIVariableTextValue : Equatable { }
extension URIVariableTextValue : Hashable { }

// -------------------------------------------------------------------------- //
// MARK: - Comparable
// -------------------------------------------------------------------------- //

extension URIVariableTextValue : Comparable {
  
  @inlinable
  internal static func <(
    lhs: URIVariableTextValue,
    rhs: URIVariableTextValue
  ) -> Bool {
#if HEAVY_DEBUG
    pedanticAssert(lhs.isValid)
    pedanticAssert(rhs.isValid)
#endif
    return lhs.rawValue < rhs.rawValue
  }

}


// -------------------------------------------------------------------------- //
// MARK: - CustomStringConvertible
// -------------------------------------------------------------------------- //

extension URIVariableTextValue : CustomStringConvertible {
  
  @usableFromInline
  internal var description: String { rawValue }
  
}

// -------------------------------------------------------------------------- //
// MARK: - CustomDebugStringConvertible
// -------------------------------------------------------------------------- //

extension URIVariableTextValue : CustomDebugStringConvertible {
  
  @usableFromInline
  internal var debugDescription: String {
    "URIVariableTextValue(rawValue: '\(rawValue)')"
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: - Codable
// -------------------------------------------------------------------------- //

extension URIVariableTextValue : Codable {
  
  @usableFromInline
  internal func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }
  
  @usableFromInline
  internal init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()
    self.init(rawValue: try container.decode(String.self))
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: - Expressible
// -------------------------------------------------------------------------- //

extension URIVariableTextValue : ExpressibleByStringLiteral {
  @usableFromInline
  typealias ExtendedGraphemeClusterLiteralType = String.ExtendedGraphemeClusterLiteralType
  
  @usableFromInline
  typealias StringLiteralType = String.StringLiteralType
  
  @inlinable
  internal init(unicodeScalarLiteral value: ExtendedGraphemeClusterLiteralType) {
    self.init(rawValue: String(value))
    precondition(isValid)
  }
  
  @inlinable
  internal init(extendedGraphemeClusterLiteral value: ExtendedGraphemeClusterLiteralType) {
    self.init(rawValue: String(value))
    precondition(isValid)
  }
  
  @inlinable
  internal init(stringLiteral value: StringLiteralType) {
    self.init(rawValue: String(value))
    precondition(isValid)
  }
}

// -------------------------------------------------------------------------- //
// MARK: - Validatable
// -------------------------------------------------------------------------- //

extension URIVariableTextValue {
  
  @inlinable
  internal var isValid: Bool { true }
  
}

// -------------------------------------------------------------------------- //
// MARK: URIVariableTextValue - Core API
// -------------------------------------------------------------------------- //

extension URIVariableTextValue {
  
  /// `true` iff we're wrapping an empty string.
  @inlinable
  internal var isEmpty: Bool { rawValue.isEmpty }
  
}
