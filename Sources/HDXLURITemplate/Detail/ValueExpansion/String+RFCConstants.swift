import Foundation

// RFC-derived Code Components in this file are attributed in
// THIRD_PARTY_NOTICES.md.

extension String {

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
