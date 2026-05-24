import Foundation

extension URITemplate {
  
  public struct EvaluationError: Error, LocalizedError {
    public internal(set) var template: URITemplate
    public internal(set) var parameters: [String: URIVariableValue]
    
    public internal(set) var underlyingError: Error?
    
    @usableFromInline
    internal init(
      template: URITemplate,
      parameters: [String : URIVariableValue],
      underlyingError: Error? = nil
    ) {
      self.template = template
      self.parameters = parameters
      self.underlyingError = underlyingError
    }
    
    public var localizedDescription: String {
      let baseMessage =
      """
      Error evaluating template `\(template.templateRepresentation)` on parameters: \(parameters.errorMessageRepresentation).
      """
      
      guard let underlyingError else {
        return baseMessage
      }
      
      return
        """
        \(baseMessage)
        
        Underlying error: \(String(reflecting: underlyingError))
        """
    }
  }
  
  @inlinable
  public func evaluateAsString(parameters: [String: URIVariableValue]) throws -> String {
    var result: String = ""
    for component in storage.components {
      switch component {
      case .literal(let literal):
        result.append(contentsOf: literal.rawValue)
      case .expression(let expression):
        result.append(contentsOf: try expression.evaluate(parameters: parameters))
      }
    }
    
    return result
  }

  @inlinable
  public func evaluate(parameters: [String: URIVariableValue]) throws -> URL {
    let stringResult = try evaluateAsString(parameters: parameters)
    guard let url = URL(string: stringResult) else {
      // TODO:
      throw URLError(
        .badURL,
        userInfo: [
          NSLocalizedDescriptionKey :
          """
          Rendered template `\(templateRepresentation)` succeeded-as `\(stringResult)`, but failed to produce a valid URL! 
          """
        ]
      )
    }
    return url
  }

}

extension Dictionary where Key == String, Value == URIVariableValue {
  
  @usableFromInline
  internal var errorMessageRepresentation: String {
    let memberRepresentation = lazy.map { key, value in
      "\(key): \(value.errorMessageRepresentation)"
    }.joined(separator: ", ")
    return "[ \(memberRepresentation) ]"
  }
  
}
