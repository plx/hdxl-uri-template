import Foundation
import Testing

@testable import HDXLURITemplate

@Test(
  "Public parsing preserves exact accepted source",
  arguments: exactSourceExamples
)
private func publicParsingPreservesExactSource(
  source: String
) throws {
  try verifyExactSourceRoundTrip(
    source: source,
    parameters: exactSourceParameters
  )
}

@Test(
  "Every parseable pinned source remains exact and semantically stable",
  arguments: parseableReferenceExamples
)
private func parseablePinnedSourcesRemainExact(
  example: CaptionedTestCase
) throws {
  try verifyExactSourceRoundTrip(
    source: example.testCase.template,
    parameters: example.parameters
  )
}

@Test("Generated valid sources round trip exactly")
private func generatedValidSourcesRoundTripExactly() throws {
  #expect(generatedValidSources.count == 264)
  for source in generatedValidSources {
    try verifyExactSourceRoundTrip(
      source: source,
      parameters: exactSourceParameters
    )
  }
}

@Test(
  "Codable round trips retain exact validated source",
  arguments: exactSourceExamples
)
private func codableRoundTripsRetainExactSource(
  source: String
) throws {
  let template = try URITemplate(parsing: source)
  let decoded = try JSONDecoder().decode(
    URITemplate.self,
    from: JSONEncoder().encode(template)
  )

  #expect(decoded == template)
  #expect(
    decoded.templateRepresentation.utf8.elementsEqual(source.utf8)
  )
}

@Test("Copies and evaluation retain the authoritative source")
private func copiesAndEvaluationRetainSource() throws {
  var source = "é{?x,y}%2f"
  let original = try URITemplate(parsing: source)
  let copy = original
  source.append("changed")

  _ = try original.evaluateAsString(
    parameters: exactSourceParameters
  )

  #expect(original.templateRepresentation == "é{?x,y}%2f")
  #expect(copy.templateRepresentation == "é{?x,y}%2f")
  #expect(
    try URITemplate(
      parsing: copy.templateRepresentation
    ) == copy
  )
}

private func verifyExactSourceRoundTrip(
  source: String,
  parameters: [String: URIVariableValue]
) throws {
  let original = try URITemplate(parsing: source)

  #expect(
    original.templateRepresentation.utf8.elementsEqual(source.utf8)
  )
  let reparsed = try URITemplate(
    parsing: original.templateRepresentation
  )
  #expect(reparsed == original)
  #expect(
    reparsed.templateRepresentation.utf8.elementsEqual(source.utf8)
  )
  let originalEvaluation = Result {
    try original.evaluateAsString(parameters: parameters)
  }
  let reparsedEvaluation = Result {
    try reparsed.evaluateAsString(parameters: parameters)
  }
  switch (originalEvaluation, reparsedEvaluation) {
  case (.success(let originalResult), .success(let reparsedResult)):
    #expect(reparsedResult == originalResult)
  case (.failure(let originalError), .failure(let reparsedError)):
    #expect(
      String(reflecting: type(of: reparsedError))
        == String(reflecting: type(of: originalError))
    )
  case (.success, .failure), (.failure, .success):
    Issue.record(
      "Reparsing changed whether evaluation succeeds for source \(source)."
    )
  }
}

private let expressionOperators = [
  "",
  "+",
  "#",
  ".",
  "/",
  ";",
  "?",
  "&",
]

private let exactSourceExamples =
  [
    "",
    "literal",
    "'{x}'",
    "~café/%2f",
    "cafe\u{301}/%2f",
    "𝄞{x}",
    "{x:1}",
    "{x*}",
    "{alpha.%2F}",
    "pre%2f{?name%2F,x}post%AF",
  ]
  + expressionOperators.map {
    "é{\($0)x:12,y*}~"
  }

private let exactSourceParameters: [String: URIVariableValue] = [
  "x": .text("value"),
  "y": .list(["one", "two"]),
  "alpha.%2F": .text("alpha"),
  "name%2F": .text("encoded"),
]

private let generatedLiteralSegments = [
  "",
  "a",
  "%2f",
  "~café",
  "cafe\u{301}",
  "𝄞",
  "'",
  "mid/path",
]

private let generatedVariableLists = [
  "x",
  "x,y",
  "x:1,y*",
  "name%2F,alpha.%2F",
]

private let generatedValidSources: [String] = {
  var sources: Set<String> = []
  for (literalIndex, prefix) in generatedLiteralSegments.enumerated() {
    let suffix = generatedLiteralSegments[
      (literalIndex + 3) % generatedLiteralSegments.count
    ]
    for expressionOperator in expressionOperators {
      for variableList in generatedVariableLists {
        sources.insert(
          "\(prefix){\(expressionOperator)\(variableList)}\(suffix)"
        )
      }
    }
  }
  for expressionOperator in expressionOperators {
    sources.insert(
      "pre{\(expressionOperator)x}mid%2f{?y*}post"
    )
  }
  return sources.sorted()
}()

private let parseableReferenceExamples = allReferenceExamples().filter {
  (try? URITemplate(parsing: $0.testCase.template)) != nil
}
