//
//  URIValueExpansionType.swift
//

import Foundation

// -------------------------------------------------------------------------- //
// MARK: URIValueExpansionType - Definition
// -------------------------------------------------------------------------- //

@frozen
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
// MARK: URIValueExpansionType - Core API
// -------------------------------------------------------------------------- //

internal extension URIValueExpansionType {
    
  @inlinable
  var formatString: String {
    get {
      switch self {
      case .simple:
        return Self.simpleFormatString
      case .reserved:
        return Self.reservedFormatString
      case .fragment:
        return Self.fragmentFormatString
      case .label:
        return Self.labelFormatString
      case .pathSegment:
        return Self.pathSegmentFormatString
      case .pathParameter:
        return Self.pathParameterFormatString
      case .query:
        return Self.queryFormatString
      case .queryContinuation:
        return Self.queryContinuationFormatString
      }
    }
  }
  
  @inlinable
  var prefixForExpandedVariableList: String {
    get {
      switch self {
      case .simple:
        return Self.simplePrefixForExpandedVariableList
      case .reserved:
        return Self.reservedPrefixForExpandedVariableList
      case .fragment:
        return Self.fragmentPrefixForExpandedVariableList
      case .label:
        return Self.labelPrefixForExpandedVariableList
      case .pathSegment:
        return Self.pathSegmentPrefixForExpandedVariableList
      case .pathParameter:
        return Self.pathParameterPrefixForExpandedVariableList
      case .query:
        return Self.queryPrefixForExpandedVariableList
      case .queryContinuation:
        return Self.queryContinuationPrefixForExpandedVariableList
      }
    }
  }
  
  @inlinable
  var separatorForExpandedVariableList: String {
    get {
      switch self {
      case .simple:
        return Self.simpleSeparatorForExpandedVariableList
      case .reserved:
        return Self.reservedSeparatorForExpandedVariableList
      case .fragment:
        return Self.fragmentSeparatorForExpandedVariableList
      case .label:
        return Self.labelSeparatorForExpandedVariableList
      case .pathSegment:
        return Self.pathSegmentSeparatorForExpandedVariableList
      case .pathParameter:
        return Self.pathParameterSeparatorForExpandedVariableList
      case .query:
        return Self.querySeparatorForExpandedVariableList
      case .queryContinuation:
        return Self.queryContinuationSeparatorForExpandedVariableList
      }
    }
  }

  
  @inlinable
  init?(formatString: String) {
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

// -------------------------------------------------------------------------- //
// MARK: URIValueExpansionType - Equatable
// -------------------------------------------------------------------------- //

extension URIValueExpansionType : Equatable {

  @inlinable
  internal static func ==(
    lhs: URIValueExpansionType,
    rhs: URIValueExpansionType) -> Bool {
    return lhs.rawValue == rhs.rawValue
  }
  
  @inlinable
  internal static func !=(
    lhs: URIValueExpansionType,
    rhs: URIValueExpansionType) -> Bool {
    return lhs.rawValue != rhs.rawValue
  }

}

// -------------------------------------------------------------------------- //
// MARK: URIValueExpansionType - Comparable
// -------------------------------------------------------------------------- //

extension URIValueExpansionType : Comparable {
  
  @inlinable
  internal static func <(
    lhs: URIValueExpansionType,
    rhs: URIValueExpansionType) -> Bool {
    return lhs.rawValue < rhs.rawValue
  }
  
  @inlinable
  internal static func >(
    lhs: URIValueExpansionType,
    rhs: URIValueExpansionType) -> Bool {
    return lhs.rawValue > rhs.rawValue
  }
  
  @inlinable
  internal static func <=(
    lhs: URIValueExpansionType,
    rhs: URIValueExpansionType) -> Bool {
    return lhs.rawValue <= rhs.rawValue
  }
  
  @inlinable
  internal static func >=(
    lhs: URIValueExpansionType,
    rhs: URIValueExpansionType) -> Bool {
    return lhs.rawValue >= rhs.rawValue
  }

}


// -------------------------------------------------------------------------- //
// MARK: URIValueExpansionType - Hashable
// -------------------------------------------------------------------------- //

extension URIValueExpansionType : Hashable {
  
  @inlinable
  internal func hash(into hasher: inout Hasher) {
    self.rawValue.hash(into: &hasher)
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: URIValueExpansionType - CustomStringConvertible
// -------------------------------------------------------------------------- //

extension URIValueExpansionType : CustomStringConvertible {
  
  @inlinable
  internal var description: String {
    get {
      switch self {
      case .simple:
        return "simple"
      case .reserved:
        return "reserved"
      case .fragment:
        return "fragment"
      case .label:
        return "label"
      case .pathSegment:
        return "pathSegment"
      case .pathParameter:
        return "PathParameter"
      case .query:
        return "query"
      case .queryContinuation:
        return "queryContinuation"
      }
    }
  }
}

// -------------------------------------------------------------------------- //
// MARK: URIValueExpansionType - CustomStringConvertible
// -------------------------------------------------------------------------- //

extension URIValueExpansionType : CustomDebugStringConvertible {
  
  @inlinable
  internal var debugDescription: String {
    get {
      switch self {
      case .simple:
        return "URIValueExpansionType.simple"
      case .reserved:
        return "URIValueExpansionType.reserved"
      case .fragment:
        return "URIValueExpansionType.fragment"
      case .label:
        return "URIValueExpansionType.label"
      case .pathSegment:
        return "URIValueExpansionType.pathSegment"
      case .pathParameter:
        return "URIValueExpansionType.PathParameter"
      case .query:
        return "URIValueExpansionType.query"
      case .queryContinuation:
        return "URIValueExpansionType.queryContinuation"
      }
    }
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: URIValueExpansionType - Codable
// -------------------------------------------------------------------------- //

extension URIValueExpansionType : Codable {
  
  // synthesized ok
  
}

extension URIValueExpansionType : CaseIterable {
  
  @usableFromInline
  internal typealias AllCases = [URIValueExpansionType]
  
  @inlinable
  internal static var allCases: AllCases {
    get {
      return [
        .simple,
        .reserved,
        .fragment,
        .label,
        .pathSegment,
        .pathParameter,
        .query,
        .queryContinuation
      ]
    }
  }
  
}
