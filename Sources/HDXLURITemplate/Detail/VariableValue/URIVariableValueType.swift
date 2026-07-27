// -------------------------------------------------------------------------- //
// MARK: URIVariableValueType - Definition
// -------------------------------------------------------------------------- //

/// Case-enumeration for variable *values*, which can be either undefined (`nil`-like),
/// `text` (simple string), `list` (of simple strings), or `association` (*ordered* list
/// of key-value pairs).
///
/// This is a native Swift value. The package does not expose an Objective-C
/// facade.
public enum URIVariableValueType : UInt8 {
  
  case undefined = 1
  case text = 2
  case list = 4
  case association = 8
  
}

// -------------------------------------------------------------------------- //
// MARK: - Synthesized Conformances
// -------------------------------------------------------------------------- //

extension URIVariableValueType : Sendable { }
extension URIVariableValueType : Equatable { }
extension URIVariableValueType : Hashable { }
extension URIVariableValueType : Codable { }
extension URIVariableValueType : CaseIterable { }

// -------------------------------------------------------------------------- //
// MARK: - CustomStringConvertible
// -------------------------------------------------------------------------- //

extension URIVariableValueType : CustomStringConvertible {
  
  @inlinable
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

extension URIVariableValueType : CustomDebugStringConvertible {
  
  @inlinable
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
