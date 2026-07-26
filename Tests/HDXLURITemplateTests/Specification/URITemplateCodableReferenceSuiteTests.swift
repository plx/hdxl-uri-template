import Foundation
import HDXLURITemplate
import Testing

@Test("Codable reference-suite partitions are complete")
private func codableReferenceSuitePartitionsAreComplete() {
  #expect(positiveCodableReferenceExamples.count == 234)
  #expect(negativeCodableReferenceExamples.count == 36)
  #expect(
    positiveCodableReferenceExamples.count
      + negativeCodableReferenceExamples.count
      == 270
  )
}

@Test(
  "Every positive pinned example retains source and semantics",
  arguments: positiveCodableReferenceExamples
)
private func everyPositivePinnedExampleRetainsSourceAndSemantics(
  example: CaptionedTestCase
) throws {
  let original = try URITemplate(
    parsing: example.testCase.template
  )
  let originalExpansion = try original.evaluateAsString(
    parameters: example.parameters
  )
  verifyPinnedExpansion(
    originalExpansion,
    expectation: example.testCase.expectation
  )
  try verifyJSONReferenceRoundTrip(
    original: original,
    example: example,
    expectedExpansion: originalExpansion
  )
  try verifyPropertyListReferenceRoundTrips(
    original: original,
    example: example,
    expectedExpansion: originalExpansion
  )
}

private func verifyJSONReferenceRoundTrip(
  original: URITemplate,
  example: CaptionedTestCase,
  expectedExpansion: String
) throws {
  let json = try JSONEncoder().encode(original)
  let jsonSource = try JSONDecoder().decode(
    String.self,
    from: json
  )
  #expect(
    jsonSource.utf8.elementsEqual(
      example.testCase.template.utf8
    )
  )
  let jsonDecoded = try JSONDecoder().decode(
    URITemplate.self,
    from: json
  )
  try verifyReferenceCodableRoundTrip(
    original: original,
    decoded: jsonDecoded,
    expectedExpansion: expectedExpansion,
    parameters: example.parameters
  )
}

private func verifyPropertyListReferenceRoundTrips(
  original: URITemplate,
  example: CaptionedTestCase,
  expectedExpansion: String
) throws {
  for outputFormat in referencePropertyListFormats {
    let encoder = PropertyListEncoder()
    encoder.outputFormat = outputFormat
    let propertyList = try encoder.encode([original])
    let propertyListObject =
      try PropertyListSerialization.propertyList(
        from: propertyList,
        options: [],
        format: nil
      )
    let propertyListSources = try #require(
      propertyListObject as? [String]
    )
    #expect(propertyListSources.count == 1)
    if let propertyListSource = propertyListSources.first {
      #expect(
        propertyListSource.utf8.elementsEqual(
          example.testCase.template.utf8
        )
      )
    }

    let decodedArray = try PropertyListDecoder().decode(
      [URITemplate].self,
      from: propertyList
    )
    let decoded = try #require(decodedArray.first)
    try verifyReferenceCodableRoundTrip(
      original: original,
      decoded: decoded,
      expectedExpansion: expectedExpansion,
      parameters: example.parameters
    )
  }
}

@Test(
  "Pinned failure cases share the public parser acceptance boundary",
  arguments: negativeCodableReferenceExamples
)
private func pinnedFailureCasesSharePublicParserAcceptanceBoundary(
  example: CaptionedTestCase
) throws {
  let source = example.testCase.template
  let semanticPayload = try JSONEncoder().encode(source)
  let parsingResult: Result<URITemplate, Error> = Result {
    try URITemplate(parsing: source)
  }

  switch parsingResult {
  case .success(let original):
    try verifyDecodedEvaluationFailure(
      original: original,
      semanticPayload: semanticPayload,
      example: example
    )

  case .failure(let directError):
    try verifyRejectedParserInput(
      directError: directError,
      semanticPayload: semanticPayload
    )
  }
}

