//
//  URITemplateVariableName+Parsing.swift
//

import Foundation

internal extension URITemplateVariableName {
  
  @usableFromInline
  enum ParseError : Error {
    case invalidEmptyName
    case invalidNameContents(String)
  }
  
  @inlinable
  init(parsing string: String) throws {
    guard !string.isEmpty else {
      throw ParseError.invalidEmptyName
    }
    guard URITemplateVariableName
      .validationRegularExpression
      .matchesEntirety(of: string) else {
        throw ParseError.invalidNameContents(string)
    }
    self.init(storage: string)
  }
  
}
