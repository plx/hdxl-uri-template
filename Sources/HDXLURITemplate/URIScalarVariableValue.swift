import Foundation

// MARK: URIScalarVariableValue

/// A lightweight wrapper for single text values, used primarily in array and dictionary literals.
///
/// This type serves as the element type for `URIVariableValue`'s `ExpressibleByArrayLiteral`
/// and dictionary literal conformances, enabling concise syntax like `["a", "b", "c"]` for lists
/// and `["key": "value"]` for associations.
public struct URIScalarVariableValue {
  
  // MARK: - Primary Properties
  
  /// Shorthand for the wrapped data-storage type.
  @usableFromInline
  package typealias Storage = URIVariableTextValue
  
  /// Holds the actual variable value.
  @usableFromInline
  package var storage: Storage
  
  // MARK: - Designated Initializer
  
  /// Designated internal-use-only initializer.
  @inlinable
  package init(storage: Storage) {
    self.storage = storage
  }
  
  // MARK: - Public Constructors
  
  /// Constructs a scalar value wrapping `text`.
  ///
  /// - Parameter text: The string value to wrap.
  ///
  /// - Returns: A scalar value containing the text.
  @inlinable
  public static func text(_ text: String) -> Self {
    Self(
      storage: Storage(rawValue: text)
    )
  }
    
}

// MARK: - Synthesized Conformances

extension URIScalarVariableValue : Sendable { }
extension URIScalarVariableValue : Equatable { }
extension URIScalarVariableValue : Hashable { }

// MARK: - Comparable

extension URIScalarVariableValue : Comparable {

  @inlinable
  public static func <(
    lhs: URIScalarVariableValue,
    rhs: URIScalarVariableValue
  ) -> Bool {
    lhs.storage < rhs.storage
  }

}

// MARK: - CustomStringConvertible

extension URIScalarVariableValue : CustomStringConvertible {

  @inlinable
  public var description: String {
    storage.description
  }

}

// MARK: - CustomDebugStringConvertible

extension URIScalarVariableValue : CustomDebugStringConvertible {

  @inlinable
  public var debugDescription: String {
    "URIVariableValue(storage: \(storage.debugDescription))"
  }

}

// MARK: - Codable

extension URIScalarVariableValue : Codable {

  /// Encodes this value into the given encoder.
  ///
  /// - Parameter encoder: The encoder to write data to.
  ///
  /// - Throws: An error if encoding fails.
  @inlinable
  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(storage)
  }

  /// Creates a new instance by decoding from the given decoder.
  ///
  /// - Parameter decoder: The decoder to read data from.
  ///
  /// - Throws: An error if decoding fails.
  @inlinable
  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    let storage = try container.decode(Storage.self)
    self.init(storage: storage)
  }

}

extension URIScalarVariableValue: ExpressibleByIntegerLiteral {

  /// The integer literal type for initialization.
  public typealias IntegerLiteralType = Int

  /// Creates a text-flavored value from an integer literal.
  ///
  /// - Parameter value: The integer value to convert to text.
  public init(integerLiteral value: IntegerLiteralType) {
    self.init(
      storage: URIVariableTextValue(rawValue: "\(value)")
    )
  }
}

extension URIScalarVariableValue: ExpressibleByFloatLiteral {

  /// The floating-point literal type for initialization.
  public typealias FloatLiteralType = Double

  /// Creates a text-flavored value from a floating-point literal.
  ///
  /// - Parameter value: The floating-point value to convert to text.
  public init(floatLiteral value: FloatLiteralType) {
    self.init(
      storage: URIVariableTextValue(rawValue: "\(value)")
    )
  }
}

extension URIScalarVariableValue: ExpressibleByUnicodeScalarLiteral {
  
  /// A type that represents a Unicode scalar literal.
  ///
  /// Valid types for `UnicodeScalarLiteralType` are `Unicode.Scalar`,
  /// `Character`, `String`, and `StaticString`.
  public typealias UnicodeScalarLiteralType = Unicode.Scalar
  
  /// Creates an instance initialized to the given value.
  ///
  /// - Parameter value: The value of the new instance.
  public init(unicodeScalarLiteral value: UnicodeScalarLiteralType) {
    self.init(
      storage: URIVariableTextValue(rawValue: String(value))
    )
  }

}

extension URIScalarVariableValue: ExpressibleByExtendedGraphemeClusterLiteral {
  
  /// A type that represents a Unicode scalar literal.
  ///
  /// Valid types for `UnicodeScalarLiteralType` are `Unicode.Scalar`,
  /// `Character`, `String`, and `StaticString`.
  public typealias ExtendedGraphemeClusterLiteralType = Character
  
  /// Creates an instance initialized to the given value.
  ///
  /// - Parameter value: The value of the new instance.
  public init(extendedGraphemeClusterLiteral value: ExtendedGraphemeClusterLiteralType) {
    self.init(
      storage: URIVariableTextValue(rawValue: String(value))
    )
  }
  
}

extension URIScalarVariableValue: ExpressibleByStringLiteral {
  
  /// A type that represents a Unicode scalar literal.
  ///
  /// Valid types for `UnicodeScalarLiteralType` are `Unicode.Scalar`,
  /// `Character`, `String`, and `StaticString`.
  public typealias StringLiteralType = String
  
  /// Creates an instance initialized to the given value.
  ///
  /// - Parameter value: The value of the new instance.
  public init(stringLiteral value: String) {
    self.init(
      storage: URIVariableTextValue(rawValue: String(value))
    )
  }
  
}

// MARK: - Core API

extension URIScalarVariableValue {
  
  /// `true` iff this value counts as *empty*.
  ///
  /// - `.undefined`: always *empty*
  /// - `.text`: is *empty* when the underlying string is empty
  /// - `.list`: is *empty* when the underlying list is empty
  /// - `.association`: is *empty* when the underlying association is empty
  ///
  /// This is a superficial emptiness, and e.g. `[""]` and `[("","")]` (etc.) aren't empty.
  ///
  @inlinable
  public var isEmpty: Bool {
    storage.isEmpty
  }
      
  @usableFromInline
  package var errorMessageRepresentation: String {
    storage.errorMessageRepresentation
  }
  
}

// MARK: - Validatable

extension URIScalarVariableValue {
  
  @inlinable
  internal var isValid: Bool {
    storage.isValid
  }
  
}
