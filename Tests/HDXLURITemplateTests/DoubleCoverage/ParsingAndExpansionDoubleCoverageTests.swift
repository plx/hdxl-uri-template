import Foundation
import Testing
@testable import HDXLURITemplate

extension Tag {
  @Tag
  static var doubleCoverageParsingExpansion: Self
}

@Test(
  "Manual parsing coverage",
  .tags(.doubleCoverageParsingExpansion)
)
private func manualParsingCoverage() throws {
  // Chunking is the first parser boundary, so this covers literal/expression decomposition plus each structural bracket failure.
  let chunks = try "pre{a}mid{?b}post".identifyURITemplateChunkRanges()
  #expect(chunks.count == 5)
  let components = try "pre{a}".parseIntoURITemplateComponents()
  #expect(components.map(\.templateRepresentation) == ["pre", "{a}"])

  #expect(try "".identifyURITemplateChunkRanges().isEmpty)
  #expect(throws: String.URITemplateChunkingError.self) {
    _ = try "{}".identifyURITemplateChunkRanges()
  }
  #expect(throws: String.URITemplateChunkingError.self) {
    _ = try "{a{b}".identifyURITemplateChunkRanges()
  }
  #expect(throws: String.URITemplateChunkingError.self) {
    _ = try "a}".identifyURITemplateChunkRanges()
  }
  #expect(throws: String.URITemplateChunkingError.self) {
    _ = try "{a".identifyURITemplateChunkRanges()
  }

  // These examples separate each parser layer's empty and invalid-content cases so failures identify the responsible grammar.
  #expect(throws: URIValueExpansionType.ParseError.self) {
    var source = ""
    _ = try URIValueExpansionType(parsing: &source)
  }
  #expect(throws: URIValueExpansionModifier.ParseError.self) {
    var source = "name:0"
    _ = try URIValueExpansionModifier(parsing: &source)
  }
  #expect(throws: URITemplateLiteralComponent.ParseError.self) {
    _ = try URITemplateLiteralComponent(parsing: "")
  }
  #expect(throws: URITemplateLiteralComponent.ParseError.self) {
    _ = try URITemplateLiteralComponent(parsing: "has space")
  }
  #expect(throws: URITemplateVariableName.ParseError.self) {
    _ = try URITemplateVariableName(parsing: "")
  }
  #expect(throws: URITemplateVariableName.ParseError.self) {
    _ = try URITemplateVariableName(parsing: "bad!")
  }
  #expect(throws: URITemplateVariable.ParseError.self) {
    _ = try URITemplateVariable(parsing: "")
  }
  #expect(throws: URITemplateExpressionComponent.ParseError.self) {
    _ = try URITemplateExpressionComponent(parsing: "")
  }
  #expect(throws: URITemplateExpressionComponent.ParseError.self) {
    _ = try URITemplateExpressionComponent(parsing: "?")
  }

  var simple = "name"
  #expect(try URIValueExpansionType(parsing: &simple) == .simple)
  #expect(simple == "name")
  var prefixed = "name:12"
  #expect(try URIValueExpansionModifier(parsing: &prefixed) == .prefix(12))
  #expect(prefixed == "name")

  #expect(URIValueExpansionModifier.unmodified < .prefix(1))
  #expect(!(URIValueExpansionModifier.prefix(1) < .unmodified))
  #expect(try JSONDecoder().decode(URIValueExpansionModifier.self, from: #"{"type":2}"#.data(using: .utf8)!) == .explode)
  #expect(try JSONDecoder().decode(URIValueExpansionModifier.self, from: #"{"type":4,"data":42}"#.data(using: .utf8)!) == .prefix(42))
}

