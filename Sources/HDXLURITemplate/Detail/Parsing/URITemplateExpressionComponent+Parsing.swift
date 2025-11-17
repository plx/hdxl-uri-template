import Foundation

extension URITemplateExpressionComponent {
   
  @usableFromInline
  internal enum ParseError : Error {
    case invalidEmptyString
    case noVariablesFound(String)
  }
  
  @inlinable
  internal init(parsing string: String) throws {
    guard !string.isEmpty else {
      throw ParseError.invalidEmptyString
    }
    var variableListString = string
    let expansionType = try URIValueExpansionType(
      parsing: &variableListString
    )
    let variables = try variableListString
      .split(separator: ",")
      .map { segment in
        let trimmed = segment.trimmingCharacters(in: .whitespaces)
        
        return try URITemplateVariable(parsing: String(trimmed))
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
