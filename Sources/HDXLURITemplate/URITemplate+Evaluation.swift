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
    // This `do`/`catch` is the public failure boundary for evaluation: any
    // error surfaced while expanding a component is re-thrown as an
    // `EvaluationError` carrying the template and parameters, so callers get
    // a uniform error type with diagnostic context (see `SpecificationTests`'
    // `.evaluationFailure` expectation). Composite values with prefix
    // modifiers are one controlled downstream failure surfaced here.
    // That failure is rejected after both the modifier and runtime value
    // flavor are known.
    do {
      var result: String = ""
      for component in storage.components {
        switch component {
        case .literal(let literal):
          result.append(contentsOf: literal.expansionRepresentation)
        case .expression(let expression):
          result.append(contentsOf: try expression.evaluate(parameters: parameters))
        }
      }

      return result
    }
    catch let error {
      throw EvaluationError(
        template: self,
        parameters: parameters,
        underlyingError: error
      )
    }
  }

  @inlinable
  public func evaluate(parameters: [String: URIVariableValue]) throws -> URL {
    let stringResult = try evaluateAsString(parameters: parameters)
    guard let url = URL(string: stringResult) else {
      // A successfully-rendered template can still fail to produce a valid
      // `URL` (e.g. an empty expansion, or literal text `URL` rejects). Wrap
      // this as an `EvaluationError` — like expansion failures — so the
      // public `evaluate(parameters:)` surfaces one consistent error type.
      throw EvaluationError(
        template: self,
        parameters: parameters,
        underlyingError: URLError(
          .badURL,
          userInfo: [
            NSLocalizedDescriptionKey :
            """
            Rendered template `\(templateRepresentation)` succeeded-as `\(stringResult)`, but failed to produce a valid URL!
            """
          ]
        )
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
