import Testing
import Foundation
@testable import HDXLURITemplate

extension Tag {
  @Tag
  static var uriTemplate: Self
}

@Suite(.tags(.uriTemplate))
struct URITemplateTests {

  // MARK: - Parsing Tests

  @Test
  func `parses empty template`() throws {
    let template = try URITemplate(parsing: "")
    #expect(template.templateRepresentation == "")
    #expect(template.variableNames.isEmpty)
  }

  @Test
  func `parses literal-only template`() throws {
    let template = try URITemplate(parsing: "https://example.com/path")
    #expect(template.templateRepresentation == "https://example.com/path")
    #expect(template.variableNames.isEmpty)
  }

  @Test
  func `parses simple variable template`() throws {
    let template = try URITemplate(parsing: "{var}")
    #expect(template.variableNames == ["var"])
  }

  @Test
  func `parses multiple variables template`() throws {
    let template = try URITemplate(parsing: "{x}/{y}/{z}")
    #expect(template.variableNames == ["x", "y", "z"])
  }

  @Test
  func `parses reserved expansion template`() throws {
    let template = try URITemplate(parsing: "{+path}")
    #expect(template.variableNames == ["path"])
  }

  @Test
  func `parses fragment expansion template`() throws {
    let template = try URITemplate(parsing: "{#anchor}")
    #expect(template.variableNames == ["anchor"])
  }

  @Test
  func `parses query expansion template`() throws {
    let template = try URITemplate(parsing: "{?query}")
    #expect(template.variableNames == ["query"])
  }

  @Test
  func `parses query continuation template`() throws {
    let template = try URITemplate(parsing: "{&more}")
    #expect(template.variableNames == ["more"])
  }

  @Test
  func `parses label expansion template`() throws {
    let template = try URITemplate(parsing: "{.ext}")
    #expect(template.variableNames == ["ext"])
  }

  @Test
  func `parses path segment template`() throws {
    let template = try URITemplate(parsing: "{/path}")
    #expect(template.variableNames == ["path"])
  }

  @Test
  func `parses path parameter template`() throws {
    let template = try URITemplate(parsing: "{;param}")
    #expect(template.variableNames == ["param"])
  }

  @Test
  func `parses explode modifier template`() throws {
    let template = try URITemplate(parsing: "{list*}")
    #expect(template.variableNames == ["list"])
  }

  @Test
  func `parses prefix modifier template`() throws {
    let template = try URITemplate(parsing: "{var:3}")
    #expect(template.variableNames == ["var"])
  }

  @Test
  func `parses complex template`() throws {
    let template = try URITemplate(parsing: "https://api.example.com/{version}/users/{userId}{?fields,sort}")
    #expect(template.variableNames == ["version", "userId", "fields", "sort"])
  }

  @Test
  func `parses variable with dots in name`() throws {
    let template = try URITemplate(parsing: "{var.name}")
    #expect(template.variableNames == ["var.name"])
  }

  // MARK: - Parse Error Tests

