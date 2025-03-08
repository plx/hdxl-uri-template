import Foundation

extension URITemplateVariableName {
  
  @usableFromInline
  internal enum ParseError : Error {
    case invalidEmptyName
    case invalidNameContents(String)
  }
  
  @inlinable
  internal init(parsing string: String) throws {
    guard !string.isEmpty else {
      throw ParseError.invalidEmptyName
    }
    guard URITemplateVariableName
      .validationRegularExpression
      .matchesEntirety(of: string)
    else {
      throw ParseError.invalidNameContents(string)
    }
    self.init(storage: string)
  }
  
}
