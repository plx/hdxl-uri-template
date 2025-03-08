import Foundation

// -------------------------------------------------------------------------- //
// MARK: URIValueExpansionType - Definition
// -------------------------------------------------------------------------- //

@usableFromInline
internal enum URIValueExpansionType : UInt8 {
    
  case simple = 1
  case reserved = 2
  case fragment = 4
  case label = 8
  case pathSegment = 16
  case pathParameter = 32
  case query = 64
  case queryContinuation = 128
  
  // ------------------------------------------------------------------------ //
  // MARK: Format String Constants
  // ------------------------------------------------------------------------ //
  
  @usableFromInline
  internal static let simpleFormatString: String = ""

  @usableFromInline
  internal static let reservedFormatString: String = "+"

  @usableFromInline
  internal static let fragmentFormatString: String = "#"

  @usableFromInline
  internal static let labelFormatString: String = "."

  @usableFromInline
  internal static let pathSegmentFormatString: String = "/"

  @usableFromInline
  internal static let pathParameterFormatString: String = ";"

  @usableFromInline
  internal static let queryFormatString: String = "?"

  @usableFromInline
  internal static let queryContinuationFormatString: String = "&"

  // ------------------------------------------------------------------------ //
  // MARK: Prefixes For Expanded Variable Lists
  // ------------------------------------------------------------------------ //
  
  @usableFromInline
  internal static let simplePrefixForExpandedVariableList: String = ""
  
  @usableFromInline
  internal static let reservedPrefixForExpandedVariableList: String = ""
  
  @usableFromInline
  internal static let fragmentPrefixForExpandedVariableList: String = "#"
  
  @usableFromInline
  internal static let labelPrefixForExpandedVariableList: String = "."
  
  @usableFromInline
  internal static let pathSegmentPrefixForExpandedVariableList: String = "/"
  
  @usableFromInline
  internal static let pathParameterPrefixForExpandedVariableList: String = ";"
  
  @usableFromInline
  internal static let queryPrefixForExpandedVariableList: String = "?"
  
  @usableFromInline
  internal static let queryContinuationPrefixForExpandedVariableList: String = "&"

  // ------------------------------------------------------------------------ //
  // MARK: Separators For Expanded Variable Lists
  // ------------------------------------------------------------------------ //
  
  @usableFromInline
  internal static let simpleSeparatorForExpandedVariableList: String = ","
  
  @usableFromInline
  internal static let reservedSeparatorForExpandedVariableList: String = ","
  
  @usableFromInline
  internal static let fragmentSeparatorForExpandedVariableList: String = ","
  
  @usableFromInline
  internal static let labelSeparatorForExpandedVariableList: String = "."
  
  @usableFromInline
  internal static let pathSegmentSeparatorForExpandedVariableList: String = "/"
  
  @usableFromInline
  internal static let pathParameterSeparatorForExpandedVariableList: String = ";"
  
  @usableFromInline
  internal static let querySeparatorForExpandedVariableList: String = "&"
  
  @usableFromInline
  internal static let queryContinuationSeparatorForExpandedVariableList: String = "&"

}

// -------------------------------------------------------------------------- //
// MARK: - Synthesized Conformances
// -------------------------------------------------------------------------- //

extension URIValueExpansionType : Sendable { }
extension URIValueExpansionType : Equatable { }
extension URIValueExpansionType : Hashable { }
extension URIValueExpansionType : Codable { }
extension URIValueExpansionType : CaseIterable { }

// -------------------------------------------------------------------------- //
// MARK: - Comparable
// -------------------------------------------------------------------------- //

extension URIValueExpansionType : Comparable {
  
  @inlinable
  internal static func <(
    lhs: Self,
    rhs: Self
  ) -> Bool {
    lhs.rawValue < rhs.rawValue
  }

}

// -------------------------------------------------------------------------- //
// MARK: - CustomStringConvertible
// -------------------------------------------------------------------------- //

