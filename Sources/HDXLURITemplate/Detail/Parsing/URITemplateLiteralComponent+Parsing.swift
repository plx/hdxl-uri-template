//
//  URITemplateLiteralComponent+Parsing.swift
//

import Foundation
import HDXLCommonUtilities

internal extension URITemplateLiteralComponent {
  
  @usableFromInline
  enum ParseError : Error {
    case unexpectedlyEmpty
    case invalidContent(String)
  }
  
  @inlinable
  init(parsing string: String) throws {
    guard !string.isEmpty else {
      throw ParseError.unexpectedlyEmpty
    }
    guard Self.validationRegularExpression.matchesEntirety(of: string) else {
      throw ParseError.invalidContent(string)
    }
    self.init(
      storage: string
    )
  }
  
}
