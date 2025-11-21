import Foundation

// MARK: URIVariableValue

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
  
  /// Constructs a `.text`-flavored `URIVariableValue` wrapping `text`.
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
  
  @inlinable
  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(storage)
  }
  
  @inlinable
  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    let storage = try container.decode(Storage.self)
    self.init(storage: storage)
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