private func verifyDecodedEvaluationFailure(
  original: URITemplate,
  semanticPayload: Data,
  example: CaptionedTestCase
) throws {
  let decoded = try JSONDecoder().decode(
    URITemplate.self,
    from: semanticPayload
  )
  #expect(decoded == original)
  #expect(
    decoded.templateRepresentation.utf8.elementsEqual(
      example.testCase.template.utf8
    )
  )
  #expect(decoded.variableNames == original.variableNames)

  let originalEvaluation: Result<String, Error> = Result {
    try original.evaluateAsString(
      parameters: example.parameters
    )
  }
  let decodedEvaluation: Result<String, Error> = Result {
    try decoded.evaluateAsString(
      parameters: example.parameters
    )
  }
  switch (originalEvaluation, decodedEvaluation) {
  case (.failure(let originalError), .failure(let decodedError)):
    #expect(
      String(reflecting: type(of: decodedError))
        == String(reflecting: type(of: originalError))
    )
  case (.success, .success):
    Issue.record(
      "A pinned evaluation-failure case unexpectedly evaluated."
    )
  case (.success, .failure), (.failure, .success):
    Issue.record(
      """
      Decoding changed whether a pinned failure case evaluates \
      successfully.
      """
    )
  }
}

private func verifyRejectedParserInput(
  directError: Error,
  semanticPayload: Data
) throws {
  let directParseError = try #require(
    directError as? URITemplate.ParseError
  )
  do {
    _ = try JSONDecoder().decode(
      URITemplate.self,
      from: semanticPayload
    )
    Issue.record(
      "A source rejected by the public parser unexpectedly decoded."
    )
  } catch DecodingError.dataCorrupted(let context) {
    let decodingParseError = try #require(
      context.underlyingError as? URITemplate.ParseError
    )
    #expect(context.codingPath.isEmpty)
    #expect(
      decodingParseError.template.utf8.elementsEqual(
        directParseError.template.utf8
      )
    )
  } catch {
    Issue.record(
      """
      Expected dataCorrupted for a parser-rejected source; observed \
      \(String(reflecting: error)).
      """
    )
  }
}

private func verifyReferenceCodableRoundTrip(
  original: URITemplate,
  decoded: URITemplate,
  expectedExpansion: String,
  parameters: [String: URIVariableValue]
) throws {
  #expect(decoded == original)
  #expect(
    decoded.templateRepresentation.utf8.elementsEqual(
      original.templateRepresentation.utf8
    )
  )
  #expect(decoded.variableNames == original.variableNames)

  let decodedExpansion = try decoded.evaluateAsString(
    parameters: parameters
  )
  #expect(decodedExpansion == expectedExpansion)

  let reparsed = try URITemplate(
    parsing: decoded.templateRepresentation
  )
  #expect(reparsed == decoded)
  #expect(
    reparsed.templateRepresentation.utf8.elementsEqual(
      decoded.templateRepresentation.utf8
    )
  )
}

private func verifyPinnedExpansion(
  _ expansion: String,
  expectation: ReferenceExampleExpectation
) {
  switch expectation {
  case .evaluationFailure:
    Issue.record(
      "An evaluation-failure case entered the positive partition."
    )
  case .exactMatch(let expected):
    #expect(expansion == expected)
  case .multiplePossibleMatches(let expected):
    #expect(expected.contains(expansion))
  }
}

private let positiveCodableReferenceExamples =
  allReferenceExamples().filter {
    switch $0.testCase.expectation {
    case .exactMatch, .multiplePossibleMatches:
      true
    case .evaluationFailure:
      false
    }
  }

private let negativeCodableReferenceExamples =
  allReferenceExamples().filter {
    switch $0.testCase.expectation {
    case .evaluationFailure:
      true
    case .exactMatch, .multiplePossibleMatches:
      false
    }
  }

private typealias PropertyListFormat = PropertyListSerialization.PropertyListFormat

private let referencePropertyListFormats: [PropertyListFormat] = [.xml, .binary]
