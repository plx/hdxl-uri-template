import Foundation

// MARK: URIVariableValue

/// Represents a value intended to be substituted into a URI template variable.
///
/// Values come in four flavors:
///
/// - `undefined`: an *explicit* `nil`-like value
/// - `text`: a simple string
/// - `list`: a list of strings
/// - `association`: an *ordered* list of key-value pairs of strings
///
/// ...and the public API has (a) constructors for each of those types as well
/// as (b) some very-limited inspection (you can verify the value's flavor).
///
/// In other words, the public API is write-mostly, and that's by design: the internals make *heavy* use of `newtype`-like wrapper structs, and I'd like to *keep* those `internal`.
/// Sure, the write-mostly API also limits the potential for misuse, but that's a fringe benefit--it's really about keeping the `newtype`s out of the public-facing API.
///
/// - note: This conforms to `Comparable`, but the sort is *structural* (by flavor, then content) rather than "semantic" (e.g. by textual representation).
/// - note: When deserializing this throws `DataValidationError` if the deserialized value is somehow invalid. That error gives you a chance to "repair" the value in some circumstances.
///
public struct URIVariableValue {

  // MARK: - Primary Properties
  
  /// Shorthand for the wrapped data-storage type.
  @usableFromInline
  package typealias Storage = URIVariableValueData
  
  /// Holds the actual variable value.
  @usableFromInline
  package var storage: URIVariableValueData

  // MARK: - Designated Initializer
  
  /// Designated internal-use-only initializer.
  @inlinable
  package init(storage: URIVariableValueData) {
    self.storage = storage
  }
  
  // MARK: - Well-Known Values
    
  /// Convenience for the undefined `URIVariableValue`.
  public static let undefined: URIVariableValue = URIVariableValue(storage: .undefined)
  
  /// Convenience for the empty-string `URIVariableValue`.
  public static let emptyString: URIVariableValue = URIVariableValue(storage: .text(URIVariableTextValue(rawValue: "")))
  
  /// Convenience for the empty-list `URIVariableValue`.
  public static let emptyList: URIVariableValue = URIVariableValue(storage: .emptyList)
  
  /// Convenience for the empty-assocication `URIVariableValue`.
  public static let emptyAssociation: URIVariableValue = URIVariableValue(storage: .emptyAssociation)

  // MARK: - Public Constructors      

  /// Constructs a `.text`-flavored `URIVariableValue` wrapping `text`.
  @inlinable
  public static func text(_ text: String) -> Self {
    Self(
      storage: Storage(from: text)
    )
  }

  /// Controls capitalization of boolean text representations.
  @objc(URIVariableValueBooleanCapitalization)
  public enum BooleanCapitalization: Int {
    /// Lowercase representation (e.g., "true", "false").
    case lowercase
    /// Capitalized representation (e.g., "True", "False").
    case capitalized
    /// All-caps representation (e.g., "TRUE", "FALSE").
    case allCaps
  }
  
  /// Constructs a `.text`-flavored `URIVariableValue` representing `boolValue` as `trueRepresentation` or `falseRepresentation`.
  ///
  /// - Parameters:
  ///   - boolValue: The boolean value to represent.
  ///   - capitalization: The capitalization style to apply.
  ///   - trueRepresentation: The string to use when `boolValue` is `true`.
  ///   - falseRepresentation: The string to use when `boolValue` is `false`.
  ///
  /// - Returns: A text-flavored value with the appropriate representation.
  @inlinable
  public static func boolean(
    _ boolValue: Bool,
    capitalization: BooleanCapitalization = .lowercase,
    ifTrue trueRepresentation: @autoclosure () -> String,
    ifFalse falseRepresentation: @autoclosure () -> String
  ) -> Self {
    let textRepresentation = switch boolValue {
    case true:
      trueRepresentation()
    case false:
      falseRepresentation()
    }
    
    let adjustedTextRepresentation = switch capitalization {
    case .lowercase:
      textRepresentation
    case .capitalized:
      textRepresentation.capitalized
    case .allCaps:
      textRepresentation.uppercased()
    }
    
    return text(adjustedTextRepresentation)
  }

