import Foundation

// MARK: URIVariableValueType

/// Case-enumeration for variable *values*, which can be either undefined (`nil`-like),
/// `text` (simple string), `list` (of simple strings), or `association` (*ordered* list
/// of key-value pairs).
///
/// Made public and compatible with Objective-C so as to faciliate use of this
/// package's functionality from Objective-C code.
///
@objc(HDXLURIVariableValueType)
public enum URIVariableValueType : UInt8 {

  /// An undefined (nil-like) value.
  case undefined = 1
  /// A simple text string value.
  case text = 2
  /// A list of strings.
  case list = 4
  /// An ordered list of key-value pairs.
  case association = 8

}

// MARK: - Synthesized Conformances

extension URIVariableValueType : Sendable { }
extension URIVariableValueType : Equatable { }
extension URIVariableValueType : Hashable { }
extension URIVariableValueType : Codable { }
extension URIVariableValueType : CaseIterable { }

// MARK: - Comparable

extension URIVariableValueType : Comparable {

  @inlinable
  public static func <(
    lhs: URIVariableValueType,
    rhs: URIVariableValueType
  ) -> Bool {
    lhs.rawValue < rhs.rawValue
  }

}

// MARK: - CustomStringConvertible

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

// MARK: - CustomDebugStringConvertible

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
