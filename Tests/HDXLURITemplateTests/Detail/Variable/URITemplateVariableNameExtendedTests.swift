import Testing
import Foundation
@testable import HDXLURITemplate

extension Tag {
  @Tag
  static var uriTemplateVariableNameExtended: Self
}

@Suite(.tags(.uriTemplateVariableNameExtended))
struct URITemplateVariableNameExtendedTests {

  // MARK: - Valid Name Tests

  @Test
  func `simple letter name is valid`() {
    let name = URITemplateVariableName(rawValue: "x")
    #expect(name.isValid)
  }

  @Test
  func `multiple letter name is valid`() {
    let name = URITemplateVariableName(rawValue: "name")
    #expect(name.isValid)
  }

  @Test
  func `name with digits is valid`() {
    let name = URITemplateVariableName(rawValue: "var1")
    #expect(name.isValid)
  }

  @Test
  func `name starting with digit is valid`() {
    let name = URITemplateVariableName(rawValue: "1var")
    #expect(name.isValid)
  }

  @Test
  func `name with underscore is valid`() {
    let name = URITemplateVariableName(rawValue: "var_name")
    #expect(name.isValid)
  }

  @Test
  func `underscore only is valid`() {
    let name = URITemplateVariableName(rawValue: "_")
    #expect(name.isValid)
  }

  @Test
  func `name with dot separator is valid`() {
    let name = URITemplateVariableName(rawValue: "var.name")
    #expect(name.isValid)
  }

  @Test
  func `name with multiple dot separators is valid`() {
    let name = URITemplateVariableName(rawValue: "a.b.c")
    #expect(name.isValid)
  }

  @Test
  func `name with percent encoding is valid`() {
    let name = URITemplateVariableName(rawValue: "%20")
    #expect(name.isValid)
  }

  @Test
  func `name with mixed percent encoding is valid`() {
    let name = URITemplateVariableName(rawValue: "var%2Fname")
    #expect(name.isValid)
  }

  @Test
  func `uppercase letters are valid`() {
    let name = URITemplateVariableName(rawValue: "VAR")
    #expect(name.isValid)
  }

  @Test
  func `mixed case is valid`() {
    let name = URITemplateVariableName(rawValue: "VarName")
    #expect(name.isValid)
  }

  // MARK: - Invalid Name Tests

  @Test
  func `empty string is invalid`() {
    let name = URITemplateVariableName(rawValue: "")
    #expect(!name.isValid)
  }

  @Test
  func `space is invalid`() {
    let name = URITemplateVariableName(rawValue: " ")
    #expect(!name.isValid)
  }

  @Test
  func `name with space is invalid`() {
    let name = URITemplateVariableName(rawValue: "var name")
    #expect(!name.isValid)
  }

  @Test
  func `name ending with dot is invalid`() {
    let name = URITemplateVariableName(rawValue: "var.")
    #expect(!name.isValid)
  }

  @Test
  func `name starting with dot is invalid`() {
    let name = URITemplateVariableName(rawValue: ".var")
    #expect(!name.isValid)
  }

  @Test
  func `consecutive dots are invalid`() {
    let name = URITemplateVariableName(rawValue: "var..name")
    #expect(!name.isValid)
  }

  @Test
  func `special characters are invalid`() {
    let invalidNames = [
      "var@name",
      "var#name",
      "var$name",
      "var!name",
      "var+name",
      "var=name",
      "var&name",
      "var?name",
      "var/name",
      "var:name"
    ]
    for rawValue in invalidNames {
      let name = URITemplateVariableName(rawValue: rawValue)
      #expect(!name.isValid, "Expected '\(rawValue)' to be invalid")
    }
  }

  // MARK: - Codable Tests

  @Test
  func `valid name codable round trip`() throws {
    let original = URITemplateVariableName(rawValue: "validName")
    let encoder = JSONEncoder()
    let data = try encoder.encode(original)
    let decoder = JSONDecoder()
    let decoded = try decoder.decode(URITemplateVariableName.self, from: data)
    #expect(original == decoded)
  }

  @Test
  func `name with dots codable round trip`() throws {
    let original = URITemplateVariableName(rawValue: "path.to.var")
    let encoder = JSONEncoder()
    let data = try encoder.encode(original)
    let decoder = JSONDecoder()
    let decoded = try decoder.decode(URITemplateVariableName.self, from: data)
    #expect(original == decoded)
  }

