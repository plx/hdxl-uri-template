import Foundation

extension URITemplateExpressionComponent {
   
  internal enum ParseError : Error {
    case invalidEmptyString
    case noVariablesFound(String)
  }
  
  internal init(parsing string: String) throws {
    guard !string.isEmpty else {
      throw ParseError.invalidEmptyString
    }
    var variableListString = string
    let expansionType = try URIValueExpansionType(
      parsing: &variableListString
    )
    guard !variableListString.isEmpty else {
      throw ParseError.noVariablesFound(string)
    }
    let variables = try variableListString
      .split(
        separator: ",",
        omittingEmptySubsequences: false
      )
      .map { segment in
        try URITemplateVariable(parsing: String(segment))
      }
    self.init(
      expansionType: expansionType,
      variables: variables
    )
  }
  
}
