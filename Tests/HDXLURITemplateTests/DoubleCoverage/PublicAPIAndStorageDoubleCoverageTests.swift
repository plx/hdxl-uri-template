import Foundation
import Testing

@testable import HDXLURITemplate

extension Tag {
  @Tag
  static var doubleCoveragePublicAPI: Self
}

@Test(
  "Manual public template API coverage",
  .tags(.doubleCoveragePublicAPI)
)
private func manualPublicTemplateAPICoverage() throws {
  // This example has literal, path, query, and empty-string components so the public API drives storage rendering, variable discovery, URL evaluation, and text expansion together.
  let template = try URITemplate(parsing: "https://example.com{/id}{?q,empty}")
  let parameters: [String: URIVariableValue] = [
    "id": .text("users"),
    "q": .text("uri templates"),
    "empty": .text(""),
  ]

  #expect(template.isValid)
  #expect(template.templateRepresentation == "https://example.com{/id}{?q,empty}")
  #expect(template.variableNames == ["id", "q", "empty"])
  #expect(template.description.contains("https://example.com"))
  #expect(template.debugDescription.contains("URITemplate"))
  #expect(
    try template.evaluateAsString(parameters: parameters)
      == "https://example.com/users?q=uri%20templates&empty="
  )
  #expect(
    try template.evaluate(parameters: parameters)
      == URL(string: "https://example.com/users?q=uri%20templates&empty=")
  )
  // A rendered string that `URL` rejects surfaces as `EvaluationError` (with the
  // underlying `URLError` preserved), matching the uniform evaluation-failure contract.
  do {
    _ = try URITemplate(parsing: "https://[").evaluate(parameters: [:])
    Issue.record("Expected an unrepresentable-URL evaluation to throw.")
  } catch let error as URITemplate.EvaluationError {
    #expect(error.template.templateRepresentation == "https://[")
    #expect(error.underlyingError is URLError)
    #expect(error.kind == .invalidURL)
    #expect(error.kind.description == "invalidURL")
  }

  // Codable, equality, and hashing are part of the public template semantics,
  // so this checks they preserve parsed structure rather than object identity.
  let encoded = try JSONEncoder().encode(template)
  let decoded = try JSONDecoder().decode(URITemplate.self, from: encoded)
  #expect(decoded == template)
  #expect(Set([template, decoded]).count == 1)

  // The public parse error keeps the original template while exposing bounded
  // localized prose.
  do {
    _ = try URITemplate(parsing: "{")
    Issue.record("Expected an unterminated template to throw.")
  } catch let error as URITemplate.ParseError {
    #expect(error.template == "{")
    #expect(error.errorDescription == "The URI template could not be parsed.")
  }

  // EvaluationError provides the same safe description regardless of whether
  // it wraps an internal downstream failure.
  let noUnderlyingError = URITemplate.EvaluationError(template: template, parameters: parameters)
  #expect(noUnderlyingError.errorDescription == "The URI template could not be evaluated.")
  #expect(noUnderlyingError.kind == .other)
  #expect(noUnderlyingError.failingVariableName == nil)
  #expect(noUnderlyingError.expressionOperatorToken == nil)
  #expect(noUnderlyingError.prefixModifierCodePointCount == nil)
  #expect(noUnderlyingError.failingValueType == nil)
  #expect(noUnderlyingError.failureReason?.contains("specific") == true)
  #expect(String(describing: noUnderlyingError.kind) == "other")
  #expect(
    String(reflecting: noUnderlyingError.kind)
      == "URITemplate.EvaluationError.Kind.other"
  )
  let underlyingError = URITemplate.EvaluationError(
    template: template,
    parameters: parameters,
    underlyingError: URLError(.badURL)
  )
  #expect(underlyingError.errorDescription == "The URI template could not be evaluated.")
  #expect(underlyingError.kind == .other)
}

@Test(
  "Property public template API coverage",
  .tags(.doubleCoveragePublicAPI)
)
private func propertyPublicTemplateAPICoverage() throws {
  let names = ["a", "b", "c"]
  let values = ["alpha", "beta gamma", "symbols:/?#[]@"]

  for size in 1...names.count {
    let activeNames = Array(names.prefix(size))
    let variableList = activeNames.joined(separator: ",")
    let templateString = "https://example.com/{\(variableList)}"
    let template = try URITemplate(parsing: templateString)
    let parameters = Dictionary(
      uniqueKeysWithValues: zip(names, values).map { ($0, URIVariableValue.text($1)) }
    )

    let rendered = try template.evaluateAsString(parameters: parameters)
    let renderedPieces =
      rendered
      .replacingOccurrences(of: "https://example.com/", with: "")
      .split(separator: ",")
      .map(String.init)

    #expect(template.variableNames == Set(activeNames))
    #expect(renderedPieces.count == activeNames.count)
    for value in values.prefix(size) {
      #expect(rendered.contains(value.escaped(forValueExpansionType: .simple)))
    }
  }
}