@Test(
  "Property parsing coverage",
  .tags(.doubleCoverageParsingExpansion)
)
private func propertyParsingCoverage() throws {
  for expansionType in URIValueExpansionType.allCases {
    var source = "\(expansionType.formatString)a"
    let parsed = try URIValueExpansionType(parsing: &source)
    #expect(parsed == expansionType)
    #expect(source == "a")
  }

  for modifier in [URIValueExpansionModifier.unmodified, .explode, .prefix(1), .prefix(9999)] {
    var source = "a\(modifier.templateRepresentation)"
    let parsed = try URIValueExpansionModifier(parsing: &source)
    #expect(parsed == modifier)
    #expect(source == "a")
  }

  for name in ["a", "a.b", "A_1", "%2F"] {
    let parsed = try URITemplateVariableName(parsing: name)
    #expect(parsed.rawValue == name)
    #expect(parsed.isValid)
  }

  for expression in ["a", "+a,b", "#a:2", "/a*", "?a,b:3"] {
    let parsed = try URITemplateExpressionComponent(parsing: expression)
    #expect(parsed.templateRepresentation == expression.replacingOccurrences(of: ",", with: ", "))
    #expect(parsed.isValid)
  }
}

@Test(
  "Manual expansion support coverage",
  .tags(.doubleCoverageParsingExpansion)
)
private func manualExpansionSupportCoverage() throws {
  // Expansion type metadata controls URI punctuation; one explicit table makes every operator's contract visible.
  let expected: [(URIValueExpansionType, Bool, Bool, String, String, String, String)] = [
    (.simple, false, false, "", "", ",", ""),
    (.reserved, false, true, "", "", ",", "+"),
    (.fragment, false, true, "", "#", ",", "#"),
    (.label, false, false, "", ".", ".", "."),
    (.pathSegment, false, false, "", "/", "/", "/"),
    (.pathParameter, false, false, "", ";", ";", ";"),
    (.query, true, false, "=", "?", "&", "?"),
    (.queryContinuation, true, false, "=", "&", "&", "&")
  ]

  for (type, isQuery, allowsTriplets, emptySuffix, prefix, separator, format) in expected {
    #expect(type.isQueryExpansionType == isQuery)
    #expect(type.allowsPercentEncodedTriplets == allowsTriplets)
    #expect(type.emptyValueSuffix == emptySuffix)
    #expect(type.prefixForExpandedVariableList == prefix)
    #expect(type.separatorForExpandedVariableList == separator)
    #expect(type.formatString == format)
    #expect(URIValueExpansionType(formatString: format) == type)
    #expect(CharacterSet.allowedCharacters(forValueExpansionType: type).isSuperset(of: rfc_unreserved))
  }
  #expect(URIValueExpansionType(formatString: "!") == nil)

  // Escaping differs between simple and reserved expansion: reserved keeps real pct-triplets, while simple encodes reserved characters.
  #expect("".escaped(forValueExpansionType: .simple) == "")
  #expect("a/b".escaped(forValueExpansionType: .simple) == "a%2Fb")
  #expect("a/b".escaped(forValueExpansionType: .reserved) == "a/b")
  #expect("%2F/%zz".escaped(forValueExpansionType: .reserved) == "%2F/%25zz")
  #expect((0x30 as UInt8).isASCIIHexadecimalDigit)
  #expect(!(0x47 as UInt8).isASCIIHexadecimalDigit)

  // CharacterSet convenience initializers underpin RFC sets; these examples cover scalar ranges and unions.
  let scalarA: UnicodeScalar = "a"
  let scalarC: UnicodeScalar = "c"
  let scalarD: UnicodeScalar = "d"
  let rangeSet = CharacterSet(unionOf: [scalarA...scalarC])
  #expect(rangeSet.contains(scalarA))
  #expect(rangeSet.contains(scalarC))
  #expect(!rangeSet.contains(scalarD))
  let unionSet = CharacterSet(unionOf: [scalarA...scalarA, scalarC...scalarC])
  #expect(unionSet.contains(scalarA))
  #expect(unionSet.contains(scalarC))
  let openRangeSet = CharacterSet(unionOf: [scalarA..<scalarD])
  #expect(openRangeSet.contains(scalarA))
  #expect(openRangeSet.contains(scalarC))
  #expect(!openRangeSet.contains(scalarD))

  // Support helpers also need success and no-op paths because modifiers and expression parsing depend on these string operations.
  #expect("abc,def".lastComponent(forSeparator: ",") == "def")
  #expect("abc,def".removingLastComponent(forSeparator: ",") == "abc,")
  var removable = "abc,def"
  removable.removeLastComponent(forSeparator: ",")
  #expect(removable == "abc,")
  #expect("abc".constrained(toCodePointCount: -1) == "")
  #expect(StandardEnumerationCodingKeys(intValue: 2) == nil)
  #expect(!URLError(.badURL).bestAvailableExplanation.isEmpty)
  #expect(ManualLocalizedCoverageError().bestAvailableExplanation == "manual localized explanation")
}

