import HDXLURITemplate
import Testing

@Test("Percent-encoded UTF-8 scalar is one prefix code point")
private func percentEncodedUTF8ScalarIsOnePrefixCodePoint() throws {
  let template = try URITemplate(parsing: "{+x:1}")

  #expect(
    try template.evaluateAsString(
      parameters: ["x": .text("%C3%A9")]
    ) == "%C3%A9"
  )
}

@Test("One- through four-byte encoded scalars remain complete")
private func encodedScalarsRemainComplete() throws {
  let reserved = try URITemplate(parsing: "{+x:1}")
  let fragment = try URITemplate(parsing: "{#x:1}")
  let cases = [
    "%2F",
    "%C2%80",
    "%C3%A9",
    "%DF%BF",
    "%E0%A0%80",
    "%E2%82%AC",
    "%ED%9F%BF",
    "%EE%80%80",
    "%F0%90%80%80",
    "%F0%9D%84%9E",
    "%F4%8F%BF%BF",
    "%c3%a9"
  ]

  for source in cases {
    #expect(
      try reserved.evaluateAsString(
        parameters: ["x": .text(source)]
      ) == source
    )
    #expect(
      try fragment.evaluateAsString(
        parameters: ["x": .text(source)]
      ) == "#\(source)"
    )
  }
}

@Test("Raw and encoded Unicode use the same prefix boundaries")
private func rawAndEncodedUnicodeUseSameBoundaries() throws {
  let cases = [
    (raw: "é", encoded: "%C3%A9"),
    (raw: "€", encoded: "%E2%82%AC"),
    (raw: "𝄞", encoded: "%F0%9D%84%9E")
  ]
  let template = try URITemplate(parsing: "{+x:1}")

  #expect(
    try template.evaluateAsString(
      parameters: ["x": .text("A")]
    ) == "A"
  )
  #expect(
    try template.evaluateAsString(
      parameters: ["x": .text("%41")]
    ) == "%41"
  )

  for testCase in cases {
    #expect(
      try template.evaluateAsString(
        parameters: ["x": .text(testCase.raw)]
      ) == testCase.encoded
    )
    #expect(
      try template.evaluateAsString(
        parameters: ["x": .text(testCase.encoded)]
      ) == testCase.encoded
    )
  }
}

@Test("Mixed literal and encoded values truncate at logical boundaries")
private func mixedValuesTruncateAtLogicalBoundaries() throws {
  let encodedSource = "A%C3%A9B"
  let rawSource = "AéB"
  let encodedExpectations = [
    "A",
    "A%C3%A9",
    "A%C3%A9B",
    "A%C3%A9B"
  ]
  let rawExpectations = [
    "A",
    "A%C3%A9",
    "A%C3%A9B",
    "A%C3%A9B"
  ]

  for prefixLength in 1...4 {
    let template = try URITemplate(
      parsing: "{+x:\(prefixLength)}"
    )
    #expect(
      try template.evaluateAsString(
        parameters: ["x": .text(encodedSource)]
      ) == encodedExpectations[prefixLength - 1]
    )
    #expect(
      try template.evaluateAsString(
        parameters: ["x": .text(rawSource)]
      ) == rawExpectations[prefixLength - 1]
    )
  }
}

@Test("Combining sequences count Unicode code points, not graphemes")
private func combiningSequencesCountCodePoints() throws {
  let rawSource = "e\u{301}Z"
  let encodedSource = "%65%CC%81Z"
  let rawExpectations = [
    "e",
    "e%CC%81",
    "e%CC%81Z"
  ]
  let encodedExpectations = [
    "%65",
    "%65%CC%81",
    "%65%CC%81Z"
  ]

  for prefixLength in 1...3 {
    let template = try URITemplate(
      parsing: "{+x:\(prefixLength)}"
    )
    #expect(
      try template.evaluateAsString(
        parameters: ["x": .text(rawSource)]
      ) == rawExpectations[prefixLength - 1]
    )
    #expect(
      try template.evaluateAsString(
        parameters: ["x": .text(encodedSource)]
      ) == encodedExpectations[prefixLength - 1]
    )
  }
}

