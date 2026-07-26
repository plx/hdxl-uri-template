import Foundation

// ------------------------------------------------------------------------ //
// MARK: URITemplate.ParseError - Definition
// ------------------------------------------------------------------------ //

extension URITemplate {
  
  public struct ParseError : Error, LocalizedError {
    
    public let template: String
    public let underlyingError: Error
    
    @inlinable
    internal init(template: String, underlyingError: Error) {
      self.template = template
      self.underlyingError = underlyingError
    }
    
    public var errorDescription: String? {
      "The URI template could not be parsed."
    }
    
  }

}
