import Foundation

extension URITemplate {

  /// Error thrown when template evaluation fails.
  ///
  /// Contains the template being evaluated, the parameters provided, and any underlying error.
  public struct EvaluationError: Error, LocalizedError {
    /// The template that failed to evaluate.
    public internal(set) var template: URITemplate
    /// The parameters passed to the evaluation.
    public internal(set) var parameters: [String: URIVariableValue]

    /// The underlying error that caused the evaluation failure, if any.
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
  
  /// Evaluates the template with the given parameters, returning the result as a string.
  ///
  /// - Parameter parameters: A dictionary mapping variable names to their values.
  ///
  /// - Returns: The expanded URI template as a string.
  ///
  /// - Throws: `EvaluationError` if evaluation fails.
  @inlinable
  public func evaluateAsString(parameters: [String: URIVariableValue]) throws -> String {
    do {
      var result: String = ""
      result.reserveCapacity(storage.underestimatedExpansionLength)
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
    catch let error {
      throw EvaluationError(
        template: self,
        parameters: parameters,
        underlyingError: error
      )
    }
  }

  /// Evaluates the template with the given parameters, returning a URL.
  ///
  /// - Parameter parameters: A dictionary mapping variable names to their values.
  ///
  /// - Returns: The expanded URI template as a `URL`.
  ///
  /// - Throws: `EvaluationError` if evaluation fails, or `URLError(.badURL)` if the
  ///   expanded string is not a valid URL.
  @inlinable
  public func evaluate(parameters: [String: URIVariableValue]) throws -> URL {
    let stringResult = try evaluateAsString(parameters: parameters)
    guard let url = URL(string: stringResult) else {
      // TODO: extend `EvaluationError` to cover this case, and then make this and the wrapped method both `throws(EvaluationError)`
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
