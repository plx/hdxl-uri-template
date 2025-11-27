import Testing
import Foundation
@testable import HDXLURITemplate

extension Tag {
  @Tag
  static var uriTemplateVariableNameExtended: Self
}

@Suite(.tags(.uriTemplateVariableNameExtended))
struct URITemplateVariableNameExtendedTests {

  // MARK: - Validity Tests

  @Test
  func `valid names`() {
    // simple letter names
    #expect(URITemplateVariableName(rawValue: "x").isValid)
    #expect(URITemplateVariableName(rawValue: "name").isValid)

    // names with digits
    #expect(URITemplateVariableName(rawValue: "var1").isValid)
    #expect(URITemplateVariableName(rawValue: "1var").isValid)

    // names with underscores
    #expect(URITemplateVariableName(rawValue: "var_name").isValid)
    #expect(URITemplateVariableName(rawValue: "_").isValid)

    // names with dot separators
    #expect(URITemplateVariableName(rawValue: "var.name").isValid)
    #expect(URITemplateVariableName(rawValue: "a.b.c").isValid)

    // names with percent encoding
    #expect(URITemplateVariableName(rawValue: "%20").isValid)
    #expect(URITemplateVariableName(rawValue: "var%2Fname").isValid)

    // case variations
    #expect(URITemplateVariableName(rawValue: "VAR").isValid)
    #expect(URITemplateVariableName(rawValue: "VarName").isValid)
  }

  @Test
  func `invalid names`() {
    // empty and whitespace
    #expect(!URITemplateVariableName(rawValue: "").isValid)
    #expect(!URITemplateVariableName(rawValue: " ").isValid)
    #expect(!URITemplateVariableName(rawValue: "var name").isValid)

    // dot issues
    #expect(!URITemplateVariableName(rawValue: "var.").isValid)
    #expect(!URITemplateVariableName(rawValue: ".var").isValid)
    #expect(!URITemplateVariableName(rawValue: "var..name").isValid)

    // special characters
    let invalidNames = [
      "var@name", "var#name", "var$name", "var!name", "var+name",
      "var=name", "var&name", "var?name", "var/name", "var:name"
    ]
    for rawValue in invalidNames {
      #expect(!URITemplateVariableName(rawValue: rawValue).isValid, "Expected '\(rawValue)' to be invalid")
    }
  }

  // MARK: - Codable Tests

  @Test
  func `codable round trip`() throws {
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()

    // valid name
    let validName = URITemplateVariableName(rawValue: "validName")
    let validData = try encoder.encode(validName)
    let decodedValid = try decoder.decode(URITemplateVariableName.self, from: validData)
    #expect(validName == decodedValid)

    // name with dots
    let dottedName = URITemplateVariableName(rawValue: "path.to.var")
    let dottedData = try encoder.encode(dottedName)
    let decodedDotted = try decoder.decode(URITemplateVariableName.self, from: dottedData)
    #expect(dottedName == decodedDotted)
  }

  @Test
  func `decoding invalid names throws`() {
    // invalid name with space
    let invalidJson = "\"invalid name with space\""
    let invalidData = Data(invalidJson.utf8)
    #expect(throws: (any Error).self) {
      try JSONDecoder().decode(URITemplateVariableName.self, from: invalidData)
    }

