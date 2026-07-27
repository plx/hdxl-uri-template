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
  let chunkingFailures: [(String, URITemplate.ParseError.Kind)] = [
    ("{}", .emptyExpression),
    ("{a{b}", .unexpectedOpeningBrace),
    ("a}", .unexpectedClosingBrace),
    ("{a", .unterminatedExpression),
  ]
  for (source, expectedKind) in chunkingFailures {
    do {
      _ = try source.identifyURITemplateChunkRanges()
      Issue.record("Expected chunking to reject \(source).")
    } catch let diagnostic as URITemplateSourceDiagnostic {
      #expect(diagnostic.kind == expectedKind)
    } catch {
      Issue.record(
        "Expected URITemplateSourceDiagnostic for \(source)."
      )
    }
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
    #expect(parsed.templateRepresentation == expression)
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
    (.queryContinuation, true, false, "=", "&", "&", "&"),
  ]

  for (type, isQuery, allowsTriplets, emptySuffix, prefix, separator, format) in expected {
    #expect(type.isQueryExpansionType == isQuery)
    #expect(type.allowsPercentEncodedTriplets == allowsTriplets)
    #expect(type.emptyValueSuffix == emptySuffix)
    #expect(type.prefixForExpandedVariableList == prefix)
    #expect(type.separatorForExpandedVariableList == separator)
    #expect(type.formatString == format)
    #expect(URIValueExpansionType(formatString: format) == type)
    #expect(
      CharacterSet.allowedCharacters(forValueExpansionType: type).isSuperset(of: rfc_unreserved)
    )
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
  // The negative fallback intentionally violates the HEAVY_DEBUG invariant.
  #if !HEAVY_DEBUG
    #expect("abc".constrained(toCodePointCount: -1) == "")
  #endif
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

  for range in rfc_iprivate_ranges {
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
  #expect(text.escapedContents(expansionType: .simple) == "hello%2Fworld")
  #expect(
    text.expansion(expansionType: .simple, variableName: name, expansionModifier: .unmodified)
      == "hello%2Fworld"
  )
  #expect(
    text.expansion(expansionType: .query, variableName: name, expansionModifier: .prefix(5))
      == "name=hello"
  )
  #expect(
    URIVariableTextValue(rawValue: "").expansion(
      expansionType: .query,
      variableName: name,
      expansionModifier: .unmodified
    ) == "name="
  )
  #expect(text.effectiveVariableValue(forExpansionModifier: .explode) == "hello/world")
  #expect(text.effectiveVariableValue(forExpansionModifier: .prefix(5)) == "hello")

  // List and association expansion have distinct exploded/unexploded rules across path, parameter, and query operators.
  let list = URIVariableListValue(strings: ["red", "", "blue"])
  #expect(
    list.expansion(expansionType: .simple, variableName: name, expansionModifier: .unmodified)
      == "red,,blue"
  )
  #expect(
    list.expansion(expansionType: .query, variableName: name, expansionModifier: .unmodified)
      == "name=red,,blue"
  )
  #expect(
    list.expansion(
      expansionType: .pathParameter,
      variableName: name,
      expansionModifier: .explode
    ) == "name=red;name;name=blue"
  )
  #expect(
    URIVariableListValue().expansion(
      expansionType: .query,
      variableName: name,
      expansionModifier: .explode
    ) == ""
  )

  let association = try URIVariableAssociationValue(
    validatingStrings: [("a", "1"), ("b", ""), ("c", "3")]
  )
  #expect(
    association.expansion(
      expansionType: .simple,
      variableName: name,
      expansionModifier: .unmodified
    ) == "a,1,b,,c,3"
  )
  #expect(
    association.expansion(
      expansionType: .query,
      variableName: name,
      expansionModifier: .unmodified
    ) == "name=a,1,b,,c,3"
  )
  #expect(
    association.expansion(
      expansionType: .query,
      variableName: name,
      expansionModifier: .explode
    ) == "a=1&b=&c=3"
  )
  #expect(
    association.expansion(
      expansionType: .pathParameter,
      variableName: name,
      expansionModifier: .explode
    ) == "a=1;b;c=3"
  )
  #expect(
    URIVariableAssociationValue().expansion(
      expansionType: .query,
      variableName: name,
      expansionModifier: .explode
    ) == ""
  )

  let variable = URITemplateVariable(variableName: name, expansionModifier: .unmodified)
  let parameters: [String: URIVariableValue] = [
    "name": .text("value"),
    "emptyList": .emptyList,
  ]
  #expect(try variable.evaluate(parameters: parameters, expansionType: .simple) == "value")
  #expect(
    try URITemplateVariable(parsing: "missing").evaluate(
      parameters: parameters,
      expansionType: .simple
    ) == ""
  )
  #expect(
    try URITemplateVariable(parsing: "emptyList").evaluateIfDefined(
      parameters: parameters,
      expansionType: .simple
    ) == nil
  )

  let value = try URIVariableValue.association([("a", "1")])
  #expect(try value.evaluate(expansionType: .query, templateVariable: variable) == "name=a,1")
  #expect(
    try URIVariableValue.undefined.evaluate(expansionType: .query, templateVariable: variable) == ""
  )

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
      let unmodified = text.expansion(
        expansionType: expansionType,
        variableName: name,
        expansionModifier: .unmodified
      )
      let viaVariable = text.expansion(
        expansionType: expansionType,
        templateVariable: URITemplateVariable(variableName: name, expansionModifier: .unmodified)
      )
      #expect(unmodified == viaVariable)

      let prefixed = text.effectiveVariableValue(forExpansionModifier: .prefix(2))
      #expect(prefixed.codePointCount <= 2)
    }

    let list = URIVariableListValue(strings: values)
    #expect(
      list.expansion(
        expansionType: expansionType,
        templateVariable: URITemplateVariable(variableName: name, expansionModifier: .explode)
      ).isEmpty == false
    )
    #expect(throws: URIVariableValue.ExpansionError.self) {
      _ = try URIVariableValue.list(values).evaluate(
        expansionType: expansionType,
        templateVariable: URITemplateVariable(
          variableName: name,
          expansionModifier: .prefix(2)
        )
      )
    }

    let association = try URIVariableAssociationValue(
      validatingStrings: [("a", "1"), ("b", "2")]
    )
    #expect(
      association.expansion(
        expansionType: expansionType,
        templateVariable: URITemplateVariable(variableName: name, expansionModifier: .explode)
      ).isEmpty == false
    )
    #expect(throws: URIVariableValue.ExpansionError.self) {
      _ = try URIVariableValue.association(
        key: "a",
        value: "1"
      ).evaluate(
        expansionType: expansionType,
        templateVariable: URITemplateVariable(
          variableName: name,
          expansionModifier: .prefix(2)
        )
      )
    }
  }
}
