import Foundation
import Testing

@testable import HDXLURITemplate

@Test(
  "Public parsing accepts canonical prefix-modifier boundaries",
  arguments: canonicalPrefixBoundaryProbes
)
private func publicParsingAcceptsCanonicalPrefixBoundaries(
  probe: PrefixGrammarProbe
) throws {
  let template = try URITemplate(parsing: probe.template)

  #expect(template.isValid)
  #expect(template.templateRepresentation == probe.template)
  #expect(try URITemplate(parsing: template.templateRepresentation) == template)

  let decoded = try JSONDecoder().decode(
    URITemplate.self,
    from: JSONEncoder().encode(template)
  )
  #expect(decoded == template)
  #expect(decoded.isValid)
  #expect(decoded.templateRepresentation == probe.template)
}

@Test(
  "Public parsing rejects noncanonical prefix-modifier spellings",
  arguments: rejectedPrefixGrammarProbes
)
private func publicParsingRejectsNoncanonicalPrefixSpellings(
  probe: PrefixGrammarProbe
) {
  do {
    _ = try URITemplate(parsing: probe.template)
    Issue.record(
      "Invalid prefix modifier unexpectedly parsed: \(probe.template)"
    )
  } catch let error as URITemplate.ParseError {
    #expect(error.template == probe.template)
  } catch {
    Issue.record(
      """
      Invalid prefix modifier escaped the public parse boundary: \
      \(probe.template) threw \(String(reflecting: error)).
      """
    )
  }

  var variableSpecification = String(
    probe.template.dropFirst().dropLast()
  )
  let originalVariableSpecification = variableSpecification
  #expect(throws: URIValueExpansionModifier.ParseError.self) {
    _ = try URIValueExpansionModifier(
      parsing: &variableSpecification
    )
  }
  #expect(variableSpecification == originalVariableSpecification)
}

@Test("Every canonical ASCII prefix length parses without normalization")
private func everyCanonicalPrefixLengthParsesExactly() throws {
  for prefixLength in
    URIValueExpansionModifier.rangeOfValidPrefixCodePointCounts {
    var variableSpecification = "x:\(prefixLength)"
    let modifier = try URIValueExpansionModifier(
      parsing: &variableSpecification
    )

    #expect(modifier == .prefix(prefixLength))
    #expect(modifier.isValid)
    #expect(modifier.templateRepresentation == ":\(prefixLength)")
    #expect(variableSpecification == "x")
  }
}

@Test("Prefix decoding and internal validity use the numeric invariant")
private func prefixDecodingAndInternalValidityAgree() throws {
  for prefixLength in [1, 9, 10, 9_999] {
    let encoded = Data(
      """
      {"type":4,"data":\(prefixLength)}
      """.utf8
    )
    let modifier = try JSONDecoder().decode(
      URIValueExpansionModifier.self,
      from: encoded
    )

    #expect(modifier == .prefix(prefixLength))
    #expect(modifier.isValid)
    #expect(modifier.templateRepresentation == ":\(prefixLength)")
    #expect(
      try JSONDecoder().decode(
        URIValueExpansionModifier.self,
        from: JSONEncoder().encode(modifier)
      ) == modifier
    )
  }

  for invalidPrefixLength in [0, 10_000, Int.min, Int.max] {
    #expect(!URIValueExpansionModifier.prefix(invalidPrefixLength).isValid)
    let encoded = Data(
      """
      {"type":4,"data":\(invalidPrefixLength)}
      """.utf8
    )
    #expect(
      throws: DataValidationError<URIValueExpansionModifier>.self
    ) {
      _ = try JSONDecoder().decode(
        URIValueExpansionModifier.self,
        from: encoded
      )
    }
  }
}

@Test("The resolved pinned prefix case is an ordinary pass")
private func resolvedPinnedPrefixCaseIsAnOrdinaryPass() throws {
  let caseIdentity = ReferenceExampleCaseIdentity(
    source: "negative-tests",
    caption: "Failure Tests",
    template: "{var:01}",
    expectation: .evaluationFailure
  )
  let example = try #require(
    allReferenceExamples().first(where: caseIdentity.matches)
  )

  try verifyReferenceExampleBehavior(example)
}

private struct PrefixGrammarProbe:
  CustomTestStringConvertible,
  Sendable {

  let label: String
  let template: String

  var testDescription: String {
    label
  }
}

private let canonicalPrefixBoundaryProbes = [
  PrefixGrammarProbe(label: "one", template: "{x:1}"),
  PrefixGrammarProbe(label: "single-digit maximum", template: "{x:9}"),
  PrefixGrammarProbe(label: "two-digit minimum", template: "{x:10}"),
  PrefixGrammarProbe(label: "three digits", template: "{x:999}"),
  PrefixGrammarProbe(label: "maximum", template: "{x:9999}")
]

private let rejectedPrefixGrammarProbes = [
  PrefixGrammarProbe(label: "empty", template: "{x:}"),
  PrefixGrammarProbe(label: "zero", template: "{x:0}"),
  PrefixGrammarProbe(label: "multiple zeroes", template: "{x:00}"),
  PrefixGrammarProbe(label: "leading zero", template: "{x:01}"),
  PrefixGrammarProbe(label: "multiple leading zeroes", template: "{x:0001}"),
  PrefixGrammarProbe(label: "plus sign", template: "{x:+1}"),
  PrefixGrammarProbe(label: "minus sign", template: "{x:-1}"),
  PrefixGrammarProbe(label: "Unicode minus", template: "{x:\u{2212}1}"),
  PrefixGrammarProbe(label: "over maximum", template: "{x:10000}"),
  PrefixGrammarProbe(
    label: "overflow-sized digits",
    template: "{x:9999999999999999999999999999999999999999}"
  ),
  PrefixGrammarProbe(label: "leading whitespace", template: "{x: 1}"),
  PrefixGrammarProbe(label: "trailing whitespace", template: "{x:1 }"),
  PrefixGrammarProbe(label: "underscore separator", template: "{x:1_0}"),
  PrefixGrammarProbe(label: "decimal separator", template: "{x:1.0}"),
  PrefixGrammarProbe(label: "alphabetic suffix", template: "{x:1a}"),
  PrefixGrammarProbe(
    label: "combining-mark suffix",
    template: "{x:1\u{0301}}"
  ),
  PrefixGrammarProbe(label: "Arabic-Indic digit", template: "{x:\u{0661}}"),
  PrefixGrammarProbe(label: "fullwidth digit", template: "{x:\u{FF11}}")
]
