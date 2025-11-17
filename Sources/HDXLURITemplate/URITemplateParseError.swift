import Foundation

// MARK: URITemplate.ParseError

extension URITemplate {
  
  public struct ParseError : Error, LocalizedError {
    
    public let template: String
    public let underlyingError: Error
    
    @inlinable
    internal init(
      template: String, 
      underlyingError: Error
    ) {
      self.template = template
      self.underlyingError = underlyingError
    }
    
    public var localizedDescription: String {
      """
      Couldn't parse template-string "\(template)" due to underlying-error: \(underlyingError.bestAvailableExplanation)
      """
    }
    
  }

}