  /// Constructs a `.text`-flavored `URIVariableValue` representing `boolValue` as `true` or `false`.
  ///
  /// - Parameters:
  ///   - boolValue: The boolean value to represent.
  ///   - capitalization: The capitalization style to apply.
  ///
  /// - Returns: A text-flavored value with "true" or "false".
  @inlinable
  public static func trueOrFalse(
    boolValue: Bool,
    capitalization: BooleanCapitalization
  ) -> Self {
    boolean(
      boolValue,
      capitalization: capitalization,
      ifTrue: "true",
      ifFalse: "false"
    )
  }

  /// Constructs a `.text`-flavored `URIVariableValue` representing `boolValue` as `yes` or `no`.
  ///
  /// - Parameters:
  ///   - boolValue: The boolean value to represent.
  ///   - capitalization: The capitalization style to apply.
  ///
  /// - Returns: A text-flavored value with "yes" or "no".
  @inlinable
  public static func yesOrNo(
    boolValue: Bool,
    capitalization: BooleanCapitalization
  ) -> Self {
    boolean(
      boolValue,
      capitalization: capitalization,
      ifTrue: "yes",
      ifFalse: "no"
    )
  }

  /// Constructs a `.text`-flavored `URIVariableValue` representing `boolValue` as `y` or `n`.
  ///
  /// - Parameters:
  ///   - boolValue: The boolean value to represent.
  ///   - capitalization: The capitalization style to apply (defaults to `.allCaps`).
  ///
  /// - Returns: A text-flavored value with "y" or "n".
  @inlinable
  public static func yOrN(
    boolValue: Bool,
    capitalization: BooleanCapitalization = .allCaps
  ) -> Self {
    boolean(
      boolValue,
      capitalization: capitalization,
      ifTrue: "y",
      ifFalse: "n"
    )
  }

  /// Constructs a `.text`-flavored `URIVariableValue` representing `boolValue` as `1` or `0`.
  ///
  /// - Parameter boolValue: The boolean value to represent.
  ///
  /// - Returns: A text-flavored value with "1" or "0".
  @inlinable
  public static func zeroOrOne(boolValue: Bool) -> Self {
    boolean(
      boolValue,
      capitalization: .lowercase,
      ifTrue: "1",
      ifFalse: "0"
    )
  }

  /// Constructs a `.text`-flavored `URIVariableValue` by converting `integer` to a `String`.
  ///
  /// - Parameter integer: The integer value to convert.
  ///
  /// - Returns: A text-flavored value with the integer's string representation.
  @inlinable
  public static func integer<T>(
    _ integer: T
  ) -> Self where T: BinaryInteger {
    Self(
      storage: Storage(from: String(integer))
    )
  }
  
  /// Constructs a `.text`-flavored `URIVariableValue` wrapping `number` as formatted-by `style`.
  ///
  /// - Parameters:
  ///   - number: The integer value to format.
  ///   - style: The format style to apply.
  ///
  /// - Returns: A text-flavored value with the formatted number.
  @inlinable
  public static func formattedNumber<T>(
    _ number: T,
    style: IntegerFormatStyle<T>
  ) -> Self where T: BinaryInteger {
    Self(
      storage: Storage(from: style.format(number))
    )
  }

  /// Constructs a `.text`-flavored `URIVariableValue` wrapping `number` as formatted-by `style`.
  ///
  /// - Parameters:
  ///   - number: The floating-point value to format.
  ///   - style: The format style to apply.
  ///
  /// - Returns: A text-flavored value with the formatted number.
  @inlinable
  public static func formattedNumber<T>(
    _ number: T,
    style: FloatingPointFormatStyle<T>
  ) -> Self where T: BinaryFloatingPoint {
    Self(
      storage: Storage(from: style.format(number))
    )
  }

  /// Constructs a `.text`-flavored `URIVariableValue` wrapping `number` as formatted-by `style`.
  ///
  /// - Parameters:
  ///   - number: The decimal value to format.
  ///   - style: The format style to apply.
  ///
  /// - Returns: A text-flavored value with the formatted number.
  @inlinable
  public static func formattedNumber(
    _ number: Decimal,
    style: Decimal.FormatStyle
  ) -> Self {
    Self(
      storage: Storage(from: style.format(number))
    )
  }

  /// Constructs a `.list`-flavored `URIVariableValue` wrapping `texts`.
  ///
  /// - Parameter texts: The sequence of strings to include in the list.
  ///
  /// - Returns: A list-flavored value containing the strings.
  @inlinable
  public static func list(_ texts: some Sequence<String>) -> Self {
    Self(
      storage: Storage(from: texts)
    )
  }

