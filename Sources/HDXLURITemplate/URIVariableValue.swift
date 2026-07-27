// -------------------------------------------------------------------------- //
// MARK: URIVariableValue - Definition
// -------------------------------------------------------------------------- //

/// Represents a value intended to be substituted into a URI template variable.
///
/// Values come in four flavors:
///
/// - `undefined`: an *explicit* `nil`-like value
/// - `text`: a simple string
/// - `list`: a list of strings
/// - `association`: an *ordered* list of unique-key pairs of strings
///
/// The public API provides constructors for every flavor and read-only payload
/// access through ``textValue``, ``listValue``, and ``associationValue``.
/// These properties return ordinary Swift values and do not expose or promise
/// a particular storage representation.
///
/// - Important: This package's initial contract is Swift-only. Code that used
///   the removed `HDXLURIVariableValue` wrapper should migrate to
///   ``undefined``, ``text(_:)``, ``list(_:)-(String)``, and the
///   `association` factories, then inspect the native value through
///   ``valueType``, the `is…Value` properties, and the flavor-specific payload
///   properties.
///   Archives of the removed wrapper are not supported.
///
/// - Note: This runtime value deliberately does not conform to `Codable`.
///   Applications that persist parameters should own and version their source
///   model and construct runtime values through the public factories. The
///   payload accessors are runtime inspection APIs, not a persistence schema.
///
public struct URIVariableValue {

  // ------------------------------------------------------------------------ //
  // MARK: Primary Properties
  // ------------------------------------------------------------------------ //

  /// Shorthand for the wrapped data-storage type.
  internal typealias Storage = URIVariableValueData

  /// Holds the actual variable value.
  internal var storage: URIVariableValueData

  // ------------------------------------------------------------------------ //
  // MARK: Designated Initializer
  // ------------------------------------------------------------------------ //

  /// Designated internal-use-only initializer.
  internal init(storage: URIVariableValueData) {
    #if HEAVY_DEBUG
      pedanticAssert(storage.isValid)
      defer { pedanticAssert(isValid) }
    #endif
    self.storage = storage
  }

  // ------------------------------------------------------------------------ //
  // MARK: Well-Known Values
  // ------------------------------------------------------------------------ //

  /// Convenience for the undefined `URIVariableValue`.
  public static let undefined: URIVariableValue = URIVariableValue(storage: .undefined)

  /// Convenience for the empty-string `URIVariableValue`.
  public static let emptyString: URIVariableValue = URIVariableValue(
    storage: .text(URIVariableTextValue(rawValue: ""))
  )

  /// Convenience for the empty-list `URIVariableValue`.
  public static let emptyList: URIVariableValue = URIVariableValue(storage: .emptyList)

  /// Convenience for the empty-association `URIVariableValue`.
  public static let emptyAssociation: URIVariableValue = URIVariableValue(
    storage: .emptyAssociation
  )

  // ------------------------------------------------------------------------ //
  // MARK: Public Constructors
  // ------------------------------------------------------------------------ //

  /// Constructs a `.text`-flavored `URIVariableValue` wrapping `text`.
  ///
  /// During prefix expansion, a well-formed percent-encoded UTF-8 scalar
  /// counts as one Unicode code point and retains its original triplet
  /// spelling for reserved and fragment expansion. A syntactically-valid
  /// `%HH` triplet that is not part of well-formed UTF-8 is treated as one
  /// opaque prefix-counting unit; this is the library's deterministic fallback
  /// for malformed encoded input. A percent sign outside `%HH` is ordinary text
  /// and is escaped as `%25`.
  public static func text(_ text: String) -> Self {
    Self(
      storage: Storage(from: text)
    )
  }

  /// Constructs a `.list`-flavored `URIVariableValue` wrapping `texts`.
  public static func list(_ texts: some Sequence<String>) -> Self {
    Self(
      storage: Storage(from: texts)
    )
  }

  /// Constructs a single-element `.list`-flavored `URIVariableValue` wrapping `text`.
  public static func list(_ text: String) -> Self {
    Self(
      storage: Storage(singleElementListFrom: text)
    )
  }

  /// Constructs an `.association`-flavored `URIVariableValue` wrapping `pairs`.
  ///
  /// - Throws: `AssociationError.duplicateKey(firstIndex:duplicateIndex:)`
  ///   when a key repeats.
  public static func association(
    _ pairs: some Sequence<(String, String)>
  ) throws -> Self {
    Self(
      storage: try Storage(validating: pairs)
    )
  }

