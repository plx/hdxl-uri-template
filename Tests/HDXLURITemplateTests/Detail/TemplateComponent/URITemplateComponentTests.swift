import Testing
import Foundation
@testable import HDXLURITemplate

extension Tag {
  @Tag
  static var uriTemplateComponent: Self
}

@Suite(.tags(.uriTemplateComponent))
struct URITemplateComponentTests {

  // MARK: - Construction and Type Classification Tests

  @Test
  func `construction and type classification`() {
    // literal component
    let literal = URITemplateComponent.literal(
      URITemplateLiteralComponent(rawValue: "hello")
    )
    #expect(literal.isLiteralComponent)
    #expect(!literal.isExpressionComponent)
    #expect(literal.templateComponentType == .literal)

    // expression component
    let expression = URITemplateComponent.expression(
      URITemplateExpressionComponent(
        expansionType: .simple,
        variable: URITemplateVariable(
          variableName: URITemplateVariableName(rawValue: "var"),
          expansionModifier: .unmodified
        )
      )
    )
    #expect(expression.isExpressionComponent)
    #expect(!expression.isLiteralComponent)
    #expect(expression.templateComponentType == .expression)
  }

  // MARK: - Template Representation Tests

  @Test
  func `templateRepresentation`() {
    // literal
    let literal = URITemplateComponent.literal(
      URITemplateLiteralComponent(rawValue: "https://example.com/")
    )
    #expect(literal.templateRepresentation == "https://example.com/")

    // simple expression
    let simple = URITemplateComponent.expression(
      URITemplateExpressionComponent(
        expansionType: .simple,
        variable: URITemplateVariable(
          variableName: URITemplateVariableName(rawValue: "var"),
          expansionModifier: .unmodified
        )
      )
    )
    #expect(simple.templateRepresentation == "{var}")

    // query expression
    let query = URITemplateComponent.expression(
      URITemplateExpressionComponent(
        expansionType: .query,
        variable: URITemplateVariable(
          variableName: URITemplateVariableName(rawValue: "query"),
          expansionModifier: .unmodified
        )
      )
    )
    #expect(query.templateRepresentation == "{?query}")

    // expression with explode
    let explode = URITemplateComponent.expression(
      URITemplateExpressionComponent(
        expansionType: .simple,
        variable: URITemplateVariable(
          variableName: URITemplateVariableName(rawValue: "list"),
          expansionModifier: .explode
        )
      )
    )
    #expect(explode.templateRepresentation == "{list*}")

    // expression with prefix
    let prefix = URITemplateComponent.expression(
      URITemplateExpressionComponent(
        expansionType: .simple,
        variable: URITemplateVariable(
          variableName: URITemplateVariableName(rawValue: "name"),
          expansionModifier: .prefix(5)
        )
      )
    )
    #expect(prefix.templateRepresentation == "{name:5}")
  }

  // MARK: - Variable Injection Tests

  @Test
  func `injectTemplateVariables`() {
    // literal yields nothing
    let literal = URITemplateComponent.literal(
      URITemplateLiteralComponent(rawValue: "literal")
    )
    var literalVariables: Set<URITemplateVariable> = []
    literal.injectTemplateVariables(into: &literalVariables)
    #expect(literalVariables.isEmpty)

    // expression yields single variable
    let variable = URITemplateVariable(
      variableName: URITemplateVariableName(rawValue: "test"),
      expansionModifier: .unmodified
    )
    let expression = URITemplateComponent.expression(
      URITemplateExpressionComponent(
        expansionType: .simple,
        variable: variable
      )
    )
    var expressionVariables: Set<URITemplateVariable> = []
    expression.injectTemplateVariables(into: &expressionVariables)
    #expect(expressionVariables.count == 1)
    #expect(expressionVariables.contains(variable))

    // expression with multiple variables
    let var1 = URITemplateVariable(
      variableName: URITemplateVariableName(rawValue: "x"),
      expansionModifier: .unmodified
    )
    let var2 = URITemplateVariable(
      variableName: URITemplateVariableName(rawValue: "y"),
      expansionModifier: .explode
    )
    let multiVarExpression = URITemplateComponent.expression(
      URITemplateExpressionComponent(
        expansionType: .simple,
        variables: [var1, var2]
      )
    )
    var multiVariables: Set<URITemplateVariable> = []
    multiVarExpression.injectTemplateVariables(into: &multiVariables)
    #expect(multiVariables.count == 2)
  }

  // MARK: - Validity Tests