  /// Constructs a single-element `.list`-flavored `URIVariableValue` wrapping `text`.
  ///
  /// - Parameter text: The single string to include in the list.
  ///
  /// - Returns: A list-flavored value containing one string.
  @inlinable
  public static func list(_ text: String) -> Self {
    Self(
      storage: Storage(singleElementListFrom: text)
    )
  }

  /// Constructs an `.association`-flavored `URIVariableValue` wrapping `pairs`.
  ///
  /// - Parameter pairs: The sequence of key-value pairs to include.
  ///
  /// - Returns: An association-flavored value containing the pairs.
  @inlinable
  public static func association(_ pairs: some Sequence<(String, String)>) -> Self {
    Self(
      storage: Storage(from: pairs)
    )
  }

  /// Constructs a single-element `.association`-flavored `URIVariableValue` wrapping `pair`.
  ///
  /// - Parameters:
  ///   - key: The key of the single pair.
  ///   - value: The value of the single pair.
  ///
  /// - Returns: An association-flavored value containing one pair.
  @inlinable
  public static func association(key: String, value: String) -> Self {
    Self(
      storage: Storage(from: (key, value))
    )
  }

}

// MARK: - Synthesized Conformances

extension URIVariableValue : Sendable { }
extension URIVariableValue : Equatable { }
extension URIVariableValue : Hashable { }

// MARK: - Comparable

extension URIVariableValue : Comparable {

  @inlinable
  public static func <(
    lhs: URIVariableValue,
    rhs: URIVariableValue
  ) -> Bool {
    lhs.storage < rhs.storage
  }

}

// MARK: - CustomStringConvertible

extension URIVariableValue : CustomStringConvertible {

  @inlinable
  public var description: String {
    storage.description
  }

}

// MARK: - CustomDebugStringConvertible

extension URIVariableValue : CustomDebugStringConvertible {

  @inlinable
  public var debugDescription: String {
    "URIVariableValue(storage: \(storage.debugDescription))"
  }

}

// MARK: - Codable

extension URIVariableValue : Codable {

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
  /// - Throws: `DataValidationError` if the decoded value is invalid.
  @inlinable
  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    let storage = try container.decode(Storage.self)
    guard storage.isValid else {
      switch storage {
      case .undefined:
        // ^ shouldn't actually get to this branch
        throw DataValidationError(
          forType: URIVariableValue.self,
          problemDescription: "Unexpectedly discovered an invalid `.undefined`-style storage \(storage.debugDescription)",
          repairDescription: ".undefined shouldn't ever be invalid thus no suggestion is available.",
          repairSuggestion: nil
        )
      case .text(let text):
        throw DataValidationError(
          forType: URIVariableValue.self,
          problemDescription: "Unexpectedly discovered an invalid `.text` payload \(text.debugDescription)",
          repairDescription: "Supplying an empty-string .text as a repair suggestion",
          repairSuggestion: URIVariableValue(
            storage: .text(URIVariableTextValue(rawValue: ""))
          )
        )
      case .list(let list):
        throw DataValidationError(
          forType: URIVariableValue.self,
          problemDescription: "Unexpectedly discovered an invalid `.list` payload \(list.debugDescription)",
          repairDescription: "Supplying a .list with an empty payload as a repair suggestion",
          repairSuggestion: URIVariableValue(
            storage: .list(URIVariableListValue())
          )
        )
      case .association(let association):
        throw DataValidationError(
          forType: URIVariableValue.self,
          problemDescription: "Unexpectedly discovered an invalid `.association` payload \(association.debugDescription)",
          repairDescription: "Supplying a .list with an empty payload as a repair suggestion",
          repairSuggestion: URIVariableValue(
            storage: .association(URIVariableAssociationValue())
          )
        )
      }
    }
    self.init(storage: storage)
  }
  
}

extension URIVariableValue: ExpressibleByNilLiteral {

  /// Creates an undefined value from a nil literal.
  public init(nilLiteral: ()) {
    self = .undefined
  }
}

extension URIVariableValue: ExpressibleByArrayLiteral {

  /// The element type for array literal initialization.
  public typealias ArrayLiteralElement = URIScalarVariableValue

