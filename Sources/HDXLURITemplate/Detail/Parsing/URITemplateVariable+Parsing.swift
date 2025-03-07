//
//  URITemplateVariable+Parsing.swift
//

import Foundation

internal extension URITemplateVariable {
  
  @usableFromInline
  enum ParseError : Error {
    case invalidEmptyString
  }
  
  @inlinable
  init(parsing string: String) throws {
    guard !string.isEmpty else {
      throw ParseError.invalidEmptyString
    }
    var variableNameString: String = string
    let expansionModifier = try URIValueExpansionModifier(
      parsing: &variableNameString
    )
    let variableName = try URITemplateVariableName(
      parsing: variableNameString
    )
    self.init(
      variableName: variableName,
      expansionModifier: expansionModifier
    )
  }
  
}
