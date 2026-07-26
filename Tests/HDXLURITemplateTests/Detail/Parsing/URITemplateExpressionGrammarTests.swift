import Testing

@testable import HDXLURITemplate

@Test(
  "Public parsing rejects empty or whitespace-normalized varspecs",
  arguments: malformedExpressionTemplates
)
private func publicParsingRejectsMalformedVariableLists(
  source: String
) {
  do {
    _ = try URITemplate(parsing: source)
    Issue.record(
      "Malformed expression unexpectedly parsed: \(String(reflecting: source))"
    )
  } catch let error as URITemplate.ParseError {
    #expect(error.template == source)
  } catch {
    Issue.record(
      """
      Malformed expression escaped the public parse boundary: \
      \(String(reflecting: source)) threw \(String(reflecting: error)).
      """
    )
  }
}

@Test(
  "Every expression operator accepts valid single and multiple varspecs",
  arguments: expressionOperators
)
private func everyExpressionOperatorAcceptsValidVariableLists(
  expressionOperator: String
) throws {
  for (variableList, expectedNames) in [
    ("x", Set(["x"])),
    ("x,y", Set(["x", "y"]))
  ] {
    let source = "{\(expressionOperator)\(variableList)}"
    let template = try URITemplate(parsing: source)

    #expect(template.isValid)
    #expect(template.variableNames == expectedNames)
  }
}

@Test(
  "Valid varspec forms remain accepted",
  arguments: validExpressionCases
)
private func validVariableSpecificationsRemainAccepted(
  testCase: ValidExpressionCase
) throws {
  let template = try URITemplate(parsing: testCase.source)

  #expect(template.isValid)
  #expect(template.variableNames == testCase.variableNames)
}

private let expressionOperators = [
  "",
  "+",
  "#",
  ".",
  "/",
  ";",
  "?",
  "&"
]

private let malformedExpressionTemplates =
  expressionOperators.map { expressionOperator in
    "{\(expressionOperator)}"
  }
  + expressionOperators.flatMap { expressionOperator in
    [
      "{\(expressionOperator),x}",
      "{\(expressionOperator)x,}",
      "{\(expressionOperator)x,,y}",
      "{\(expressionOperator)x, y}"
    ]
  }
  + [
    "{,}",
    "{x,,}",
    "{ leading_space}",
    "{trailing_space }",
    "{x ,y}",
    "/resolution{?x, y}",
    "{x,\ty}",
    "{x,\ny}",
    "{x,\ry}",
    "{x,\u{000B}y}",
    "{x,\u{000C}y}",
    "{x,\u{0085}y}",
    "{x,\u{00A0}y}",
    "{x,\u{1680}y}",
    "{x,\u{2003}y}",
    "{x,\u{2028}y}",
    "{x,\u{2029}y}",
    "{x,\u{202F}y}",
    "{x,\u{205F}y}",
    "{x,\u{3000}y}"
  ]

private struct ValidExpressionCase: CustomTestStringConvertible, Sendable {
  let source: String
  let variableNames: Set<String>

  var testDescription: String {
    source
  }
}

private let validExpressionCases = [
  ValidExpressionCase(
    source: "{x}",
    variableNames: ["x"]
  ),
  ValidExpressionCase(
    source: "{x,y}",
    variableNames: ["x", "y"]
  ),
  ValidExpressionCase(
    source: "{%20}",
    variableNames: ["%20"]
  ),
  ValidExpressionCase(
    source: "{alpha.%2F}",
    variableNames: ["alpha.%2F"]
  ),
  ValidExpressionCase(
    source: "{x,y*,z:12}",
    variableNames: ["x", "y", "z"]
  )
]