  @Test
  func `throws on unclosed expression`() {
    #expect(throws: URITemplate.ParseError.self) {
      try URITemplate(parsing: "{unclosed")
    }
  }

  // MARK: - Evaluation Tests

  @Test
  func `evaluates literal template`() throws {
    let template = try URITemplate(parsing: "https://example.com")
    let result = try template.evaluateAsString(parameters: [:])
    #expect(result == "https://example.com")
  }

  @Test
  func `evaluates simple variable`() throws {
    let template = try URITemplate(parsing: "{name}")
    let result = try template.evaluateAsString(parameters: ["name": "fred"])
    #expect(result == "fred")
  }

  @Test
  func `evaluates multiple variables`() throws {
    let template = try URITemplate(parsing: "{x}/{y}")
    let result = try template.evaluateAsString(parameters: ["x": "1", "y": "2"])
    #expect(result == "1/2")
  }

  @Test
  func `evaluates undefined variable as empty`() throws {
    let template = try URITemplate(parsing: "prefix{missing}suffix")
    let result = try template.evaluateAsString(parameters: [:])
    #expect(result == "prefixsuffix")
  }

  @Test
  func `evaluates query expansion`() throws {
    let template = try URITemplate(parsing: "{?query}")
    let result = try template.evaluateAsString(parameters: ["query": "value"])
    #expect(result == "?query=value")
  }

  @Test
  func `evaluates list variable`() throws {
    let template = try URITemplate(parsing: "{list}")
    let result = try template.evaluateAsString(parameters: ["list": .list(["a", "b", "c"])])
    #expect(result == "a,b,c")
  }

  @Test
  func `evaluates exploded list variable`() throws {
    let template = try URITemplate(parsing: "{list*}")
    let result = try template.evaluateAsString(parameters: ["list": .list(["a", "b", "c"])])
    #expect(result == "a,b,c")
  }

  @Test
  func `evaluate returns URL`() throws {
    let template = try URITemplate(parsing: "https://example.com/{path}")
    let url = try template.evaluate(parameters: ["path": "test"])
    #expect(url.absoluteString == "https://example.com/test")
  }

  // MARK: - Equatable Tests

  @Test
  func `equal templates are equal`() throws {
    let template1 = try URITemplate(parsing: "{var}")
    let template2 = try URITemplate(parsing: "{var}")
    #expect(template1 == template2)
  }

  @Test
  func `different templates are not equal`() throws {
    let template1 = try URITemplate(parsing: "{x}")
    let template2 = try URITemplate(parsing: "{y}")
    #expect(template1 != template2)
  }

  // MARK: - Hashable Tests

  @Test
  func `equal templates have equal hashes`() throws {
    let template1 = try URITemplate(parsing: "{var}")
    let template2 = try URITemplate(parsing: "{var}")
    #expect(template1.hashValue == template2.hashValue)
  }

  @Test
  func `templates work in sets`() throws {
    let template1 = try URITemplate(parsing: "{a}")
    let template2 = try URITemplate(parsing: "{b}")
    let template3 = try URITemplate(parsing: "{a}")
    let set: Set<URITemplate> = [template1, template2, template3]
    #expect(set.count == 2)
  }

  // MARK: - Comparable Tests

  @Test
  func `templates are comparable`() throws {
    let template1 = try URITemplate(parsing: "aaa")
    let template2 = try URITemplate(parsing: "bbb")
    #expect(template1 < template2)
  }

  @Test
  func `equal templates are not less than`() throws {
    let template1 = try URITemplate(parsing: "{var}")
    let template2 = try URITemplate(parsing: "{var}")
    #expect(!(template1 < template2))
    #expect(!(template2 < template1))
  }

  // MARK: - Codable Tests

  @Test
  func `codable round trip`() throws {
    let original = try URITemplate(parsing: "https://example.com/{path}{?query}")
    let encoder = JSONEncoder()
    let data = try encoder.encode(original)
    let decoder = JSONDecoder()
    let decoded = try decoder.decode(URITemplate.self, from: data)
    #expect(original == decoded)
    #expect(original.templateRepresentation == decoded.templateRepresentation)
  }

  @Test
  func `codable round trip empty template`() throws {
    let original = try URITemplate(parsing: "")
    let encoder = JSONEncoder()
    let data = try encoder.encode(original)
    let decoder = JSONDecoder()
    let decoded = try decoder.decode(URITemplate.self, from: data)
    #expect(original == decoded)
  }

  @Test
  func `codable round trip complex template`() throws {
    let original = try URITemplate(parsing: "{+reserved}{#fragment}{.label}{/path}{;param}{?query}{&continuation}")
    let encoder = JSONEncoder()
    let data = try encoder.encode(original)
    let decoder = JSONDecoder()
    let decoded = try decoder.decode(URITemplate.self, from: data)
    #expect(original == decoded)
  }

  // MARK: - Description Tests

  @Test
  func `description is template representation`() throws {
    let template = try URITemplate(parsing: "https://example.com/{var}")
    #expect(template.description == template.templateRepresentation)
  }

  @Test
  func `debugDescription contains storage`() throws {
    let template = try URITemplate(parsing: "{var}")
    #expect(template.debugDescription.contains("URITemplate"))
    #expect(template.debugDescription.contains("storage"))
  }

  // MARK: - Validity Tests

  @Test
  func `parsed templates are valid`() throws {
    let template = try URITemplate(parsing: "{var}")
    #expect(template.isValid)
  }

  @Test
  func `empty template is valid`() throws {
    let template = try URITemplate(parsing: "")
    #expect(template.isValid)
  }

}

// MARK: - Parse Error Tests

@Suite(.tags(.uriTemplate))
struct URITemplateParseErrorTests {

  @Test
  func `parse error contains template`() {
    do {
      _ = try URITemplate(parsing: "{invalid{")
      Issue.record("Expected ParseError to be thrown")
    } catch let error as URITemplate.ParseError {
      #expect(error.template == "{invalid{")
    } catch {
      Issue.record("Expected ParseError, got \(type(of: error))")
    }
  }

  @Test
  func `parse error has underlying error`() {
    do {
      _ = try URITemplate(parsing: "{")
      Issue.record("Expected ParseError to be thrown")
    } catch let error as URITemplate.ParseError {
      // underlyingError is non-optional, so just verify it exists by using it
      let _ = error.underlyingError
    } catch {
      Issue.record("Expected ParseError, got \(type(of: error))")
    }
  }

  @Test
  func `parse error localized description mentions template`() {
    do {
      _ = try URITemplate(parsing: "{bad")
      Issue.record("Expected ParseError to be thrown")
    } catch let error as URITemplate.ParseError {
      #expect(error.localizedDescription.contains("{bad"))
    } catch {
      Issue.record("Expected ParseError, got \(type(of: error))")
    }
  }

}

// MARK: - Evaluation Error Tests

@Suite(.tags(.uriTemplate))
struct URITemplateEvaluationErrorTests {

  @Test
  func `evaluation error contains template and parameters`() throws {
    let template = try URITemplate(parsing: "{var}")
    let parameters: [String: URIVariableValue] = ["var": "test"]
    let error = URITemplate.EvaluationError(
      template: template,
      parameters: parameters
    )
    #expect(error.template == template)
    #expect(error.parameters == parameters)
  }

  @Test
  func `evaluation error localized description mentions template`() throws {
    let template = try URITemplate(parsing: "{test}")
    let error = URITemplate.EvaluationError(
      template: template,
      parameters: [:]
    )
    #expect(error.localizedDescription.contains("{test}"))
  }

  @Test
  func `evaluation error localized description includes underlying error`() throws {
    let template = try URITemplate(parsing: "{var}")
    let underlyingError = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "test error"])
    let error = URITemplate.EvaluationError(
      template: template,
      parameters: [:],
      underlyingError: underlyingError
    )
    #expect(error.localizedDescription.contains("Underlying error"))
  }

}
