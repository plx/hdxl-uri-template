import Foundation
import HDXLURITemplate
import Testing

private struct ParseDiagnosticProbe:
  Sendable,
  CustomTestStringConvertible
{
  let label: String
  let source: String
  let expectedKind: URITemplate.ParseError.Kind
  let expectedUTF8Range: Range<Int>

  var testDescription: String {
    label
  }
}

private let parseDiagnosticProbes: [ParseDiagnosticProbe] = [
  ParseDiagnosticProbe(
    label: "unexpected closing brace at start",
    source: "}",
    expectedKind: .unexpectedClosingBrace,
    expectedUTF8Range: 0..<1
  ),
  ParseDiagnosticProbe(
    label: "unexpected opening brace in expression",
    source: "{x{y}",
    expectedKind: .unexpectedOpeningBrace,
    expectedUTF8Range: 2..<3
  ),
  ParseDiagnosticProbe(
    label: "unterminated expression after literal",
    source: "prefix{",
    expectedKind: .unterminatedExpression,
    expectedUTF8Range: 7..<7
  ),
  ParseDiagnosticProbe(
    label: "empty expression",
    source: "{}",
    expectedKind: .emptyExpression,
    expectedUTF8Range: 1..<1
  ),
  ParseDiagnosticProbe(
    label: "operator without variable",
    source: "{?}",
    expectedKind: .emptyVariableSpecification,
    expectedUTF8Range: 2..<2
  ),
  ParseDiagnosticProbe(
    label: "empty trailing variable",
    source: "{x,}",
    expectedKind: .emptyVariableSpecification,
    expectedUTF8Range: 3..<3
  ),
  ParseDiagnosticProbe(
    label: "reserved unsupported operator",
    source: "{!x}",
    expectedKind: .invalidOperator,
    expectedUTF8Range: 1..<2
  ),
  ParseDiagnosticProbe(
    label: "invalid literal character",
    source: "ok value",
    expectedKind: .invalidLiteral,
    expectedUTF8Range: 2..<3
  ),
  ParseDiagnosticProbe(
    label: "invalid variable name",
    source: "{x-y}",
    expectedKind: .invalidVariableName,
    expectedUTF8Range: 2..<3
  ),
  ParseDiagnosticProbe(
    label: "invalid prefix modifier",
    source: "{x:0}",
    expectedKind: .invalidModifier,
    expectedUTF8Range: 2..<4
  ),
  ParseDiagnosticProbe(
    label: "repeated prefix modifier separator",
    source: "{x:1:2}",
    expectedKind: .invalidModifier,
    expectedUTF8Range: 2..<6
  ),
  ParseDiagnosticProbe(
    label: "malformed literal percent triplet",
    source: "ok%2",
    expectedKind: .malformedPercentEncoding,
    expectedUTF8Range: 2..<4
  ),
  ParseDiagnosticProbe(
    label: "malformed variable percent triplet",
    source: "{x.%GG}",
    expectedKind: .malformedPercentEncoding,
    expectedUTF8Range: 3..<6
  ),
  ParseDiagnosticProbe(
    label: "multibyte prefix before modifier",
    source: "é🙂{x:0}",
    expectedKind: .invalidModifier,
    expectedUTF8Range: 8..<10
  ),
  ParseDiagnosticProbe(
    label: "multibyte prefix before malformed variable percent",
    source: "é{%G}",
    expectedKind: .malformedPercentEncoding,
    expectedUTF8Range: 3..<5
  ),
  ParseDiagnosticProbe(
    label: "multibyte prefix before closing brace",
    source: "🙂}",
    expectedKind: .unexpectedClosingBrace,
    expectedUTF8Range: 4..<5
  ),
  ParseDiagnosticProbe(
    label: "brace with a combining scalar remains a delimiter",
    source: "{\u{301}x}",
    expectedKind: .invalidVariableName,
    expectedUTF8Range: 1..<3
  ),
]

@Test(
  "Public parse diagnostics expose stable kinds and UTF-8 ranges",
  arguments: parseDiagnosticProbes
)
private func publicParseDiagnosticsExposeKindAndRange(
  probe: ParseDiagnosticProbe
) {
  do {
    _ = try URITemplate(parsing: probe.source)
    Issue.record("Expected malformed URI-template source to fail.")
  } catch let error as URITemplate.ParseError {
    #expect(error.kind == probe.expectedKind)
    #expect(error.sourceRange == probe.expectedUTF8Range)
    #expect(error.sourceRange.lowerBound >= 0)
    #expect(error.sourceRange.upperBound <= probe.source.utf8.count)
    #expect(error.failureReason?.isEmpty == false)
  } catch {
    Issue.record(
      "Expected URITemplate.ParseError; observed \(String(reflecting: error))."
    )
  }
}

@Test("Parse diagnostic kinds have stable textual identities")
private func parseDiagnosticKindsHaveStableIdentities() {
  let expectedRawValues = [
    "unexpectedOpeningBrace",
    "unexpectedClosingBrace",
    "unterminatedExpression",
    "emptyExpression",
    "emptyVariableSpecification",
    "invalidOperator",
    "invalidLiteral",
    "invalidVariableName",
    "invalidModifier",
    "malformedPercentEncoding",
    "other",
  ]

  #expect(
    URITemplate.ParseError.Kind.allCases.map(\.rawValue)
      == expectedRawValues
  )
  for kind in URITemplate.ParseError.Kind.allCases {
    #expect(String(describing: kind) == kind.rawValue)
    #expect(
      String(reflecting: kind)
        == "URITemplate.ParseError.Kind.\(kind.rawValue)"
    )
  }
}

@Test("Structured parse diagnostics survive Error and NSError bridging")
private func structuredParseDiagnosticsBridge() {
  let sensitiveSource = "SECRET_LITERAL{value:0}"

  do {
    _ = try URITemplate(parsing: sensitiveSource)
    Issue.record("Expected malformed URI-template source to fail.")
  } catch let error as URITemplate.ParseError {
    let erased: any Error = error
    let recovered = erased as? URITemplate.ParseError
    let foundationError = erased as NSError

    #expect(recovered?.kind == .invalidModifier)
    #expect(recovered?.sourceRange == 20..<22)
    #expect(
      foundationError.localizedDescription
        == "The URI template could not be parsed."
    )
    #expect(
      foundationError.localizedFailureReason
        == "A variable modifier does not match URI-template syntax."
    )
    #expect(!String(describing: error).contains("SECRET_LITERAL"))
    #expect(!String(reflecting: error).contains("SECRET_LITERAL"))
    #expect(!foundationError.description.contains("SECRET_LITERAL"))
  } catch {
    Issue.record(
      "Expected URITemplate.ParseError; observed \(String(reflecting: error))."
    )
  }
}
