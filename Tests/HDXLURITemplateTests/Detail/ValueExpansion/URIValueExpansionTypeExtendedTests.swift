import Testing
import Foundation
@testable import HDXLURITemplate

extension Tag {
  @Tag
  static var uriValueExpansionTypeExtended: Self
}

@Suite(.tags(.uriValueExpansionTypeExtended))
struct URIValueExpansionTypeExtendedTests {

  // MARK: - isQueryExpansionType Tests

  @Test
  func `simple is not query expansion`() {
    #expect(!URIValueExpansionType.simple.isQueryExpansionType)
  }

  @Test
  func `reserved is not query expansion`() {
    #expect(!URIValueExpansionType.reserved.isQueryExpansionType)
  }

  @Test
  func `fragment is not query expansion`() {
    #expect(!URIValueExpansionType.fragment.isQueryExpansionType)
  }

  @Test
  func `label is not query expansion`() {
    #expect(!URIValueExpansionType.label.isQueryExpansionType)
  }

  @Test
  func `pathSegment is not query expansion`() {
    #expect(!URIValueExpansionType.pathSegment.isQueryExpansionType)
  }

  @Test
  func `pathParameter is not query expansion`() {
    #expect(!URIValueExpansionType.pathParameter.isQueryExpansionType)
  }

  @Test
  func `query is query expansion`() {
    #expect(URIValueExpansionType.query.isQueryExpansionType)
  }

  @Test
  func `queryContinuation is query expansion`() {
    #expect(URIValueExpansionType.queryContinuation.isQueryExpansionType)
  }

  // MARK: - Format String Tests

  @Test
  func `simple formatString`() {
    #expect(URIValueExpansionType.simple.formatString == "")
  }

  @Test
  func `reserved formatString`() {
    #expect(URIValueExpansionType.reserved.formatString == "+")
  }

  @Test
  func `fragment formatString`() {
    #expect(URIValueExpansionType.fragment.formatString == "#")
  }

  @Test
  func `label formatString`() {
    #expect(URIValueExpansionType.label.formatString == ".")
  }

  @Test
  func `pathSegment formatString`() {
    #expect(URIValueExpansionType.pathSegment.formatString == "/")
  }

  @Test
  func `pathParameter formatString`() {
    #expect(URIValueExpansionType.pathParameter.formatString == ";")
  }

  @Test
  func `query formatString`() {
    #expect(URIValueExpansionType.query.formatString == "?")
  }

  @Test
  func `queryContinuation formatString`() {
    #expect(URIValueExpansionType.queryContinuation.formatString == "&")
  }

  // MARK: - Prefix For Expanded Variable List Tests

  @Test
  func `simple prefixForExpandedVariableList`() {
    let prefix = URIValueExpansionType.simple.prefixForExpandedVariableList
    #expect(prefix.isEmpty)
  }

  @Test
  func `reserved prefixForExpandedVariableList`() {
    let prefix = URIValueExpansionType.reserved.prefixForExpandedVariableList
    #expect(prefix.isEmpty)
  }

  @Test
  func `fragment prefixForExpandedVariableList`() {
    let prefix = URIValueExpansionType.fragment.prefixForExpandedVariableList
    #expect(prefix == "#")
  }

  @Test
  func `label prefixForExpandedVariableList`() {
    let prefix = URIValueExpansionType.label.prefixForExpandedVariableList
    #expect(prefix == ".")
  }

  @Test
  func `pathSegment prefixForExpandedVariableList`() {
    let prefix = URIValueExpansionType.pathSegment.prefixForExpandedVariableList
    #expect(prefix == "/")
  }

  @Test
  func `pathParameter prefixForExpandedVariableList`() {
    let prefix = URIValueExpansionType.pathParameter.prefixForExpandedVariableList
    #expect(prefix == ";")
  }

  @Test
  func `query prefixForExpandedVariableList`() {
    let prefix = URIValueExpansionType.query.prefixForExpandedVariableList
    #expect(prefix == "?")
  }

  @Test
  func `queryContinuation prefixForExpandedVariableList`() {
    let prefix = URIValueExpansionType.queryContinuation.prefixForExpandedVariableList
    #expect(prefix == "&")
  }