  @Test
  func `validity`() {
    let validLiteral = URITemplateComponent.literal(
      URITemplateLiteralComponent(rawValue: "valid")
    )
    #expect(validLiteral.isValid)

    let validExpression = URITemplateComponent.expression(
      URITemplateExpressionComponent(
        expansionType: .simple,
        variable: URITemplateVariable(
          variableName: URITemplateVariableName(rawValue: "var"),
          expansionModifier: .unmodified
        )
      )
    )
    #expect(validExpression.isValid)
  }

  // MARK: - Equatable and Hashable Tests

  @Test
  func `equality and hashing`() {
    // equal literals are equal
    let literal1 = URITemplateComponent.literal(
      URITemplateLiteralComponent(rawValue: "same")
    )
    let literal2 = URITemplateComponent.literal(
      URITemplateLiteralComponent(rawValue: "same")
    )
    #expect(literal1 == literal2)
    #expect(literal1.hashValue == literal2.hashValue)

    // different literals are not equal
    let literal3 = URITemplateComponent.literal(
      URITemplateLiteralComponent(rawValue: "different")
    )
    #expect(literal1 != literal3)

    // literal and expression are not equal (even with same content)
    let expression = URITemplateComponent.expression(
      URITemplateExpressionComponent(
        expansionType: .simple,
        variable: URITemplateVariable(
          variableName: URITemplateVariableName(rawValue: "same"),
          expansionModifier: .unmodified
        )
      )
    )
    #expect(literal1 != expression)

    // components work in sets
    let a = URITemplateComponent.literal(URITemplateLiteralComponent(rawValue: "a"))
    let b = URITemplateComponent.literal(URITemplateLiteralComponent(rawValue: "b"))
    let aDuplicate = URITemplateComponent.literal(URITemplateLiteralComponent(rawValue: "a"))
    let set: Set<URITemplateComponent> = [a, b, aDuplicate]
    #expect(set.count == 2)
  }

  // MARK: - Comparable Tests

  @Test
  func `ordering`() {
    // literal < expression (regardless of content)
    let literal = URITemplateComponent.literal(
      URITemplateLiteralComponent(rawValue: "zzz")
    )
    let expression = URITemplateComponent.expression(
      URITemplateExpressionComponent(
        expansionType: .simple,
        variable: URITemplateVariable(
          variableName: URITemplateVariableName(rawValue: "aaa"),
          expansionModifier: .unmodified
        )
      )
    )
    #expect(literal < expression)

    // literals compare by content
    let literalA = URITemplateComponent.literal(
      URITemplateLiteralComponent(rawValue: "aaa")
    )
    let literalB = URITemplateComponent.literal(
      URITemplateLiteralComponent(rawValue: "bbb")
    )
    #expect(literalA < literalB)

    // expressions compare by content
    let expressionA = URITemplateComponent.expression(
      URITemplateExpressionComponent(
        expansionType: .simple,
        variable: URITemplateVariable(
          variableName: URITemplateVariableName(rawValue: "aaa"),
          expansionModifier: .unmodified
        )
      )
    )
    let expressionB = URITemplateComponent.expression(
      URITemplateExpressionComponent(
        expansionType: .simple,
        variable: URITemplateVariable(
          variableName: URITemplateVariableName(rawValue: "bbb"),
          expansionModifier: .unmodified
        )
      )
    )
    #expect(expressionA < expressionB)
  }

  // MARK: - Codable Tests

  @Test
  func `codable round trip`() throws {
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()

    // literal
    let literal = URITemplateComponent.literal(
      URITemplateLiteralComponent(rawValue: "https://example.com/")
    )
    let literalData = try encoder.encode(literal)
    let decodedLiteral = try decoder.decode(URITemplateComponent.self, from: literalData)
    #expect(literal == decodedLiteral)

    // expression
    let expression = URITemplateComponent.expression(
      URITemplateExpressionComponent(
        expansionType: .query,
        variable: URITemplateVariable(
          variableName: URITemplateVariableName(rawValue: "search"),
          expansionModifier: .unmodified
        )
      )
    )
    let expressionData = try encoder.encode(expression)
    let decodedExpression = try decoder.decode(URITemplateComponent.self, from: expressionData)
    #expect(expression == decodedExpression)
  }

  // MARK: - Description Tests

  @Test
  func `descriptions`() {
    let literal = URITemplateComponent.literal(
      URITemplateLiteralComponent(rawValue: "content")
    )
    #expect(literal.description.contains("literal"))
    #expect(literal.description.contains("content"))
    #expect(literal.debugDescription.contains("URITemplateComponent"))

    let expression = URITemplateComponent.expression(
      URITemplateExpressionComponent(
        expansionType: .simple,
        variable: URITemplateVariable(
          variableName: URITemplateVariableName(rawValue: "var"),
          expansionModifier: .unmodified
        )
      )
    )
    #expect(expression.description.contains("expression"))
  }

}