  /// Creates a list-flavored value from an array literal of scalar values.
  ///
  /// - Parameter elements: The scalar values to include in the list.
  public init(arrayLiteral elements: ArrayLiteralElement...) {
    self.init(
      storage: .list(
        URIVariableListValue(strings: elements.map(\.storage.rawValue))
      )
    )
  }

}

extension URIVariableValue: ExpressibleByDictionaryLiteral {

  /// The key type for dictionary literal initialization.
  public typealias Key = String

  /// The value type for dictionary literal initialization.
  public typealias Value = URIScalarVariableValue

  /// Creates an association-flavored value from a dictionary literal.
  ///
  /// - Parameter elements: The key-value pairs to include in the association.
  public init(dictionaryLiteral elements: (Key, Value)...) {
    self.init(
      storage: .association(
        URIVariableAssociationValue(
          values: elements.map { key, value in
            URIVariablePairValue(
              key: URIVariableTextValue(rawValue: key),
              value: value.storage
            )
          }
        )
      )
    )
  }

}

extension URIVariableValue: ExpressibleByIntegerLiteral {

  /// The integer literal type for initialization.
  public typealias IntegerLiteralType = Int

  /// Creates a text-flavored value from an integer literal.
  ///
  /// - Parameter value: The integer value to convert to text.
  public init(integerLiteral value: IntegerLiteralType) {
    self.init(
      storage: .text(
        URIVariableTextValue(rawValue: "\(value)")
      )
    )
  }
}

extension URIVariableValue: ExpressibleByFloatLiteral {

  /// The floating-point literal type for initialization.
  public typealias FloatLiteralType = Double

  /// Creates a text-flavored value from a floating-point literal.
  ///
  /// - Parameter value: The floating-point value to convert to text.
  public init(floatLiteral value: FloatLiteralType) {
    self.init(
      storage: .text(
        URIVariableTextValue(rawValue: "\(value)")
      )
    )
  }
}

extension URIVariableValue: ExpressibleByUnicodeScalarLiteral {
  
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
      storage: .text(
        URIVariableTextValue(rawValue: String(value))
      )
    )
  }

}

extension URIVariableValue: ExpressibleByExtendedGraphemeClusterLiteral {
  
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
      storage: .text(
        URIVariableTextValue(rawValue: String(value))
      )
    )
  }
  
}

extension URIVariableValue: ExpressibleByStringLiteral {
  
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
      storage: .text(
        URIVariableTextValue(rawValue: String(value))
      )
    )
  }
  
}

// MARK: - Core API

extension URIVariableValue {
  
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
  
  /// Returns a count of the defined "sub-values" within `self`.
  ///
  /// - `.undefined`: always *0*
  /// - `.text`: always *1* (even for empty strings)
  /// - `.list`: count of the underlying list
  /// - `.association`: count of the underlying association
  ///
  @inlinable
  public var count: Int {
    storage.count
  }
  
  /// The flavor of the value: `.undefined`, `.text`, and so on.
  @inlinable
  public var valueType: URIVariableValueType {
    storage.valueType
  }
  
  /// `true` if this has one of the *defined* flavors (e.g. anything other than `.undefined`).
  @inlinable
  public var isDefined: Bool {
    storage.isDefined
  }
  
  /// `true` if this is of the `.undefined ` flavor.
  @inlinable
  public var isUndefined: Bool {
    storage.isUndefined
  }
  
  /// Synonym for `isUndefined`--exists for analogy with other `is$Value` properties.
  @inlinable
  public var isUndefinedValue: Bool {
    storage.isUndefined
  }
  
  /// `true` iff this has the `.text` flavor.
  @inlinable
  public var isTextValue: Bool {
    storage.isTextValue
  }
  
  /// `true` iff this has the `.list` flavor.
  @inlinable
  public var isListValue: Bool {
    storage.isListValue
  }
  
  /// `true` iff this has the `.association` flavor.
  @inlinable
  public var isAssociationValue: Bool {
    storage.isAssociationValue
  }
  
  @usableFromInline
  internal var errorMessageRepresentation: String {
    storage.errorMessageRepresentation
  }
  
}

// MARK: - Validatable

extension URIVariableValue {
  
  @inlinable
  internal var isValid: Bool {
    storage.isValid
  }
  
}
