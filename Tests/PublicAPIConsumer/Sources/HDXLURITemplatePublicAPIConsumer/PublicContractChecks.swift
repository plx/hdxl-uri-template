import Foundation
import HDXLURITemplate

func publicPrefixExample() throws {
  let template = try URITemplate(parsing: "{value:3}")
  let rendered = try template.evaluateAsString(
    parameters: [
      "value": .text("abcdef")
    ]
  )

  precondition(rendered == "abc")
}

func publicErrorExamples() throws {
  let malformedTemplate = "{"
  do {
    _ = try URITemplate(parsing: malformedTemplate)
    preconditionFailure("Expected malformed URI-template source to fail.")
  } catch let error as URITemplate.ParseError {
    let erasedError: any Error = error
    let recoveredError = erasedError as? URITemplate.ParseError
    let foundationError = erasedError as NSError

    precondition(recoveredError?.template == malformedTemplate)
    precondition(recoveredError?.kind == .unterminatedExpression)
    precondition(recoveredError?.sourceRange == 1..<1)
    precondition(
      foundationError.localizedDescription
        == "The URI template could not be parsed."
    )
    precondition(
      foundationError.localizedFailureReason
        == "An expression is missing its closing brace."
    )
  }

  let prefixTemplate = try URITemplate(
    parsing: "https://example.com/{items:1}"
  )
  do {
    _ = try prefixTemplate.evaluateAsString(
      parameters: [
        "items": .list(["first", "second"])
      ]
    )
    preconditionFailure("Expected a list prefix modifier to fail.")
  } catch let error as URITemplate.EvaluationError {
    let erasedError: any Error = error
    let recoveredError = erasedError as? URITemplate.EvaluationError
    let foundationError = erasedError as NSError

    precondition(recoveredError?.kind == .prefixModifierNotApplicable)
    precondition(recoveredError?.failingVariableName == "items")
    precondition(recoveredError?.prefixModifierCodePointCount == 1)
    precondition(recoveredError?.failingValueType == .list)
    precondition(
      foundationError.localizedDescription
        == "The URI template could not be evaluated."
    )
    precondition(
      foundationError.localizedFailureReason?
        .contains("Prefix modifier `:1`") == true
    )
  }

  do {
    _ = try URIVariableValue.association([
      ("duplicate", "first"),
      ("duplicate", "second"),
    ])
    preconditionFailure("Expected duplicate association keys to fail.")
  } catch let error as URIVariableValue.AssociationError {
    let erasedError: any Error = error
    let recoveredError =
      erasedError as? URIVariableValue.AssociationError
    let foundationError = erasedError as NSError

    precondition(
      recoveredError
        == .duplicateKey(firstIndex: 0, duplicateIndex: 1)
    )
    precondition(
      foundationError.domain
        == URIVariableValue.AssociationError.errorDomain
    )
    precondition(foundationError.code == 1)
    precondition(
      foundationError.localizedDescription
        == "Association keys must be unique."
    )
  }
}

func publicTemplateCodableExamples() throws {
  let templates = [
    try URITemplate(parsing: "https://example.com{/path}{?query}"),
    try URITemplate(parsing: "{value:3}"),
  ]

  try requireJSONAndPropertyListRoundTrip(templates)
}

func publicImmutableTemplateCopyExample() throws {
  var source = "https://example.com{/resource}{?query}"
  let original = try URITemplate(parsing: source)
  let copy = original
  source.append("-changed")

  precondition(
    original.templateRepresentation
      == "https://example.com{/resource}{?query}"
  )
  precondition(copy.templateRepresentation == original.templateRepresentation)
  precondition(copy.variableNames == ["resource", "query"])
  precondition(copy == original)
  precondition(copy.hashValue == original.hashValue)
  let copiedExpansion = try copy.evaluateAsString(
    parameters: [
      "resource": .text("users"),
      "query": .text("swift concurrency"),
    ]
  )
  precondition(
    copiedExpansion
      == "https://example.com/users?query=swift%20concurrency"
  )
}

func publicConcurrencyExample() async throws {
  let source = "https://example.com{/resource}{?query}"
  let template = try URITemplate(parsing: source)
  let equivalentTemplate = try URITemplate(parsing: source)
  let expectedNames: Set<String> = ["resource", "query"]
  let operationCount = 64

  let completedOperations = try await withThrowingTaskGroup(
    of: Int.self,
    returning: Set<Int>.self
  ) { group in
    for index in 0..<operationCount {
      group.addTask {
        precondition(template.templateRepresentation == source)
        precondition(template.variableNames == expectedNames)
        precondition(template == equivalentTemplate)
        precondition(template.hashValue == equivalentTemplate.hashValue)
        let rendered = try template.evaluateAsString(
          parameters: [
            "resource": .text(String(index)),
            "query": .text("swift concurrency"),
          ]
        )
        precondition(
          rendered
            == "https://example.com/\(index)?query=swift%20concurrency"
        )
        return index
      }
    }

    var completed: Set<Int> = []
    for try await index in group {
      completed.insert(index)
    }
    return completed
  }

  precondition(completedOperations == Set(0..<operationCount))
}

private func requireJSONAndPropertyListRoundTrip<Value>(
  _ values: [Value]
) throws where Value: Codable & Equatable {
  let jsonData = try JSONEncoder().encode(values)
  let jsonValues = try JSONDecoder().decode(
    [Value].self,
    from: jsonData
  )
  precondition(jsonValues == values)

  let propertyListData = try PropertyListEncoder().encode(values)
  let propertyListValues = try PropertyListDecoder().decode(
    [Value].self,
    from: propertyListData
  )
  precondition(propertyListValues == values)
}