  // MARK: - Separator For Expanded Variable List Tests

  @Test
  func `simple separatorForExpandedVariableList`() {
    let separator = URIValueExpansionType.simple.separatorForExpandedVariableList
    #expect(separator == ",")
  }

  @Test
  func `reserved separatorForExpandedVariableList`() {
    let separator = URIValueExpansionType.reserved.separatorForExpandedVariableList
    #expect(separator == ",")
  }

  @Test
  func `fragment separatorForExpandedVariableList`() {
    let separator = URIValueExpansionType.fragment.separatorForExpandedVariableList
    #expect(separator == ",")
  }

  @Test
  func `label separatorForExpandedVariableList`() {
    let separator = URIValueExpansionType.label.separatorForExpandedVariableList
    #expect(separator == ".")
  }

  @Test
  func `pathSegment separatorForExpandedVariableList`() {
    let separator = URIValueExpansionType.pathSegment.separatorForExpandedVariableList
    #expect(separator == "/")
  }

  @Test
  func `pathParameter separatorForExpandedVariableList`() {
    let separator = URIValueExpansionType.pathParameter.separatorForExpandedVariableList
    #expect(separator == ";")
  }

  @Test
  func `query separatorForExpandedVariableList`() {
    let separator = URIValueExpansionType.query.separatorForExpandedVariableList
    #expect(separator == "&")
  }

  @Test
  func `queryContinuation separatorForExpandedVariableList`() {
    let separator = URIValueExpansionType.queryContinuation.separatorForExpandedVariableList
    #expect(separator == "&")
  }

  // MARK: - Invalid Format String Tests

  @Test
  func `invalid format string returns nil`() {
    #expect(URIValueExpansionType(formatString: "invalid") == nil)
    #expect(URIValueExpansionType(formatString: "x") == nil)
    #expect(URIValueExpansionType(formatString: "??") == nil)
  }

  // MARK: - Codable Tests

  @Test(arguments: URIValueExpansionType.allCases)
  func `codable round trip`(expansionType: URIValueExpansionType) throws {
    let encoder = JSONEncoder()
    let data = try encoder.encode(expansionType)
    let decoder = JSONDecoder()
    let decoded = try decoder.decode(URIValueExpansionType.self, from: data)
    #expect(expansionType == decoded)
  }

}

// MARK: - URIValueExpansionModifier Extended Tests

@Suite(.tags(.uriValueExpansionModifier))
struct URIValueExpansionModifierExtendedTests {

  // MARK: - Template Representation Tests

  @Test
  func `unmodified templateRepresentation is empty`() {
    #expect(URIValueExpansionModifier.unmodified.templateRepresentation == "")
  }

  @Test
  func `explode templateRepresentation is asterisk`() {
    #expect(URIValueExpansionModifier.explode.templateRepresentation == "*")
  }

  @Test
  func `prefix templateRepresentation includes count`() {
    #expect(URIValueExpansionModifier.prefix(5).templateRepresentation == ":5")
    #expect(URIValueExpansionModifier.prefix(100).templateRepresentation == ":100")
    #expect(URIValueExpansionModifier.prefix(9999).templateRepresentation == ":9999")
  }

  // MARK: - Validity Tests

  @Test
  func `unmodified is always valid`() {
    #expect(URIValueExpansionModifier.unmodified.isValid)
  }

  @Test
  func `explode is always valid`() {
    #expect(URIValueExpansionModifier.explode.isValid)
  }

  @Test
  func `prefix with valid range is valid`() {
    #expect(URIValueExpansionModifier.prefix(1).isValid)
    #expect(URIValueExpansionModifier.prefix(100).isValid)
    #expect(URIValueExpansionModifier.prefix(9999).isValid)
  }

  @Test
  func `prefix boundary values`() {
    #expect(URIValueExpansionModifier.prefix(1).isValid) // minimum
    #expect(URIValueExpansionModifier.prefix(9999).isValid) // maximum
  }

  // MARK: - Codable Tests