    // empty string
    let emptyJson = "\"\""
    let emptyData = Data(emptyJson.utf8)
    #expect(throws: (any Error).self) {
      try JSONDecoder().decode(URITemplateVariableName.self, from: emptyData)
    }
  }

  // MARK: - Comparable Tests

  @Test
  func `ordering`() {
    // lexicographic ordering
    let names = [
      URITemplateVariableName(rawValue: "a"),
      URITemplateVariableName(rawValue: "b"),
      URITemplateVariableName(rawValue: "c"),
      URITemplateVariableName(rawValue: "z")
    ]
    verifyOrderedAscending(names)

    // shorter name before longer with same prefix
    let shorter = URITemplateVariableName(rawValue: "var")
    let longer = URITemplateVariableName(rawValue: "variable")
    #expect(shorter < longer)

    // uppercase before lowercase in ASCII order
    let upper = URITemplateVariableName(rawValue: "A")
    let lower = URITemplateVariableName(rawValue: "a")
    #expect(upper < lower)
  }

  // MARK: - Regex Tests

  @Test
  func `validation regex`() throws {
    let regex = try URITemplateVariableName.prepareValidationRegularExpression()
    #expect(regex.pattern.count > 0)

    let validationRegex = URITemplateVariableName.validationRegularExpression

    // matches simple names
    let simpleNames = ["x", "var", "name123", "_test", "a1b2"]
    for name in simpleNames {
      #expect(validationRegex.matchesEntirety(of: name), "Expected regex to match '\(name)'")
    }

    // matches dotted names
    let dottedNames = ["a.b", "path.to.value", "x.y.z"]
    for name in dottedNames {
      #expect(validationRegex.matchesEntirety(of: name), "Expected regex to match '\(name)'")
    }

    // rejects invalid names
    let invalidNames = ["", " ", "a b", "a..b", ".a", "a."]
    for name in invalidNames {
      #expect(!validationRegex.matchesEntirety(of: name), "Expected regex to reject '\(name)'")
    }
  }

}

// MARK: - URITemplateVariable Extended Tests

@Suite(.tags(.uriTemplateVariable))
struct URITemplateVariableExtendedTests {

  // MARK: - Template Representation Tests

  @Test
  func `templateRepresentation`() {
    // unmodified
    let unmodified = URITemplateVariable(
      variableName: URITemplateVariableName(rawValue: "name"),
      expansionModifier: .unmodified
    )
    #expect(unmodified.templateRepresentation == "name")

    // explode
    let explode = URITemplateVariable(
      variableName: URITemplateVariableName(rawValue: "list"),
      expansionModifier: .explode
    )
    #expect(explode.templateRepresentation == "list*")

    // prefix
    let prefix = URITemplateVariable(
      variableName: URITemplateVariableName(rawValue: "text"),
      expansionModifier: .prefix(10)
    )
    #expect(prefix.templateRepresentation == "text:10")
  }

  // MARK: - Validity Tests

  @Test
  func `validity`() {
    // valid name and modifier
    let valid = URITemplateVariable(
      variableName: URITemplateVariableName(rawValue: "valid"),
      expansionModifier: .unmodified
    )
    #expect(valid.isValid)

    // invalid name
    let invalid = URITemplateVariable(
      variableName: URITemplateVariableName(rawValue: ""),
      expansionModifier: .unmodified
    )
    #expect(!invalid.isValid)
  }

  // MARK: - Codable Tests

  @Test
  func `codable round trip`() throws {
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()

    // with explode modifier
    let explodeVar = URITemplateVariable(
      variableName: URITemplateVariableName(rawValue: "testVar"),
      expansionModifier: .explode
    )
    let explodeData = try encoder.encode(explodeVar)
    let decodedExplode = try decoder.decode(URITemplateVariable.self, from: explodeData)
    #expect(explodeVar == decodedExplode)

    // with prefix modifier
    let prefixVar = URITemplateVariable(
      variableName: URITemplateVariableName(rawValue: "prefixVar"),
      expansionModifier: .prefix(500)
    )
    let prefixData = try encoder.encode(prefixVar)
    let decodedPrefix = try decoder.decode(URITemplateVariable.self, from: prefixData)
    #expect(prefixVar == decodedPrefix)
  }

  // MARK: - Comparable Tests

  @Test
  func `ordering`() {
    // compares by name first
    let varA = URITemplateVariable(
      variableName: URITemplateVariableName(rawValue: "aaa"),
      expansionModifier: .explode
    )
    let varB = URITemplateVariable(
      variableName: URITemplateVariableName(rawValue: "bbb"),
      expansionModifier: .unmodified
    )
    #expect(varA < varB)

    // same name compares by modifier
    let varUnmod = URITemplateVariable(
      variableName: URITemplateVariableName(rawValue: "same"),
      expansionModifier: .unmodified
    )
    let varExplode = URITemplateVariable(
      variableName: URITemplateVariableName(rawValue: "same"),
      expansionModifier: .explode
    )
    #expect(varUnmod < varExplode)
  }

}
