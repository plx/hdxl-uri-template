import Foundation

// RFC-derived Code Components in this file are attributed in
// THIRD_PARTY_NOTICES.md.

// -------------------------------------------------------------------------- //
// MARK: URIValueExpansionType - Definition
// -------------------------------------------------------------------------- //

internal enum URIValueExpansionType: UInt8 {

  case simple = 1
  case reserved = 2
  case fragment = 4
  case label = 8
  case pathSegment = 16
  case pathParameter = 32
  case query = 64
  case queryContinuation = 128

}

// -------------------------------------------------------------------------- //
// MARK: - Synthesized Conformances
// -------------------------------------------------------------------------- //

extension URIValueExpansionType: Sendable {}
extension URIValueExpansionType: Equatable {}
extension URIValueExpansionType: Hashable {}
extension URIValueExpansionType: CaseIterable {}

// -------------------------------------------------------------------------- //
// MARK: - Comparable
// -------------------------------------------------------------------------- //

extension URIValueExpansionType: Comparable {

  internal static func < (
    lhs: Self,
    rhs: Self
  ) -> Bool {
    lhs.rawValue < rhs.rawValue
  }

}

// -------------------------------------------------------------------------- //
// MARK: - CustomStringConvertible
// -------------------------------------------------------------------------- //

extension URIValueExpansionType: CustomStringConvertible {

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

extension URIValueExpansionType: CustomDebugStringConvertible {

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

  internal var isQueryExpansionType: Bool {
    switch self {
    case .query, .queryContinuation:
      true
    default:
      false
    }
  }

  internal var allowsPercentEncodedTriplets: Bool {
    switch self {
    case .reserved, .fragment:
      true
    default:
      false
    }
  }

  internal var emptyValueSuffix: String {
    switch self {
    case .query, .queryContinuation:
      "="
    default:
      ""
    }
  }

  internal var formatString: String {
    switch self {
    case .simple:
      .simpleFormatString
    case .reserved:
      .reservedFormatString
    case .fragment:
      .fragmentFormatString
    case .label:
      .labelFormatString
    case .pathSegment:
      .pathSegmentFormatString
    case .pathParameter:
      .pathParameterFormatString
    case .query:
      .queryFormatString
    case .queryContinuation:
      .queryContinuationFormatString
    }
  }

  internal var prefixForExpandedVariableList: String {
    switch self {
    case .simple:
      .simplePrefixForExpandedVariableList
    case .reserved:
      .reservedPrefixForExpandedVariableList
    case .fragment:
      .fragmentPrefixForExpandedVariableList
    case .label:
      .labelPrefixForExpandedVariableList
    case .pathSegment:
      .pathSegmentPrefixForExpandedVariableList
    case .pathParameter:
      .pathParameterPrefixForExpandedVariableList
    case .query:
      .queryPrefixForExpandedVariableList
    case .queryContinuation:
      .queryContinuationPrefixForExpandedVariableList
    }
  }

  internal var separatorForExpandedVariableList: String {
    switch self {
    case .simple:
      .simpleSeparatorForExpandedVariableList
    case .reserved:
      .reservedSeparatorForExpandedVariableList
    case .fragment:
      .fragmentSeparatorForExpandedVariableList
    case .label:
      .labelSeparatorForExpandedVariableList
    case .pathSegment:
      .pathSegmentSeparatorForExpandedVariableList
    case .pathParameter:
      .pathParameterSeparatorForExpandedVariableList
    case .query:
      .querySeparatorForExpandedVariableList
    case .queryContinuation:
      .queryContinuationSeparatorForExpandedVariableList
    }
  }

  internal init?(formatString: String) {
    switch formatString {
    case .simpleFormatString:
      self = .simple
    case .reservedFormatString:
      self = .reserved
    case .fragmentFormatString:
      self = .fragment
    case .labelFormatString:
      self = .label
    case .pathSegmentFormatString:
      self = .pathSegment
    case .pathParameterFormatString:
      self = .pathParameter
    case .queryFormatString:
      self = .query
    case .queryContinuationFormatString:
      self = .queryContinuation
    default:
      // TODO: consider logging values?
      return nil
    }
  }

}
