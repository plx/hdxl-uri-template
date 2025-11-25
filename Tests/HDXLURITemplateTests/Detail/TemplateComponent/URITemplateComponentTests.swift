import Testing
import Foundation
@testable import HDXLURITemplate

extension Tag {
  @Tag
  static var uriTemplateComponent: Self
}

@Suite(.tags(.uriTemplateComponent))
struct URITemplateComponentTests {

  // MARK: - Construction Tests

  @Test
  func `literal component construction`() {
    let component = URITemplateComponent.literal(
      URITemplateLiteralComponent(rawValue: "hello")
    )
    #expect(component.isLiteralComponent)
    #expect(!component.isExpressionComponent)
  }

  @Test
  func `expression component construction`() {
    let component = URITemplateComponent.expression(
      URITemplateExpressionComponent(
        expansionType: .simple,
        variable: URITemplateVariable(
          variableName: URITemplateVariableName(rawValue: "var"),
          expansionModifier: .unmodified
        )
      )
    )
    #expect(component.isExpressionComponent)
    #expect(!component.isLiteralComponent)
  }

  // MARK: - Type Classification Tests

  @Test
  func `templateComponentType for literal`() {
    let component = URITemplateComponent.literal(
      URITemplateLiteralComponent(rawValue: "text")
    )
    #expect(component.templateComponentType == .literal)
  }

  @Test
  func `templateComponentType for expression`() {
    let component = URITemplateComponent.expression(
      URITemplateExpressionComponent(
        expansionType: .query,
        variable: URITemplateVariable(
          variableName: URITemplateVariableName(rawValue: "q"),
          expansionModifier: .unmodified
        )
      )
    )
    #expect(component.templateComponentType == .expression)
  }

  // MARK: - Template Representation Tests

  @Test
  func `templateRepresentation for literal`() {
    let component = URITemplateComponent.literal(
      URITemplateLiteralComponent(rawValue: "https://example.com/")
    )
    #expect(component.templateRepresentation == "https://example.com/")
  }

  @Test
  func `templateRepresentation for simple expression`() {
    let component = URITemplateComponent.expression(
      URITemplateExpressionComponent(
        expansionType: .simple,
        variable: URITemplateVariable(
          variableName: URITemplateVariableName(rawValue: "var"),
          expansionModifier: .unmodified
        )
      )
    )
    #expect(component.templateRepresentation == "{var}")
  }

  @Test
  func `templateRepresentation for query expression`() {
    let component = URITemplateComponent.expression(
      URITemplateExpressionComponent(
        expansionType: .query,
        variable: URITemplateVariable(
          variableName: URITemplateVariableName(rawValue: "query"),
          expansionModifier: .unmodified
        )
      )
    )
    #expect(component.templateRepresentation == "{?query}")
  }

  @Test
  func `templateRepresentation for expression with explode`() {
    let component = URITemplateComponent.expression(
      URITemplateExpressionComponent(
        expansionType: .simple,
        variable: URITemplateVariable(
          variableName: URITemplateVariableName(rawValue: "list"),
          expansionModifier: .explode
        )
      )
    )
    #expect(component.templateRepresentation == "{list*}")
  }

  @Test
  func `templateRepresentation for expression with prefix`() {
    let component = URITemplateComponent.expression(
      URITemplateExpressionComponent(
        expansionType: .simple,
        variable: URITemplateVariable(
          variableName: URITemplateVariableName(rawValue: "name"),
          expansionModifier: .prefix(5)
        )
      )
    )
    #expect(component.templateRepresentation == "{name:5}")
  }

  // MARK: - Variable Injection Tests

  @Test
  func `injectTemplateVariables for literal yields nothing`() {
    let component = URITemplateComponent.literal(
      URITemplateLiteralComponent(rawValue: "literal")
    )
    var variables: Set<URITemplateVariable> = []
    component.injectTemplateVariables(into: &variables)
    #expect(variables.isEmpty)
  }

  @Test
  func `injectTemplateVariables for expression yields variables`() {
    let variable = URITemplateVariable(
      variableName: URITemplateVariableName(rawValue: "test"),
      expansionModifier: .unmodified
    )
    let component = URITemplateComponent.expression(
      URITemplateExpressionComponent(
        expansionType: .simple,
        variable: variable
      )
    )
    var variables: Set<URITemplateVariable> = []
    component.injectTemplateVariables(into: &variables)
    #expect(variables.count == 1)
    #expect(variables.contains(variable))
  }

  @Test
  func `injectTemplateVariables for expression with multiple variables`() {
    let var1 = URITemplateVariable(
      variableName: URITemplateVariableName(rawValue: "x"),
      expansionModifier: .unmodified
    )
    let var2 = URITemplateVariable(
      variableName: URITemplateVariableName(rawValue: "y"),
      expansionModifier: .explode
    )
    let component = URITemplateComponent.expression(
      URITemplateExpressionComponent(
        expansionType: .simple,
        variables: [var1, var2]
      )
    )
    var variables: Set<URITemplateVariable> = []
    component.injectTemplateVariables(into: &variables)
    #expect(variables.count == 2)
  }

  // MARK: - Validity Tests

  @Test
  func `valid literal component`() {
    let component = URITemplateComponent.literal(
      URITemplateLiteralComponent(rawValue: "valid")
    )
    #expect(component.isValid)
  }