  @Test
  func `decoding invalid name throws`() {
    let json = "\"invalid name with space\""
    let data = Data(json.utf8)
    #expect(throws: (any Error).self) {
      try JSONDecoder().decode(URITemplateVariableName.self, from: data)
    }
  }

  @Test
  func `decoding empty string throws`() {
    let json = "\"\""
    let data = Data(json.utf8)
    #expect(throws: (any Error).self) {
      try JSONDecoder().decode(URITemplateVariableName.self, from: data)
    }
  }

  // MARK: - Comparable Extended Tests

  @Test
  func `names are ordered lexicographically`() {
    let names = [
      URITemplateVariableName(rawValue: "a"),
      URITemplateVariableName(rawValue: "b"),
      URITemplateVariableName(rawValue: "c"),
      URITemplateVariableName(rawValue: "z")
    ]
    verifyOrderedAscending(names)
  }

  @Test
  func `shorter name before longer with same prefix`() {
    let shorter = URITemplateVariableName(rawValue: "var")
    let longer = URITemplateVariableName(rawValue: "variable")
    #expect(shorter < longer)
  }

  @Test
  func `uppercase before lowercase in ASCII order`() {
    let upper = URITemplateVariableName(rawValue: "A")
    let lower = URITemplateVariableName(rawValue: "a")
    #expect(upper < lower)
  }

  // MARK: - Regex Compilation Tests

  @Test
  func `validation regex compiles successfully`() throws {
    let regex = try URITemplateVariableName.prepareValidationRegularExpression()
    #expect(regex.pattern.count > 0)
  }

  @Test
  func `regex matches simple names`() throws {
    let regex = URITemplateVariableName.validationRegularExpression
    let names = ["x", "var", "name123", "_test", "a1b2"]
    for name in names {
      #expect(regex.matchesEntirety(of: name), "Expected regex to match '\(name)'")
    }
  }

  @Test
  func `regex matches dotted names`() throws {
    let regex = URITemplateVariableName.validationRegularExpression
    let names = ["a.b", "path.to.value", "x.y.z"]
    for name in names {
      #expect(regex.matchesEntirety(of: name), "Expected regex to match '\(name)'")
    }
  }

  @Test
  func `regex rejects invalid names`() throws {
    let regex = URITemplateVariableName.validationRegularExpression
    let invalidNames = ["", " ", "a b", "a..b", ".a", "a."]
    for name in invalidNames {
      #expect(!regex.matchesEntirety(of: name), "Expected regex to reject '\(name)'")
    }
  }

}

// MARK: - URITemplateVariable Extended Tests

@Suite(.tags(.uriTemplateVariable))
struct URITemplateVariableExtendedTests {

  // MARK: - Template Representation Tests

  @Test
  func `unmodified variable template representation`() {
    let variable = URITemplateVariable(
      variableName: URITemplateVariableName(rawValue: "name"),
      expansionModifier: .unmodified
    )
    #expect(variable.templateRepresentation == "name")
  }

  @Test
  func `explode variable template representation`() {
    let variable = URITemplateVariable(
      variableName: URITemplateVariableName(rawValue: "list"),
      expansionModifier: .explode
    )
    #expect(variable.templateRepresentation == "list*")
  }

  @Test
  func `prefix variable template representation`() {
    let variable = URITemplateVariable(
      variableName: URITemplateVariableName(rawValue: "text"),
      expansionModifier: .prefix(10)
    )
    #expect(variable.templateRepresentation == "text:10")
  }

  // MARK: - Validity Tests

  @Test
  func `variable with valid name and modifier is valid`() {
    let variable = URITemplateVariable(
      variableName: URITemplateVariableName(rawValue: "valid"),
      expansionModifier: .unmodified
    )
    #expect(variable.isValid)
  }

  @Test
  func `variable with invalid name is invalid`() {
    let variable = URITemplateVariable(
      variableName: URITemplateVariableName(rawValue: ""),
      expansionModifier: .unmodified
    )
    #expect(!variable.isValid)
  }

  // MARK: - Codable Tests

  @Test
  func `variable codable round trip`() throws {
    let original = URITemplateVariable(
      variableName: URITemplateVariableName(rawValue: "testVar"),
      expansionModifier: .explode
    )
    let encoder = JSONEncoder()
    let data = try encoder.encode(original)
    let decoder = JSONDecoder()
    let decoded = try decoder.decode(URITemplateVariable.self, from: data)
    #expect(original == decoded)
  }

  @Test
  func `variable with prefix codable round trip`() throws {
    let original = URITemplateVariable(
      variableName: URITemplateVariableName(rawValue: "prefixVar"),
      expansionModifier: .prefix(500)
    )
    let encoder = JSONEncoder()
    let data = try encoder.encode(original)
    let decoder = JSONDecoder()
    let decoded = try decoder.decode(URITemplateVariable.self, from: data)
    #expect(original == decoded)
  }

  // MARK: - Comparable Extended Tests

  @Test
  func `variables compare by name first`() {
    let varA = URITemplateVariable(
      variableName: URITemplateVariableName(rawValue: "aaa"),
      expansionModifier: .explode
    )
    let varB = URITemplateVariable(
      variableName: URITemplateVariableName(rawValue: "bbb"),
      expansionModifier: .unmodified
    )
    #expect(varA < varB)
  }

  @Test
  func `same name compares by modifier`() {
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