@Test("Every operator truncates before applying its escaping policy")
private func everyOperatorUsesDecodedPrefixBoundaries() throws {
  let expectedByTemplate = [
    "{x:1}": "%25C3%25A9",
    "{+x:1}": "%C3%A9",
    "{#x:1}": "#%C3%A9",
    "{.x:1}": ".%25C3%25A9",
    "{/x:1}": "/%25C3%25A9",
    "{;x:1}": ";x=%25C3%25A9",
    "{?x:1}": "?x=%25C3%25A9",
    "{&x:1}": "&x=%25C3%25A9"
  ]

  for (source, expected) in expectedByTemplate {
    let template = try URITemplate(parsing: source)
    #expect(
      try template.evaluateAsString(
        parameters: ["x": .text("%C3%A9Z")]
      ) == expected
    )
  }
}

@Test("Literal and percent-encoded reserved characters retain spelling")
private func reservedCharactersRetainTheirInputSpelling() throws {
  let template = try URITemplate(parsing: "{+x:1}")
  let cases = [
    (source: "/", expected: "/"),
    (source: "%2F", expected: "%2F"),
    (source: "%2f", expected: "%2f"),
    (source: "?", expected: "?"),
    (source: "%3F", expected: "%3F")
  ]

  for testCase in cases {
    #expect(
      try template.evaluateAsString(
        parameters: ["x": .text(testCase.source)]
      ) == testCase.expected
    )
  }
}

@Test("Malformed percent input has deterministic opaque-triplet fallback")
private func malformedPercentInputHasDeterministicFallback() throws {
  let cases = [
    (source: "%", prefixLength: 1, expected: "%25"),
    (source: "%2", prefixLength: 1, expected: "%25"),
    (source: "%2", prefixLength: 2, expected: "%252"),
    (source: "%2G", prefixLength: 1, expected: "%25"),
    (source: "%2G", prefixLength: 2, expected: "%252"),
    (source: "%80Z", prefixLength: 1, expected: "%80"),
    (source: "%C3Z", prefixLength: 1, expected: "%C3"),
    (source: "%C3%41Z", prefixLength: 1, expected: "%C3"),
    (source: "%E2%82Z", prefixLength: 1, expected: "%E2"),
    (source: "%E2%82Z", prefixLength: 2, expected: "%E2%82"),
    (source: "%F0%9F%98Z", prefixLength: 1, expected: "%F0"),
    (source: "%C0%AFZ", prefixLength: 1, expected: "%C0"),
    (source: "%E0%80%80Z", prefixLength: 1, expected: "%E0"),
    (source: "%E0%9F%80Z", prefixLength: 1, expected: "%E0"),
    (source: "%E2%82%41Z", prefixLength: 1, expected: "%E2"),
    (source: "%ED%A0%80Z", prefixLength: 1, expected: "%ED"),
    (source: "%F0%80%80%80Z", prefixLength: 1, expected: "%F0"),
    (source: "%F0%8F%80%80Z", prefixLength: 1, expected: "%F0"),
    (source: "%F0%90%41%80Z", prefixLength: 1, expected: "%F0"),
    (source: "%F0%90%80%41Z", prefixLength: 1, expected: "%F0"),
    (source: "%F4%90%80%80Z", prefixLength: 1, expected: "%F4"),
    (source: "%F5%80%80%80Z", prefixLength: 1, expected: "%F5")
  ]

  for testCase in cases {
    let template = try URITemplate(
      parsing: "{+x:\(testCase.prefixLength)}"
    )
    #expect(
      try template.evaluateAsString(
        parameters: ["x": .text(testCase.source)]
      ) == testCase.expected
    )
  }
}

@Test("Long mixed input truncates at the requested logical unit")
private func longMixedInputTruncatesCorrectly() throws {
  let inputPattern = "A%C3%A9€%F0%9D%84%9E"
  let outputPattern = "A%C3%A9%E2%82%AC%F0%9D%84%9E"
  let input = String(repeating: inputPattern, count: 2_500)
  let expected =
    String(repeating: outputPattern, count: 2_499)
    + "A%C3%A9%E2%82%AC"
  let template = try URITemplate(parsing: "{+x:9999}")

  let output = try template.evaluateAsString(
    parameters: ["x": .text(input)]
  )

  #expect(output.utf8.elementsEqual(expected.utf8))
}
