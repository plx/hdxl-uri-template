import Foundation
import HDXLURITemplate
import Testing

private let parseErrorDescription =
  "The URI template could not be parsed."
private let evaluationErrorDescription =
  "The URI template could not be evaluated."

@Test("Parse errors provide bounded privacy-safe localized descriptions")
private func parseErrorLocalizedDescription() {
  let sentinel = "PARSE_SENTINEL_4CBB9A21"
  let source =
    String(repeating: "a", count: 20_000)
    + sentinel
    + "{"

  do {
    _ = try URITemplate(parsing: source)
    Issue.record("Expected the malformed template to fail parsing.")
  } catch let error as URITemplate.ParseError {
    #expect(error.template == source)
    #expect(error.errorDescription == parseErrorDescription)
    #expect(error.localizedDescription == parseErrorDescription)
    verifyLocalizedDescription(
      error,
      expected: parseErrorDescription,
      excluding: [sentinel]
    )
  } catch {
    Issue.record("Expected URITemplate.ParseError, received \(error).")
  }
}

@Test("Evaluation errors provide bounded privacy-safe localized descriptions")
private func evaluationErrorLocalizedDescription() throws {
  let templateSentinel = "TEMPLATE_SENTINEL_56E7B911"
  let valueSentinel = "VALUE_SENTINEL_653C9C0D"
  let template = try URITemplate(
    parsing: "https://example.com/\(templateSentinel){value:1}"
  )
  let sensitiveValue = String(
    repeating: valueSentinel,
    count: 4_096
  )
  let parameters: [String: URIVariableValue] = [
    "value": .list([sensitiveValue])
  ]

  do {
    _ = try template.evaluateAsString(parameters: parameters)
    Issue.record("Expected list prefix expansion to fail.")
  } catch let error as URITemplate.EvaluationError {
    #expect(error.template == template)
    #expect(error.parameters == parameters)
    #expect(error.errorDescription == evaluationErrorDescription)
    #expect(error.localizedDescription == evaluationErrorDescription)
    verifyLocalizedDescription(
      error,
      expected: evaluationErrorDescription,
      excluding: [templateSentinel, valueSentinel]
    )
  } catch {
    Issue.record("Expected URITemplate.EvaluationError, received \(error).")
  }
}

private func verifyLocalizedDescription(
  _ error: any Error,
  expected: String,
  excluding sentinels: [String]
) {
  let localizedError = error as? any LocalizedError
  let descriptions = [
    error.localizedDescription,
    localizedError?.errorDescription,
    (error as NSError).localizedDescription,
  ]

  #expect(localizedError != nil)
  for description in descriptions {
    #expect(description == expected)
    #expect((description?.utf8.count ?? .max) <= 128)
    #expect(
      description?.contains("The operation couldn’t be completed")
        == false
    )
    for sentinel in sentinels {
      #expect(description?.contains(sentinel) == false)
    }
  }
}
