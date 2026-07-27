import Testing

@testable import HDXLURITemplate

@Test("Literal expansion UTF-8 percent-encodes Unicode and preserves URI text")
private func literalExpansionPercentEncodesUnicodeAndPreservesURIText() throws {
  let cases: [(source: String, expected: String)] = [
    (
      "aZ09-._~!#$&'()*+,/:;=?@[]/{var}",
      "aZ09-._~!#$&'()*+,/:;=?@[]/value"
    ),
    ("café/{var}", "caf%C3%A9/value"),
    ("λ/{var}", "%CE%BB/value"),
    ("日/{var}", "%E6%97%A5/value"),
    ("😀/{var}", "%F0%9F%98%80/value"),
    (
      "e\u{0301}/é日😀/{var}",
      "e%CC%81/%C3%A9%E6%97%A5%F0%9F%98%80/value"
    ),
    ("%C3%A9/%c3%a9/{var}", "%C3%A9/%c3%a9/value"),
    ("%20/%Af/%aF/{var}", "%20/%Af/%aF/value"),
    (
      "preé-mid日-post😀/{var}",
      "pre%C3%A9-mid%E6%97%A5-post%F0%9F%98%80/value"
    ),
    ("\u{00A0}/{var}", "%C2%A0/value"),
  ]

  for testCase in cases {
    let template = try URITemplate(parsing: testCase.source)

    #expect(
      template.templateRepresentation.utf8.elementsEqual(
        testCase.source.utf8
      ),
      "Template source must remain byte-for-byte unchanged."
    )
    #expect(
      try template.evaluateAsString(
        parameters: ["var": .text("value")]
      ) == testCase.expected,
      "Unexpected literal expansion for \(testCase.source.debugDescription)."
    )
  }
}
