import Foundation

extension URITemplateVariable {
  
  internal enum ParseError : Error {
    case invalidEmptyString
  }
  
  internal init(parsing string: String) throws {
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
