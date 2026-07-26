import Testing

@testable import HDXLURITemplate

#if HEAVY_DEBUG
  @Test("HEAVY_DEBUG accepts valid literal and variable-name storage")
  private func heavyDebugAcceptsValidInvariantStorage() throws {
    let literal = URITemplateLiteralComponent(rawValue: "users")
    let variableName = URITemplateVariableName(rawValue: "id")
    let template = try URITemplate(parsing: "users{/id}")
    var assertionConditionWasEvaluated = false

    pedanticAssert(
      {
        assertionConditionWasEvaluated = true
        return literal.isValid && variableName.isValid
      }()
    )

    #expect(literal.isValid)
    #expect(variableName.isValid)
    #expect(assertionConditionWasEvaluated)
    #expect(
      try template.evaluateAsString(
        parameters: ["id": .text("42")]
      ) == "users/42"
    )
  }
#endif
