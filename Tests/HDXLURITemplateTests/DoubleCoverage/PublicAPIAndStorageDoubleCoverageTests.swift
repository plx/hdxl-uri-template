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
    "empty": .text("")
  ]

  #expect(template.isValid)
  #expect(template.templateRepresentation == "https://example.com{/id}{?q, empty}")
  #expect(template.variableNames == ["id", "q", "empty"])
  #expect(template.description.contains("https://example.com"))
  #expect(template.debugDescription.contains("URITemplate"))
  #expect(try template.evaluateAsString(parameters: parameters) == "https://example.com/users?q=uri%20templates&empty=")
  #expect(try template.evaluate(parameters: parameters) == URL(string: "https://example.com/users?q=uri%20templates&empty="))
  #expect(throws: URLError.self) {
    _ = try URITemplate(parsing: "https://[").evaluate(parameters: [:])
  }

  // Codable and comparison are part of the package's public value semantics, so this checks they preserve the parsed structure rather than object identity.
  let encoded = try JSONEncoder().encode(template)
  let decoded = try JSONDecoder().decode(URITemplate.self, from: encoded)
  #expect(decoded == template)
  #expect(template < (try URITemplate(parsing: "https://example.net/{id}")))

  // The public parse error should keep the original template and expose the underlying parser explanation.
  do {
    _ = try URITemplate(parsing: "{")
    Issue.record("Expected an unterminated template to throw.")
  } catch let error as URITemplate.ParseError {
    #expect(error.template == "{")
    #expect(error.localizedDescription.contains("Couldn't parse template-string"))
  }

  // EvaluationError has user-facing diagnostics even when created from an internal downstream failure.
  let noUnderlyingError = URITemplate.EvaluationError(template: template, parameters: parameters)
  #expect(noUnderlyingError.localizedDescription.contains("Error evaluating template"))
  let underlyingError = URITemplate.EvaluationError(
    template: template,
    parameters: parameters,
    underlyingError: URLError(.badURL)
  )
  #expect(underlyingError.localizedDescription.contains("Underlying error"))
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
    let parameters = Dictionary(uniqueKeysWithValues: zip(names, values).map { ($0, URIVariableValue.text($1)) })

    let rendered = try template.evaluateAsString(parameters: parameters)
    let renderedPieces = rendered
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
  // The storage object owns the cache invalidation path, so this exercises empty storage, component storage, cache reads, mutation, and Codable validation explicitly.
  let emptyStorage = URITemplateStorage()
  #expect(emptyStorage.templateRepresentation == "")
  #expect(emptyStorage.templateVariables.isEmpty)
  #expect(emptyStorage.templateVariablesNames.isEmpty)
  #expect(emptyStorage.variableNames.isEmpty)
  #expect(emptyStorage.isValid)

  let literalComponent = URITemplateComponent.literal(try URITemplateLiteralComponent(parsing: "prefix"))
  let variable = try URITemplateVariable(parsing: "id")
  let expression = URITemplateExpressionComponent(expansionType: .pathSegment, variable: variable)
  let expressionComponent = URITemplateComponent.expression(expression)
  let storage = URITemplateStorage(components: [literalComponent, expressionComponent])

  #expect(storage.templateRepresentation == "prefix{/id}")
  #expect(storage.templateVariables == [variable])
  #expect(storage.templateVariablesNames == [variable.variableName])
  #expect(storage.variableNames == ["id"])
  #expect(storage.description.contains("prefix{/id}"))
  #expect(storage.debugDescription.contains("URITemplateStorage"))
  #expect(storage == storage)
  #expect(storage == URITemplateStorage(components: [literalComponent, expressionComponent]))
  #expect(storage < URITemplateStorage(component: .literal(try URITemplateLiteralComponent(parsing: "z"))))
  #expect(!(storage < storage))
  #expect(Set([storage, URITemplateStorage(components: [literalComponent, expressionComponent])]).count == 1)

  let encoded = try JSONEncoder().encode(storage)
  let decoded = try JSONDecoder().decode(URITemplateStorage.self, from: encoded)
  #expect(decoded.components == storage.components)

  // Assigning equal components should leave caches intact; assigning different components must invalidate and rebuild them.
  let cachedRepresentation = storage.templateRepresentation
  let sameComponents = storage.components
  storage.components = sameComponents
  #expect(storage.templateRepresentation == cachedRepresentation)
  storage.components = [literalComponent]
  #expect(storage.templateRepresentation == "prefix")
  #expect(storage.variableNames.isEmpty)

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
  #expect(expressionComponent.debugDescription.contains("expresssion"))
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
  let literals = try ["a", "b", "c"].map { URITemplateComponent.literal(try URITemplateLiteralComponent(parsing: $0)) }
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
    let storage = URITemplateStorage(component: component)
    #expect(storage.templateRepresentation == component.templateRepresentation)
    #expect(storage.isValid == component.isValid)

    var injected: Set<URITemplateVariable> = []
    component.injectTemplateVariables(into: &injected)
    #expect(storage.templateVariables == injected)
    #expect(storage.variableNames == Set(injected.map(\.variableName.rawValue)))
  }

  for template in ["", "literal", "{a}", "pre{?a,b}post"] {
    let storage = try URITemplateStorage(parsing: template)
    #expect(storage.templateRepresentation == (template == "{?a,b}" ? "{?a, b}" : storage.components.map(\.templateRepresentation).joined()))
    let allComponentsValid = storage.components.allSatisfy(\.isValid)
    #expect(allComponentsValid)
  }
}
