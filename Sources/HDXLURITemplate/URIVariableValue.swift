//
//  URIVariableValue.swift
//

import Foundation
import HDXLCommonUtilities

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
@frozen
public struct URIVariableValue {

  // ------------------------------------------------------------------------ //
  // MARK: Primary Properties
  // ------------------------------------------------------------------------ //

  /// Shorthand for the wrapped data-storage type.
  @usableFromInline
  internal typealias Storage = URIVariableValueData
  
  /// Holds the actual variable value.
  @usableFromInline
  internal var storage: URIVariableValueData

  // ------------------------------------------------------------------------ //
  // MARK: Designated Initializer
  // ------------------------------------------------------------------------ //

  /// Designated internal-use-only initializer.
  @inlinable
  internal init(storage: URIVariableValueData) {
    // /////////////////////////////////////////////////////////////////////////
    pedantic_assert(storage.isValid)
    defer { pedantic_assert(self.isValid) }
    // /////////////////////////////////////////////////////////////////////////
    self.storage = storage
  }
  
  // ------------------------------------------------------------------------ //
  // MARK: Well-Known Values
  // ------------------------------------------------------------------------ //
  
  /// Convenience for the undefined `URIVariableValue`.
  public static let undefined: URIVariableValue = URIVariableValue(storage: .undefined)
  
  /// Convenience for the empty-string `URIVariableValue`.
  public static let emptyString: URIVariableValue = URIVariableValue(storage: .text(URIVariableTextValue(text: "")))
  
  /// Convenience for the empty-list `URIVariableValue`.
  public static let emptyList: URIVariableValue = URIVariableValue(storage: .emptyList)
  
  /// Convenience for the empty-assocication `URIVariableValue`.
  public static let emptyAssociation: URIVariableValue = URIVariableValue(storage: .emptyAssociation)

  // ------------------------------------------------------------------------ //
  // MARK: Public Initializers
  // ------------------------------------------------------------------------ //

  /// Constructs a `.text`-flavored `URIVariableValue` wrapping `text`.
  @inlinable
  public init(from text: String) {
    self.init(
      storage: Storage(from: text)
    )
  }

  /// Constructs a `.list`-flavored `URIVariableValue` wrapping `texts`.
  @inlinable
  public init<S:Sequence>(from texts: S) where S.Element == String {
    self.init(
      storage: Storage(from: texts)
    )
  }

  /// Constructs a single-element `.list`-flavored `URIVariableValue` wrapping `text`.
  @inlinable
  public init(singleElementListFrom text: String) {
    self.init(
      storage: Storage(singleElementListFrom: text)
    )
  }

  /// Constructs an `.association`-flavored `URIVariableValue` wrapping `pairs`.
  @inlinable
  public init<S:Sequence>(from pairs: S) where S.Element == (String,String) {
    self.init(
      storage: Storage(from: pairs)
    )
  }

  /// Constructs a single-element `.association`-flavored `URIVariableValue` wrapping `pair`.
  @inlinable
  public init(from pair: (String,String)) {
    self.init(
      storage: Storage(from: pair)
    )
  }

}

// -------------------------------------------------------------------------- //
// MARK: URIVariableValue - Core API
// -------------------------------------------------------------------------- //

public extension URIVariableValue {
  
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
  var isEmpty: Bool {
    get {
      return self.storage.isEmpty
    }
  }
  
  /// Returns a count of the defined "sub-values" within `self`.
  ///
  /// - `.undefined`: always *0*
  /// - `.text`: always *1* (even for empty strings)
  /// - `.list`: count of the underlying list
  /// - `.association`: count of the underlying association
  ///
  @inlinable
  var count: Int {
    get {
      return self.storage.count
    }
  }
  
  /// The flavor of the value: `.undefined`, `.text`, and so on.
  @inlinable
  var valueType: URIVariableValueType {
    get {
      return self.storage.valueType
    }
  }
  
  /// `true` if this has one of the *defined* flavors (e.g. anything other than `.undefined`).
  @inlinable
  var isDefined: Bool {
    get {
      return self.storage.isDefined
    }
  }

  /// `true` if this is of the `.undefined ` flavor.
  @inlinable
  var isUndefined: Bool {
    get {
      return self.storage.isUndefined
    }
  }

  /// Synonym for `isUndefined`--exists for analogy with other `is$Value` properties.
  @inlinable
  var isUndefinedValue: Bool {
    get {
      return self.storage.isUndefined
    }
  }

