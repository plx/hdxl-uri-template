// -------------------------------------------------------------------------- //
// MARK: URIVariableValueType - Definition
// -------------------------------------------------------------------------- //

/// Case-enumeration for variable *values*, which can be either undefined (`nil`-like),
/// `text` (simple string), `list` (of simple strings), or `association` (*ordered* list
/// of key-value pairs).
///
/// This is a native Swift value. The package does not expose an Objective-C
/// facade. The raw values support source-level inspection; they are not
/// persistence tags, and this type deliberately does not conform to `Codable`.
public enum URIVariableValueType: UInt8 {

  /// No value was supplied for the variable.
  case undefined = 1

  /// The variable contains one string.
  case text = 2

  /// The variable contains an ordered list of strings.
  case list = 4

  /// The variable contains ordered, unique-key string pairs.
  case association = 8

}

// -------------------------------------------------------------------------- //
// MARK: - Synthesized Conformances
// -------------------------------------------------------------------------- //

extension URIVariableValueType: Sendable {}
extension URIVariableValueType: Equatable {}
extension URIVariableValueType: Hashable {}
extension URIVariableValueType: CaseIterable {}

// -------------------------------------------------------------------------- //
// MARK: - CustomStringConvertible
// -------------------------------------------------------------------------- //

extension URIVariableValueType: CustomStringConvertible {

  /// The stable textual name of this value flavor.
  public var description: String {
    switch self {
    case .undefined:
      "undefined"
    case .text:
      "text"
    case .list:
      "list"
    case .association:
      "association"
    }
  }

}

// -------------------------------------------------------------------------- //
// MARK: - CustomDebugStringConvertible
// -------------------------------------------------------------------------- //

extension URIVariableValueType: CustomDebugStringConvertible {

  /// A source-like representation of this value flavor for debugging.
  public var debugDescription: String {
    switch self {
    case .undefined:
      "URIVariableValueType.undefined"
    case .text:
      "URIVariableValueType.text"
    case .list:
      "URIVariableValueType.list"
    case .association:
      "URIVariableValueType.association"
    }
  }

}