  @Test
  func `valid expression component`() {
    let component = URITemplateComponent.expression(
      URITemplateExpressionComponent(
        expansionType: .simple,
        variable: URITemplateVariable(
          variableName: URITemplateVariableName(rawValue: "var"),
          expansionModifier: .unmodified
        )
      )
    )
    #expect(component.isValid)
  }

  // MARK: - Equatable Tests

  @Test
  func `equal literal components are equal`() {
    let component1 = URITemplateComponent.literal(
      URITemplateLiteralComponent(rawValue: "same")
    )
    let component2 = URITemplateComponent.literal(
      URITemplateLiteralComponent(rawValue: "same")
    )
    #expect(component1 == component2)
  }

  @Test
  func `different literal components are not equal`() {
    let component1 = URITemplateComponent.literal(
      URITemplateLiteralComponent(rawValue: "first")
    )
    let component2 = URITemplateComponent.literal(
      URITemplateLiteralComponent(rawValue: "second")
    )
    #expect(component1 != component2)
  }

  @Test
  func `literal and expression are not equal`() {
    let literal = URITemplateComponent.literal(
      URITemplateLiteralComponent(rawValue: "var")
    )
    let expression = URITemplateComponent.expression(
      URITemplateExpressionComponent(
        expansionType: .simple,
        variable: URITemplateVariable(
          variableName: URITemplateVariableName(rawValue: "var"),
          expansionModifier: .unmodified
        )
      )
    )
    #expect(literal != expression)
  }

  // MARK: - Hashable Tests

  @Test
  func `equal components have equal hashes`() {
    let component1 = URITemplateComponent.literal(
      URITemplateLiteralComponent(rawValue: "test")
    )
    let component2 = URITemplateComponent.literal(
      URITemplateLiteralComponent(rawValue: "test")
    )
    #expect(component1.hashValue == component2.hashValue)
  }

  @Test
  func `components work in sets`() {
    let literal1 = URITemplateComponent.literal(
      URITemplateLiteralComponent(rawValue: "a")
    )
    let literal2 = URITemplateComponent.literal(
      URITemplateLiteralComponent(rawValue: "b")
    )
    let literal3 = URITemplateComponent.literal(
      URITemplateLiteralComponent(rawValue: "a")
    )
    let set: Set<URITemplateComponent> = [literal1, literal2, literal3]
    #expect(set.count == 2)
  }

  // MARK: - Comparable Tests

  @Test
  func `literal less than expression`() {
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
  }

  @Test
  func `literals compare by content`() {
    let literal1 = URITemplateComponent.literal(
      URITemplateLiteralComponent(rawValue: "aaa")
    )
    let literal2 = URITemplateComponent.literal(
      URITemplateLiteralComponent(rawValue: "bbb")
    )
    #expect(literal1 < literal2)
  }

  @Test
  func `expressions compare by content`() {
    let expression1 = URITemplateComponent.expression(
      URITemplateExpressionComponent(
        expansionType: .simple,
        variable: URITemplateVariable(
          variableName: URITemplateVariableName(rawValue: "aaa"),
          expansionModifier: .unmodified
        )
      )
    )
    let expression2 = URITemplateComponent.expression(
      URITemplateExpressionComponent(
        expansionType: .simple,
        variable: URITemplateVariable(
          variableName: URITemplateVariableName(rawValue: "bbb"),
          expansionModifier: .unmodified
        )
      )
    )
    #expect(expression1 < expression2)
  }

  // MARK: - Codable Tests

  @Test
  func `literal codable round trip`() throws {
    let original = URITemplateComponent.literal(
      URITemplateLiteralComponent(rawValue: "https://example.com/")
    )
    let encoder = JSONEncoder()
    let data = try encoder.encode(original)
    let decoder = JSONDecoder()
    let decoded = try decoder.decode(URITemplateComponent.self, from: data)
    #expect(original == decoded)
  }

  @Test
  func `expression codable round trip`() throws {
    let original = URITemplateComponent.expression(
      URITemplateExpressionComponent(
        expansionType: .query,
        variable: URITemplateVariable(
          variableName: URITemplateVariableName(rawValue: "search"),
          expansionModifier: .unmodified
        )
      )
    )
    let encoder = JSONEncoder()
    let data = try encoder.encode(original)
    let decoder = JSONDecoder()
    let decoded = try decoder.decode(URITemplateComponent.self, from: data)
    #expect(original == decoded)
  }

  // MARK: - Description Tests

  @Test
  func `literal description contains rawValue`() {
    let component = URITemplateComponent.literal(
      URITemplateLiteralComponent(rawValue: "content")
    )
    #expect(component.description.contains("literal"))
    #expect(component.description.contains("content"))
  }

  @Test
  func `expression description contains expression info`() {
    let component = URITemplateComponent.expression(
      URITemplateExpressionComponent(
        expansionType: .simple,
        variable: URITemplateVariable(
          variableName: URITemplateVariableName(rawValue: "var"),
          expansionModifier: .unmodified
        )
      )
    )
    #expect(component.description.contains("expression"))
  }

  @Test
  func `debugDescription contains type name`() {
    let component = URITemplateComponent.literal(
      URITemplateLiteralComponent(rawValue: "test")
    )
    #expect(component.debugDescription.contains("URITemplateComponent"))
  }

}
