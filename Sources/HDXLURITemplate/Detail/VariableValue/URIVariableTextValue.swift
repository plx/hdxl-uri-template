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
internal struct URIVariableTextValue: RawRepresentable {

  internal var rawValue: String

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

extension URIVariableTextValue: Sendable {}
extension URIVariableTextValue: Equatable {}
extension URIVariableTextValue: Hashable {}

// -------------------------------------------------------------------------- //
// MARK: - Comparable
// -------------------------------------------------------------------------- //

extension URIVariableTextValue: Comparable {

  internal static func < (
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

extension URIVariableTextValue: CustomStringConvertible {

  internal var description: String { rawValue }

}

// -------------------------------------------------------------------------- //
// MARK: - CustomDebugStringConvertible
// -------------------------------------------------------------------------- //

extension URIVariableTextValue: CustomDebugStringConvertible {

  internal var debugDescription: String {
    "URIVariableTextValue(rawValue: '\(rawValue)')"
  }

}

// -------------------------------------------------------------------------- //
// MARK: - Expressible
// -------------------------------------------------------------------------- //

extension URIVariableTextValue: ExpressibleByStringLiteral {
  typealias ExtendedGraphemeClusterLiteralType = String.ExtendedGraphemeClusterLiteralType

  typealias StringLiteralType = String.StringLiteralType

  internal init(unicodeScalarLiteral value: ExtendedGraphemeClusterLiteralType) {
    self.init(rawValue: String(value))
    precondition(isValid)
  }

  internal init(extendedGraphemeClusterLiteral value: ExtendedGraphemeClusterLiteralType) {
    self.init(rawValue: String(value))
    precondition(isValid)
  }

  internal init(stringLiteral value: StringLiteralType) {
    self.init(rawValue: String(value))
    precondition(isValid)
  }
}

// -------------------------------------------------------------------------- //
// MARK: - Validatable
// -------------------------------------------------------------------------- //

extension URIVariableTextValue {

  internal var isValid: Bool { true }

}

// -------------------------------------------------------------------------- //
// MARK: URIVariableTextValue - Core API
// -------------------------------------------------------------------------- //

extension URIVariableTextValue {

  /// `true` iff we're wrapping an empty string.
  internal var isEmpty: Bool { rawValue.isEmpty }

}
