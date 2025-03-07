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
internal struct URIVariableTextValue {

  @usableFromInline
  internal var storage: String
  
  @inlinable
  internal init(text: String) {
#if HEAVY_DEBUG
    defer { pedanticAssert(isValid) }
#endif
    self.storage = text
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
    return lhs.storage < rhs.storage
  }

}


// -------------------------------------------------------------------------- //
// MARK: - CustomStringConvertible
// -------------------------------------------------------------------------- //

extension URIVariableTextValue : CustomStringConvertible {
  
  @usableFromInline
  internal var description: String { storage }
  
}

// -------------------------------------------------------------------------- //
// MARK: - CustomDebugStringConvertible
// -------------------------------------------------------------------------- //

extension URIVariableTextValue : CustomDebugStringConvertible {
  
  @usableFromInline
  internal var debugDescription: String {
    "URIVariableTextValue(text: '\(storage)')"
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: - Codable
// -------------------------------------------------------------------------- //

extension URIVariableTextValue : Codable {
  
  @usableFromInline
  internal func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(storage)
  }
  
  @usableFromInline
  internal init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()
    self.init(text: try container.decode(String.self))
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
  
  /// Extracts `self.storage` as a `String`.
  /// May get eliminated now that `URIVariableTextValue` is package-internal.
  @inlinable
  internal var asString: String {
    storage
  }
  
  /// `true` iff we're wrapping an empty string.
  @inlinable
  internal var isEmpty: Bool {
    storage.isEmpty
  }
  
}