  /// Constructs an association from `dictionary` in ascending key order.
  public static func association(
    _ dictionary: [String: String]
  ) -> Self {
    association(
      dictionary,
      orderingKeysWith: <
    )
  }

  /// Constructs an association from `dictionary` in the supplied key order.
  ///
  /// The predicate should define a stable strict ordering. Distinct keys for
  /// which it returns the same result in both directions use ascending lexical
  /// order as a deterministic tie-breaker.
  public static func association(
    _ dictionary: [String: String],
    orderingKeysWith areInIncreasingOrder: (String, String) -> Bool
  ) -> Self {
    Self(
      storage: Storage(
        dictionary: dictionary,
        orderingKeysWith: areInIncreasingOrder
      )
    )
  }

  /// Constructs a single-element `.association`-flavored `URIVariableValue` wrapping `pair`.
  public static func association(key: String, value: String) -> Self {
    Self(
      storage: Storage(from: (key, value))
    )
  }

}

// -------------------------------------------------------------------------- //
// MARK: - Synthesized Conformances
// -------------------------------------------------------------------------- //

extension URIVariableValue: Sendable {}
extension URIVariableValue: Equatable {}
extension URIVariableValue: Hashable {}

// -------------------------------------------------------------------------- //
// MARK: - CustomStringConvertible
// -------------------------------------------------------------------------- //

extension URIVariableValue: CustomStringConvertible {

  /// A representation of this value suitable for diagnostic display.
  public var description: String {
    storage.description
  }

}

// -------------------------------------------------------------------------- //
// MARK: URIVariableValue - CustomDebugStringConvertible
// -------------------------------------------------------------------------- //

extension URIVariableValue: CustomDebugStringConvertible {

  /// A detailed representation of this value suitable for debugging.
  public var debugDescription: String {
    "URIVariableValue(storage: \(storage.debugDescription))"
  }

}

// -------------------------------------------------------------------------- //
// MARK: - Core API
// -------------------------------------------------------------------------- //

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
  public var count: Int {
    storage.count
  }

  /// The flavor of the value: `.undefined`, `.text`, and so on.
  public var valueType: URIVariableValueType {
    storage.valueType
  }

  /// The wrapped string when this value has the `.text` flavor.
  ///
  /// This is `nil` for undefined, list, and association values. An empty text
  /// value returns `""`, so flavor mismatch remains distinct from an empty
  /// payload.
  public var textValue: String? {
    switch storage {
    case .text(let text):
      text.rawValue
    case .undefined, .list(_), .association(_):
      nil
    }
  }

  /// The ordered strings when this value has the `.list` flavor.
  ///
  /// This is `nil` for undefined, text, and association values. An empty list
  /// returns `[]`. The returned array is an independent Swift value; mutating
  /// it does not change this `URIVariableValue`.
  public var listValue: [String]? {
    switch storage {
    case .list(let list):
      list.storage.map(\.rawValue)
    case .undefined, .text(_), .association(_):
      nil
    }
  }

  /// The ordered unique-key pairs when this value has the `.association`
  /// flavor.
  ///
  /// This is `nil` for undefined, text, and list values. An empty association
  /// returns `[]`. Pair order matches the order established by the association
  /// factory. The returned array is an independent Swift value; mutating it
  /// cannot change this `URIVariableValue` or invalidate its unique-key
  /// invariant.
  public var associationValue: [(key: String, value: String)]? {
    switch storage {
    case .association(let association):
      association.storage.map {
        (
          key: $0.key.rawValue,
          value: $0.value.rawValue
        )
      }
    case .undefined, .text(_), .list(_):
      nil
    }
  }

  /// `true` if this has one of the *defined* flavors (e.g. anything other than `.undefined`).
  public var isDefined: Bool {
    storage.isDefined
  }

  /// `true` if this is of the `.undefined ` flavor.
  public var isUndefined: Bool {
    storage.isUndefined
  }

  /// Synonym for `isUndefined`--exists for analogy with other `is$Value` properties.
  public var isUndefinedValue: Bool {
    storage.isUndefined
  }

  /// `true` iff this has the `.text` flavor.
  public var isTextValue: Bool {
    storage.isTextValue
  }

  /// `true` iff this has the `.list` flavor.
  public var isListValue: Bool {
    storage.isListValue
  }

  /// `true` iff this has the `.association` flavor.
  public var isAssociationValue: Bool {
    storage.isAssociationValue
  }

}

// -------------------------------------------------------------------------- //
// MARK: - Validatable
// -------------------------------------------------------------------------- //

extension URIVariableValue {

  internal var isValid: Bool {
    storage.isValid
  }

}