  /// `true` iff this has the `.text` flavor.
  @inlinable
  var isTextValue: Bool {
    get {
      return self.storage.isTextValue
    }
  }

  /// `true` iff this has the `.list` flavor.
  @inlinable
  var isListValue: Bool {
    get {
      return self.storage.isListValue
    }
  }

  /// `true` iff this has the `.association` flavor.
  @inlinable
  var isAssociationValue: Bool {
    get {
      return self.storage.isAssociationValue
    }
  }

}

// -------------------------------------------------------------------------- //
// MARK: URIVariableValue - Validatable
// -------------------------------------------------------------------------- //

extension URIVariableValue : Validatable {
  
  @inlinable
  public var isValid: Bool {
    get {
      return self.storage.isValid
    }
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: URIVariableValue - Equatable
// -------------------------------------------------------------------------- //

extension URIVariableValue : Equatable {
  
  @inlinable
  public static func ==(
    lhs: URIVariableValue,
    rhs: URIVariableValue) -> Bool {
    // /////////////////////////////////////////////////////////////////////////
    pedantic_assert(lhs.isValid)
    pedantic_assert(rhs.isValid)
    // /////////////////////////////////////////////////////////////////////////
    return lhs.storage == rhs.storage
  }

  @inlinable
  public static func !=(
    lhs: URIVariableValue,
    rhs: URIVariableValue) -> Bool {
    // /////////////////////////////////////////////////////////////////////////
    pedantic_assert(lhs.isValid)
    pedantic_assert(rhs.isValid)
    // /////////////////////////////////////////////////////////////////////////
    return lhs.storage != rhs.storage
  }

}

// -------------------------------------------------------------------------- //
// MARK: URIVariableValue - Comparable
// -------------------------------------------------------------------------- //

extension URIVariableValue : Comparable {
  
  @inlinable
  public static func <(
    lhs: URIVariableValue,
    rhs: URIVariableValue) -> Bool {
    // /////////////////////////////////////////////////////////////////////////
    pedantic_assert(lhs.isValid)
    pedantic_assert(rhs.isValid)
    // /////////////////////////////////////////////////////////////////////////
    return lhs.storage < rhs.storage
  }

  @inlinable
  public static func >(
    lhs: URIVariableValue,
    rhs: URIVariableValue) -> Bool {
    // /////////////////////////////////////////////////////////////////////////
    pedantic_assert(lhs.isValid)
    pedantic_assert(rhs.isValid)
    // /////////////////////////////////////////////////////////////////////////
    return lhs.storage > rhs.storage
  }

  @inlinable
  public static func <=(
    lhs: URIVariableValue,
    rhs: URIVariableValue) -> Bool {
    // /////////////////////////////////////////////////////////////////////////
    pedantic_assert(lhs.isValid)
    pedantic_assert(rhs.isValid)
    // /////////////////////////////////////////////////////////////////////////
    return lhs.storage <= rhs.storage
  }

  @inlinable
  public static func >=(
    lhs: URIVariableValue,
    rhs: URIVariableValue) -> Bool {
    // /////////////////////////////////////////////////////////////////////////
    pedantic_assert(lhs.isValid)
    pedantic_assert(rhs.isValid)
    // /////////////////////////////////////////////////////////////////////////
    return lhs.storage >= rhs.storage
  }

}

// -------------------------------------------------------------------------- //
// MARK: URIVariableValue - Hashable
// -------------------------------------------------------------------------- //

extension URIVariableValue : Hashable {
  
  @inlinable
  public func hash(into hasher: inout Hasher) {
    self.storage.hash(into: &hasher)
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: URIVariableValue - CustomStringConvertible
// -------------------------------------------------------------------------- //

extension URIVariableValue : CustomStringConvertible {
  
  @inlinable
  public var description: String {
    get {
      return self.storage.description
    }
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: URIVariableValue - CustomDebugStringConvertible
// -------------------------------------------------------------------------- //

extension URIVariableValue : CustomDebugStringConvertible {
  
  @inlinable
  public var debugDescription: String {
    get {
      return "URIVariableValue(storage: \(self.storage.debugDescription))"
    }
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: URIVariableValue - Codable
// -------------------------------------------------------------------------- //

extension URIVariableValue : Codable {
  
  @inlinable
  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(self.storage)
  }
  
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
            storage: .text(URIVariableTextValue(text: ""))
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