  @Test
  func `unmodified codable round trip`() throws {
    let original = URIValueExpansionModifier.unmodified
    let encoder = JSONEncoder()
    let data = try encoder.encode(original)
    let decoder = JSONDecoder()
    let decoded = try decoder.decode(URIValueExpansionModifier.self, from: data)
    #expect(original == decoded)
  }

  @Test
  func `explode codable round trip`() throws {
    let original = URIValueExpansionModifier.explode
    let encoder = JSONEncoder()
    let data = try encoder.encode(original)
    let decoder = JSONDecoder()
    let decoded = try decoder.decode(URIValueExpansionModifier.self, from: data)
    #expect(original == decoded)
  }

  @Test
  func `prefix codable round trip`() throws {
    let original = URIValueExpansionModifier.prefix(42)
    let encoder = JSONEncoder()
    let data = try encoder.encode(original)
    let decoder = JSONDecoder()
    let decoded = try decoder.decode(URIValueExpansionModifier.self, from: data)
    #expect(original == decoded)
  }

  @Test
  func `prefix boundary codable round trip`() throws {
    // Test minimum
    let minimum = URIValueExpansionModifier.prefix(1)
    let minData = try JSONEncoder().encode(minimum)
    let decodedMin = try JSONDecoder().decode(URIValueExpansionModifier.self, from: minData)
    #expect(minimum == decodedMin)

    // Test maximum
    let maximum = URIValueExpansionModifier.prefix(9999)
    let maxData = try JSONEncoder().encode(maximum)
    let decodedMax = try JSONDecoder().decode(URIValueExpansionModifier.self, from: maxData)
    #expect(maximum == decodedMax)
  }

  // MARK: - Comparable Extended Tests

  @Test
  func `unmodified less than explode`() {
    #expect(URIValueExpansionModifier.unmodified < URIValueExpansionModifier.explode)
  }

  @Test
  func `explode less than any prefix`() {
    #expect(URIValueExpansionModifier.explode < URIValueExpansionModifier.prefix(1))
    #expect(URIValueExpansionModifier.explode < URIValueExpansionModifier.prefix(9999))
  }

  @Test
  func `prefixes compare by value`() {
    #expect(URIValueExpansionModifier.prefix(1) < URIValueExpansionModifier.prefix(2))
    #expect(URIValueExpansionModifier.prefix(100) < URIValueExpansionModifier.prefix(200))
    #expect(!(URIValueExpansionModifier.prefix(50) < URIValueExpansionModifier.prefix(50)))
    #expect(!(URIValueExpansionModifier.prefix(100) < URIValueExpansionModifier.prefix(50)))
  }

  @Test
  func `unmodified not less than itself`() {
    let a = URIValueExpansionModifier.unmodified
    let b = URIValueExpansionModifier.unmodified
    #expect(!(a < b))
  }

  @Test
  func `explode not less than itself`() {
    let a = URIValueExpansionModifier.explode
    let b = URIValueExpansionModifier.explode
    #expect(!(a < b))
  }

}

// MARK: - URIValueExpansionModifierType Extended Tests

@Suite(.tags(.uriValueExpansionModifier))
struct URIValueExpansionModifierTypeExtendedTests {

  // MARK: - Codable Tests

  @Test(arguments: URIValueExpansionModifierType.allCases)
  func `codable round trip`(modifierType: URIValueExpansionModifierType) throws {
    let encoder = JSONEncoder()
    let data = try encoder.encode(modifierType)
    let decoder = JSONDecoder()
    let decoded = try decoder.decode(URIValueExpansionModifierType.self, from: data)
    #expect(modifierType == decoded)
  }

  // MARK: - Comparable Tests

  @Test
  func `modifier types are ordered correctly`() {
    verifyOrderedAscending(URIValueExpansionModifierType.allCases)
  }

  @Test
  func `unmodified less than explode`() {
    #expect(URIValueExpansionModifierType.unmodified < URIValueExpansionModifierType.explode)
  }

  @Test
  func `explode less than prefix`() {
    #expect(URIValueExpansionModifierType.explode < URIValueExpansionModifierType.prefix)
  }

}
