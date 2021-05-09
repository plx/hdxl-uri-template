//
//  URITemplateParseError.swift
//

import Foundation
import HDXLCommonUtilities

// ------------------------------------------------------------------------ //
// MARK: URITemplate.ParseError - Definition
// ------------------------------------------------------------------------ //

public extension URITemplate {
  
  struct ParseError : Error, LocalizedError {
    
    public let template: String
    public let underlyingError: Error
    
    @inlinable
    internal init(template: String, underlyingError: Error) {
      self.template = template
      self.underlyingError = underlyingError
    }
    
    public var localizedDescription: String {
      get {
        return (
          """
          Couldn't parse template-string "\(self.template)" due to underlying-error: \(self.underlyingError.bestAvailableExplanation)
          """
        )
      }
    }
    
  }

}
