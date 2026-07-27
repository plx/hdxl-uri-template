import Foundation

extension URITemplateLiteralComponent {

  internal enum ParseError: Error {
    case unexpectedlyEmpty
    case invalidContent(String)
  }

  internal init(parsing string: String) throws {
    guard !string.isEmpty else {
      throw ParseError.unexpectedlyEmpty
    }
    guard Self.validationRegularExpression.matchesEntirety(of: string) else {
      throw ParseError.invalidContent(string)
    }
    self.init(
      rawValue: string
    )
  }

}