@Test(
  "Manual storage and component coverage",
  .tags(.doubleCoveragePublicAPI)
)
private func manualStorageAndComponentCoverage() throws {
  // Exercise parsed storage, cache reads, exact source retention, and validity
  // explicitly.
  let emptyStorage = try URITemplateStorage(parsing: "")
  #expect(emptyStorage.templateRepresentation == "")
  #expect(emptyStorage.variableNames.isEmpty)
  #expect(emptyStorage.isValid)

  let literalComponent = URITemplateComponent.literal(
    try URITemplateLiteralComponent(parsing: "prefix")
  )
  let variable = try URITemplateVariable(parsing: "id")
  let expression = URITemplateExpressionComponent(expansionType: .pathSegment, variable: variable)
  let expressionComponent = URITemplateComponent.expression(expression)
  let storage = try URITemplateStorage(parsing: "prefix{/id}")

  #expect(storage.templateRepresentation == "prefix{/id}")
  #expect(storage.variableNames == ["id"])
  #expect(storage.description.contains("prefix{/id}"))
  #expect(storage.debugDescription.contains("URITemplateStorage"))
  #expect(storage == storage)
  #expect(storage == (try URITemplateStorage(parsing: "prefix{/id}")))
  #expect(Set([storage, try URITemplateStorage(parsing: "prefix{/id}")]).count == 1)

  // Component APIs are small discriminators, but both cases matter because storage delegates rendering and variable injection through them.
  #expect(literalComponent.isLiteralComponent)
  #expect(!literalComponent.isExpressionComponent)
  #expect(literalComponent.templateComponentType == .literal)
  #expect(literalComponent.templateRepresentation == "prefix")
  #expect(literalComponent.description == ".literal(\"prefix\")")
  #expect(literalComponent.debugDescription.contains("literal"))
  #expect(literalComponent.isValid)
  #expect(literalComponent < expressionComponent)

  #expect(!expressionComponent.isLiteralComponent)
  #expect(expressionComponent.isExpressionComponent)
  #expect(expressionComponent.templateComponentType == .expression)
  #expect(expressionComponent.templateRepresentation == "{/id}")
  #expect(expressionComponent.description.contains(".expression"))
  #expect(expressionComponent.debugDescription.contains("expression"))
  #expect(expressionComponent.isValid)
  #expect(!(expressionComponent < literalComponent))
  #expect(expression.isEmpty == false)
  #expect(expression.count == 1)

  var receiver: Set<URITemplateVariable> = []
  literalComponent.injectTemplateVariables(into: &receiver)
  #expect(receiver.isEmpty)
  expressionComponent.injectTemplateVariables(into: &receiver)
  #expect(receiver == [variable])
}

@Test(
  "Property storage and component coverage",
  .tags(.doubleCoveragePublicAPI)
)
private func propertyStorageAndComponentCoverage() throws {
  let literals = try ["a", "b", "c"].map {
    URITemplateComponent.literal(try URITemplateLiteralComponent(parsing: $0))
  }
  let variables = try ["a", "b", "c"].map { try URITemplateVariable(parsing: "\($0)*") }
  let expressions = variables.map {
    URITemplateComponent.expression(
      URITemplateExpressionComponent(expansionType: .query, variable: $0)
    )
  }
  let components = literals + expressions

  for lhs in components {
    for rhs in components {
      let expectedOrder = lhs.templateRepresentation < rhs.templateRepresentation
      if lhs.templateComponentType == rhs.templateComponentType {
        #expect((lhs < rhs) == expectedOrder)
      }
    }
  }

  for component in components {
    let storage = try URITemplateStorage(
      parsing: component.templateRepresentation
    )
    #expect(storage.templateRepresentation == component.templateRepresentation)
    #expect(storage.components == [component])
    #expect(storage.isValid == component.isValid)

    var injected: Set<URITemplateVariable> = []
    component.injectTemplateVariables(into: &injected)
    #expect(storage.variableNames == Set(injected.map(\.variableName.rawValue)))
  }

  for template in ["", "literal", "{a}", "pre{?a,b}post"] {
    let storage = try URITemplateStorage(parsing: template)
    #expect(storage.templateRepresentation == template)
    let allComponentsValid = storage.components.allSatisfy(\.isValid)
    #expect(allComponentsValid)
  }
}
