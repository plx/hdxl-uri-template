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
  func `isQueryExpansionType`() {
    // non-query expansion types:
    #expect(!URIValueExpansionType.simple.isQueryExpansionType)
    #expect(!URIValueExpansionType.reserved.isQueryExpansionType)
    #expect(!URIValueExpansionType.fragment.isQueryExpansionType)
    #expect(!URIValueExpansionType.label.isQueryExpansionType)
    #expect(!URIValueExpansionType.pathSegment.isQueryExpansionType)
    #expect(!URIValueExpansionType.pathParameter.isQueryExpansionType)

    // query expansion types:
    #expect(URIValueExpansionType.query.isQueryExpansionType)
    #expect(URIValueExpansionType.queryContinuation.isQueryExpansionType)
  }

  // MARK: - Format String Tests

  @Test
  func `formatString`() {
    #expect(URIValueExpansionType.simple.formatString == "")
    #expect(URIValueExpansionType.reserved.formatString == "+")
    #expect(URIValueExpansionType.fragment.formatString == "#")
    #expect(URIValueExpansionType.label.formatString == ".")
    #expect(URIValueExpansionType.pathSegment.formatString == "/")
    #expect(URIValueExpansionType.pathParameter.formatString == ";")
    #expect(URIValueExpansionType.query.formatString == "?")
    #expect(URIValueExpansionType.queryContinuation.formatString == "&")
  }

  @Test
  func `invalid format string returns nil`() {
    #expect(URIValueExpansionType(formatString: "invalid") == nil)
    #expect(URIValueExpansionType(formatString: "x") == nil)
    #expect(URIValueExpansionType(formatString: "??") == nil)
  }

  // MARK: - Prefix For Expanded Variable List Tests

  @Test
  func `prefixForExpandedVariableList`() {
    // empty prefix types:
    #expect(URIValueExpansionType.simple.prefixForExpandedVariableList.isEmpty)
    #expect(URIValueExpansionType.reserved.prefixForExpandedVariableList.isEmpty)

    // non-empty prefix types:
    #expect(URIValueExpansionType.fragment.prefixForExpandedVariableList == "#")
    #expect(URIValueExpansionType.label.prefixForExpandedVariableList == ".")
    #expect(URIValueExpansionType.pathSegment.prefixForExpandedVariableList == "/")
    #expect(URIValueExpansionType.pathParameter.prefixForExpandedVariableList == ";")
    #expect(URIValueExpansionType.query.prefixForExpandedVariableList == "?")
    #expect(URIValueExpansionType.queryContinuation.prefixForExpandedVariableList == "&")
  }

  // MARK: - Separator For Expanded Variable List Tests

  @Test
  func `separatorForExpandedVariableList`() {
    // comma-separated types:
    #expect(URIValueExpansionType.simple.separatorForExpandedVariableList == ",")
    #expect(URIValueExpansionType.reserved.separatorForExpandedVariableList == ",")
    #expect(URIValueExpansionType.fragment.separatorForExpandedVariableList == ",")

    // other separators:
    #expect(URIValueExpansionType.label.separatorForExpandedVariableList == ".")
    #expect(URIValueExpansionType.pathSegment.separatorForExpandedVariableList == "/")
    #expect(URIValueExpansionType.pathParameter.separatorForExpandedVariableList == ";")
    #expect(URIValueExpansionType.query.separatorForExpandedVariableList == "&")
    #expect(URIValueExpansionType.queryContinuation.separatorForExpandedVariableList == "&")
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
  func `templateRepresentation`() {
    #expect(URIValueExpansionModifier.unmodified.templateRepresentation == "")
    #expect(URIValueExpansionModifier.explode.templateRepresentation == "*")
    #expect(URIValueExpansionModifier.prefix(5).templateRepresentation == ":5")
    #expect(URIValueExpansionModifier.prefix(100).templateRepresentation == ":100")
    #expect(URIValueExpansionModifier.prefix(9999).templateRepresentation == ":9999")
  }

  // MARK: - Validity Tests

  @Test
  func `isValid`() {
    #expect(URIValueExpansionModifier.unmodified.isValid)
    #expect(URIValueExpansionModifier.explode.isValid)
    #expect(URIValueExpansionModifier.prefix(1).isValid)
    #expect(URIValueExpansionModifier.prefix(100).isValid)
    #expect(URIValueExpansionModifier.prefix(9999).isValid)
  }

  // MARK: - Codable Tests

  @Test
  func `codable round trip`() throws {
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()

    // unmodified
    let unmodified = URIValueExpansionModifier.unmodified
    let unmodifiedData = try encoder.encode(unmodified)
    let decodedUnmodified = try decoder.decode(URIValueExpansionModifier.self, from: unmodifiedData)
    #expect(unmodified == decodedUnmodified)

    // explode
    let explode = URIValueExpansionModifier.explode
    let explodeData = try encoder.encode(explode)
    let decodedExplode = try decoder.decode(URIValueExpansionModifier.self, from: explodeData)
    #expect(explode == decodedExplode)

    // prefix (typical)
    let prefix = URIValueExpansionModifier.prefix(42)
    let prefixData = try encoder.encode(prefix)
    let decodedPrefix = try decoder.decode(URIValueExpansionModifier.self, from: prefixData)
    #expect(prefix == decodedPrefix)

    // prefix (boundary: minimum)
    let minimum = URIValueExpansionModifier.prefix(1)
    let minData = try encoder.encode(minimum)
    let decodedMin = try decoder.decode(URIValueExpansionModifier.self, from: minData)
    #expect(minimum == decodedMin)

    // prefix (boundary: maximum)
    let maximum = URIValueExpansionModifier.prefix(9999)
    let maxData = try encoder.encode(maximum)
    let decodedMax = try decoder.decode(URIValueExpansionModifier.self, from: maxData)
    #expect(maximum == decodedMax)
  }

  // MARK: - Comparable Extended Tests

  @Test
  func `ordering`() {
    // unmodified < explode < prefix
    #expect(URIValueExpansionModifier.unmodified < URIValueExpansionModifier.explode)
    #expect(URIValueExpansionModifier.explode < URIValueExpansionModifier.prefix(1))
    #expect(URIValueExpansionModifier.explode < URIValueExpansionModifier.prefix(9999))

    // prefixes compare by value
    #expect(URIValueExpansionModifier.prefix(1) < URIValueExpansionModifier.prefix(2))
    #expect(URIValueExpansionModifier.prefix(100) < URIValueExpansionModifier.prefix(200))
    #expect(!(URIValueExpansionModifier.prefix(50) < URIValueExpansionModifier.prefix(50)))
    #expect(!(URIValueExpansionModifier.prefix(100) < URIValueExpansionModifier.prefix(50)))

    // reflexivity: nothing is less than itself
    #expect(!(URIValueExpansionModifier.unmodified < URIValueExpansionModifier.unmodified))
    #expect(!(URIValueExpansionModifier.explode < URIValueExpansionModifier.explode))
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
  func `ordering`() {
    verifyOrderedAscending(URIValueExpansionModifierType.allCases)
    #expect(URIValueExpansionModifierType.unmodified < URIValueExpansionModifierType.explode)
    #expect(URIValueExpansionModifierType.explode < URIValueExpansionModifierType.prefix)
  }

}
