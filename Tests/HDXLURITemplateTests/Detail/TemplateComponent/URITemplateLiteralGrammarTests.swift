import Foundation
import Testing

@testable import HDXLURITemplate

@Test("Public parsing accepts tilde as an RFC literal")
private func publicParsingAcceptsTilde() throws {
  let source = "https://example.com/~user"
  let template = try URITemplate(parsing: source)

  #expect(template.templateRepresentation == source)
  #expect(try template.evaluateAsString(parameters: [:]) == source)
}

@Test("Public parsing and expansion accept apostrophe as an RFC literal")
private func publicParsingAndExpansionAcceptApostrophe() throws {
  let template = try URITemplate(parsing: "'{var}'")

  #expect(template.templateRepresentation == "'{var}'")
  #expect(
    try template.evaluateAsString(
      parameters: ["var": .text("value")]
    ) == "'value'"
  )
}

@Test(
  "Corrected literals are valid in every literal position",
  arguments: [
    "'leading",
    "trailing'",
    "in'ternal",
    "~leading",
    "trailing~",
    "in~ternal",
  ]
)
private func correctedLiteralsAreValidInEveryPosition(
  source: String
) throws {
  let literal = try URITemplateLiteralComponent(parsing: source)

  #expect(literal.rawValue == source)
  #expect(literal.isValid)
}

@Test(
  "Corrected literals are valid next to expressions",
  arguments: [
    "'{var}'",
    "~{var}~",
    "'{var}",
    "{var}'",
    "~{var}",
    "{var}~",
  ]
)
private func correctedLiteralsAreValidNextToExpressions(
  source: String
) throws {
  let template = try URITemplate(parsing: source)

  #expect(template.templateRepresentation == source)
  #expect(
    try template.evaluateAsString(
      parameters: ["var": .text("value")]
    ) == source.replacingOccurrences(of: "{var}", with: "value")
  )
}

@Test(
  "Literal parser and invariant accept exact grammar boundaries",
  arguments: validLiteralBoundarySamples
)
private func literalValidationAcceptsExactGrammarBoundaries(
  source: String
) throws {
  let parsed = try URITemplateLiteralComponent(parsing: source)

  #expect(
    URITemplateLiteralComponent.validationRegularExpression
      .matchesEntirety(of: source)
  )
  #expect(parsed.rawValue == source)
  #expect(parsed.isValid)
}

@Test(
  "Literal parser and invariant reject exact grammar boundaries",
  arguments: invalidLiteralBoundarySamples
)
private func literalValidationRejectsExactGrammarBoundaries(
  source: String
) throws {
  #expect(
    !URITemplateLiteralComponent.validationRegularExpression
      .matchesEntirety(of: source)
  )
  #expect(throws: URITemplateLiteralComponent.ParseError.self) {
    _ = try URITemplateLiteralComponent(parsing: source)
  }
  #if !HEAVY_DEBUG
    #expect(!URITemplateLiteralComponent(rawValue: source).isValid)
  #endif

  if !source.isEmpty {
    #expect(throws: URITemplate.ParseError.self) {
      _ = try URITemplate(parsing: source)
    }
  }
}

private let validLiteralBoundarySamples = [
  "!",  // U+0021
  "#",  // U+0023
  "$",  // U+0024
  "&",  // U+0026
  "'",  // U+0027: verified RFC 6570 erratum 6937
  "(",  // U+0028
  ";",  // U+003B
  "=",  // U+003D
  "?",  // U+003F
  "A",  // U+0041
  "[",  // U+005B
  "]",  // U+005D
  "_",  // U+005F
  "a",  // U+0061
  "s",  // U+0073
  "z",  // U+007A
  "~",  // U+007E
  "\u{00A0}",  // First RFC `ucschar`
  "%00",
  "%2F",
  "%af",
  "é",
]

private let invalidLiteralBoundarySamples = [
  "",
  "\u{0000}",
  "\u{001F}",
  "\u{007F}",
  "\u{009F}",
  " ",
  "\"",
  "%",
  "%0",
  "%0G",
  "%G0",
  "%GG",
  "<",
  ">",
  "\\",
  "^",
  "`",
  "{",
  "|",
  "}",
]