extension URIValueExpansionType : CustomStringConvertible {
  
  @inlinable
  internal var description: String {
    switch self {
    case .simple:
      "simple"
    case .reserved:
      "reserved"
    case .fragment:
      "fragment"
    case .label:
      "label"
    case .pathSegment:
      "pathSegment"
    case .pathParameter:
      "pathParameter"
    case .query:
      "query"
    case .queryContinuation:
      "queryContinuation"
    }
  }
}

// -------------------------------------------------------------------------- //
// MARK: - CustomStringConvertible
// -------------------------------------------------------------------------- //

extension URIValueExpansionType : CustomDebugStringConvertible {
  
  @inlinable
  internal var debugDescription: String {
    switch self {
    case .simple:
      "URIValueExpansionType.simple"
    case .reserved:
      "URIValueExpansionType.reserved"
    case .fragment:
      "URIValueExpansionType.fragment"
    case .label:
      "URIValueExpansionType.label"
    case .pathSegment:
      "URIValueExpansionType.pathSegment"
    case .pathParameter:
      "URIValueExpansionType.pathParameter"
    case .query:
      "URIValueExpansionType.query"
    case .queryContinuation:
      "URIValueExpansionType.queryContinuation"
    }
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: - Core API
// -------------------------------------------------------------------------- //

extension URIValueExpansionType {
  
  @inlinable
  internal var formatString: String {
    switch self {
    case .simple:
      Self.simpleFormatString
    case .reserved:
      Self.reservedFormatString
    case .fragment:
      Self.fragmentFormatString
    case .label:
      Self.labelFormatString
    case .pathSegment:
      Self.pathSegmentFormatString
    case .pathParameter:
      Self.pathParameterFormatString
    case .query:
      Self.queryFormatString
    case .queryContinuation:
      Self.queryContinuationFormatString
    }
  }
  
  @inlinable
  internal var prefixForExpandedVariableList: String {
    switch self {
    case .simple:
      Self.simplePrefixForExpandedVariableList
    case .reserved:
      Self.reservedPrefixForExpandedVariableList
    case .fragment:
      Self.fragmentPrefixForExpandedVariableList
    case .label:
      Self.labelPrefixForExpandedVariableList
    case .pathSegment:
      Self.pathSegmentPrefixForExpandedVariableList
    case .pathParameter:
      Self.pathParameterPrefixForExpandedVariableList
    case .query:
      Self.queryPrefixForExpandedVariableList
    case .queryContinuation:
      Self.queryContinuationPrefixForExpandedVariableList
    }
  }
  
  @inlinable
  internal var separatorForExpandedVariableList: String {
    switch self {
    case .simple:
      Self.simpleSeparatorForExpandedVariableList
    case .reserved:
      Self.reservedSeparatorForExpandedVariableList
    case .fragment:
      Self.fragmentSeparatorForExpandedVariableList
    case .label:
      Self.labelSeparatorForExpandedVariableList
    case .pathSegment:
      Self.pathSegmentSeparatorForExpandedVariableList
    case .pathParameter:
      Self.pathParameterSeparatorForExpandedVariableList
    case .query:
      Self.querySeparatorForExpandedVariableList
    case .queryContinuation:
      Self.queryContinuationSeparatorForExpandedVariableList
    }
  }
  
  
  @inlinable
  internal init?(formatString: String) {
    switch formatString {
    case Self.simpleFormatString:
      self = .simple
    case Self.reservedFormatString:
      self = .reserved
    case Self.fragmentFormatString:
      self = .fragment
    case Self.labelFormatString:
      self = .label
    case Self.pathSegmentFormatString:
      self = .pathSegment
    case Self.pathParameterFormatString:
      self = .pathParameter
    case Self.queryFormatString:
      self = .query
    case Self.queryContinuationFormatString:
      self = .queryContinuation
    default:
      // TODO: consider logging values?
      return nil
    }
  }
  
}
