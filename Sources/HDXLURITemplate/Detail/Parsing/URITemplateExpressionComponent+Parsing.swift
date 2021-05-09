//
//  URITemplateExpressionComponent+Parsing.swift
//

import Foundation
import HDXLCommonUtilities

internal extension URITemplateExpressionComponent {
   
  @usableFromInline
  enum ParseError : Error {
    case invalidEmptyString
    case noVariablesFound(String)
  }
  
  @inlinable
  init(parsing string: String) throws {
    guard !string.isEmpty else {
      throw ParseError.invalidEmptyString
    }
    var variableListString = string
    let expansionType = try URIValueExpansionType(
      parsing: &variableListString
    )
    let variables = try variableListString
      .lazySplit(separator: ",")
      .map() {
        try URITemplateVariable(parsing: $0)
    }
    guard !variables.isEmpty else {
      throw ParseError.noVariablesFound(string)
    }
    self.init(
      expansionType: expansionType,
      variables: variables
    )
  }
  
}