private struct ManualLocalizedCoverageError: Error, LocalizedError {
  var errorDescription: String? {
    "manual localized explanation"
  }
}

@Test(
  "Property expansion support coverage",
  .tags(.doubleCoverageParsingExpansion)
)
private func propertyExpansionSupportCoverage() throws {
  for type in URIValueExpansionType.allCases {
    let allowed = CharacterSet.allowedCharacters(forValueExpansionType: type)
    #expect(allowed.isSuperset(of: rfc_unreserved))
    #expect("abc-._~".escaped(forValueExpansionType: type) == "abc-._~")
    #expect(URIValueExpansionType(formatString: type.formatString) == type)
  }

  let sampleRanges = rfc_ucschar_ranges + rfc_iprivate_ranges
  for range in sampleRanges {
    let set = CharacterSet(unionOf: [range])
    #expect(set.contains(range.lowerBound))
    #expect(set.contains(range.upperBound))
  }
}

@Test(
  "Manual variable expansion coverage",
  .tags(.doubleCoverageParsingExpansion)
)
private func manualVariableExpansionCoverage() throws {
  // Text expansion examples cover unescaped variable names, query-style escaped names, empty suffixes, and prefix modifiers.
  let name = URITemplateVariableName(rawValue: "name")
  let text = URIVariableTextValue(rawValue: "hello/world")
  #expect(try text.escapedContents(expansionType: .simple) == "hello%2Fworld")
  #expect(try text.expansion(expansionType: .simple, variableName: name, expansionModifier: .unmodified) == "hello%2Fworld")
  #expect(try text.expansion(expansionType: .query, variableName: name, expansionModifier: .prefix(5)) == "name=hello")
  #expect(try URIVariableTextValue(rawValue: "").expansion(expansionType: .query, variableName: name, expansionModifier: .unmodified) == "name=")
  #expect(text.effectiveVariableValue(forExpansionModifier: .explode) == "hello/world")
  #expect(text.effectiveVariableValue(forExpansionModifier: .prefix(5)) == "hello")

  // List and association expansion have distinct exploded/unexploded rules across path, parameter, and query operators.
  let list = URIVariableListValue(strings: ["red", "", "blue"])
  #expect(try list.expansion(expansionType: .simple, variableName: name, expansionModifier: .unmodified) == "red,,blue")
  #expect(try list.expansion(expansionType: .query, variableName: name, expansionModifier: .unmodified) == "name=red,,blue")
  #expect(try list.expansion(expansionType: .pathParameter, variableName: name, expansionModifier: .explode) == "name=red;name;name=blue")
  #expect(try URIVariableListValue().expansion(expansionType: .query, variableName: name, expansionModifier: .explode) == "")

  let association = try URIVariableAssociationValue(
    validatingStrings: [("a", "1"), ("b", ""), ("c", "3")]
  )
  #expect(try association.expansion(expansionType: .simple, variableName: name, expansionModifier: .unmodified) == "a,1,b,,c,3")
  #expect(try association.expansion(expansionType: .query, variableName: name, expansionModifier: .unmodified) == "name=a,1,b,,c,3")
  #expect(try association.expansion(expansionType: .query, variableName: name, expansionModifier: .explode) == "a=1&b=&c=3")
  #expect(try association.expansion(expansionType: .pathParameter, variableName: name, expansionModifier: .explode) == "a=1;b;c=3")
  #expect(try URIVariableAssociationValue().expansion(expansionType: .query, variableName: name, expansionModifier: .explode) == "")

  let variable = URITemplateVariable(variableName: name, expansionModifier: .unmodified)
  let parameters: [String: URIVariableValue] = [
    "name": .text("value"),
    "emptyList": .emptyList
  ]
  #expect(try variable.evaluate(parameters: parameters, expansionType: .simple) == "value")
  #expect(try URITemplateVariable(parsing: "missing").evaluate(parameters: parameters, expansionType: .simple) == "")
  #expect(try URITemplateVariable(parsing: "emptyList").evaluateIfDefined(parameters: parameters, expansionType: .simple) == nil)

  let value = try URIVariableValue.association([("a", "1")])
  #expect(try value.evaluate(expansionType: .query, templateVariable: variable) == "name=a,1")
  #expect(try URIVariableValue.undefined.evaluate(expansionType: .query, templateVariable: variable) == "")

  // Error descriptions are part of the diagnostics contract, even though escaping failure is rare for valid Swift strings.
  #expect(URIVariableTextValue.ExpansionError.unableToEscapeTextValue("x", .simple).localizedDescription.contains("Unable to escape text"))
  #expect(URIVariableTextValue.ExpansionError.unableToEscapeVariableName("x", .query).localizedDescription.contains("Unable to escape variable-name"))
  #expect(URIVariableTextValue.ExpansionError.unableToEscapeVariableValue("x", "v", .query, .explode).localizedDescription.contains("Unable to escape"))
}

@Test(
  "Property variable expansion coverage",
  .tags(.doubleCoverageParsingExpansion)
)
private func propertyVariableExpansionCoverage() throws {
  let name = URITemplateVariableName(rawValue: "v")
  let values = ["alpha", "beta/gamma", "delta space", ""]

  for expansionType in URIValueExpansionType.allCases {
    for rawValue in values {
      let text = URIVariableTextValue(rawValue: rawValue)
      let unmodified = try text.expansion(
        expansionType: expansionType,
        variableName: name,
        expansionModifier: .unmodified
      )
      let viaVariable = try text.expansion(
        expansionType: expansionType,
        templateVariable: URITemplateVariable(variableName: name, expansionModifier: .unmodified)
      )
      #expect(unmodified == viaVariable)

      let prefixed = text.effectiveVariableValue(forExpansionModifier: .prefix(2))
      #expect(prefixed.codePointCount <= 2)
    }

    let list = URIVariableListValue(strings: values)
    let unexploded = try list.expansion(expansionType: expansionType, variableName: name, expansionModifier: .unmodified)
    let prefixedList = try list.expansion(expansionType: expansionType, variableName: name, expansionModifier: .prefix(2))
    #expect(unexploded == prefixedList)
    #expect(try list.expansion(expansionType: expansionType, templateVariable: URITemplateVariable(variableName: name, expansionModifier: .explode)).isEmpty == false)

    let association = try URIVariableAssociationValue(
      validatingStrings: [("a", "1"), ("b", "2")]
    )
    let prefixedAssociation = try association.expansion(expansionType: expansionType, variableName: name, expansionModifier: .prefix(2))
    let unexplodedAssociation = try association.expansion(expansionType: expansionType, variableName: name, expansionModifier: .unmodified)
    #expect(prefixedAssociation == unexplodedAssociation)
    #expect(try association.expansion(expansionType: expansionType, templateVariable: URITemplateVariable(variableName: name, expansionModifier: .explode)).isEmpty == false)
  }
}
