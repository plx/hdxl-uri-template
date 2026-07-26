import Foundation
import HDXLURITemplate
import Testing

@Test("JSON encoding is exactly one semantic source string")
private func jsonEncodingIsExactlyOneSemanticSourceString() throws {
  let source = "cafe\u{301}/%2f{?name%2F,x:2,list*}"
  let template = try URITemplate(parsing: source)
  let encoded = try JSONEncoder().encode(template)
  let encodedSourceOnly = try JSONEncoder().encode(source)

  guard
    let encodedSource = try JSONSerialization.jsonObject(
      with: encoded,
      options: .fragmentsAllowed
    ) as? String
  else {
    let observedJSON =
      String(bytes: encoded, encoding: .utf8)
      ?? "<non-UTF-8 data>"
    Issue.record(
      """
      Expected one JSON string containing the validated template source; \
      observed \(observedJSON).
      """
    )
    return
  }

  #expect(encoded == encodedSourceOnly)
  #expect(encodedSource.utf8.elementsEqual(source.utf8))
  let encodedJSON = try #require(
    String(bytes: encoded, encoding: .utf8)
  )
  for legacyKey in ["storage", "expression", "variables", "expansionType"] {
    #expect(!encodedJSON.contains("\"\(legacyKey)\""))
  }
}

@Test("Legacy private-AST payloads are rejected")
private func legacyPrivateASTPayloadsAreRejected() {
  for payload in legacyPrivateASTPayloads {
    do {
      _ = try JSONDecoder().decode(
        URITemplate.self,
        from: payload
      )
      Issue.record(
        "A legacy private-AST payload unexpectedly decoded."
      )
    } catch DecodingError.typeMismatch(_, let context) {
      #expect(context.codingPath.isEmpty)
    } catch {
      Issue.record(
        """
        Expected a String type mismatch for a legacy private-AST payload; \
        observed \(String(reflecting: error)).
        """
      )
    }
  }
}

@Test("Invalid semantic strings preserve the public parser failure")
private func invalidSemanticStringsPreserveParserFailure() throws {
  for source in ["{}", "{", "{x:0}"] {
    let payload = try JSONEncoder().encode(source)

    do {
      _ = try JSONDecoder().decode(
        URITemplate.self,
        from: payload
      )
      Issue.record(
        "An invalid URI-template source unexpectedly decoded."
      )
    } catch DecodingError.dataCorrupted(let context) {
      #expect(context.codingPath.isEmpty)
      #expect(
        context.debugDescription
          == "Invalid URI template string."
      )
      let parseError = try #require(
        context.underlyingError as? URITemplate.ParseError
      )
      #expect(
        parseError.template.utf8.elementsEqual(source.utf8)
      )
    } catch {
      Issue.record(
        """
        Expected DecodingError.dataCorrupted for an invalid semantic \
        string; observed \(String(reflecting: error)).
        """
      )
    }
  }
}

@Test("Invalid nested strings retain their coding path")
private func invalidNestedStringsRetainCodingPath() throws {
  let payload = try JSONEncoder().encode(["valid", "{"])

  do {
    _ = try JSONDecoder().decode(
      [URITemplate].self,
      from: payload
    )
    Issue.record(
      "A collection containing an invalid template unexpectedly decoded."
    )
  } catch DecodingError.dataCorrupted(let context) {
    let key = try #require(context.codingPath.first)
    #expect(context.codingPath.count == 1)
    #expect(key.intValue == 1)
    #expect(
      context.underlyingError is URITemplate.ParseError
    )
  } catch {
    Issue.record(
      """
      Expected dataCorrupted for an invalid nested semantic string; \
      observed \(String(reflecting: error)).
      """
    )
  }
}

@Test("Malformed JSON fails by category without trapping")
private func malformedJSONFailsByCategoryWithoutTrapping() {
  verifyNonStringJSONFailsWithTypeMismatch()
  verifyNullJSONFailsWithValueNotFound()
  verifyTruncatedJSONFailsWithDataCorrupted()
}

private func verifyNonStringJSONFailsWithTypeMismatch() {
  let nonStringPayloads = ["0", "true", "[]", "{}"].map {
    Data($0.utf8)
  }
  for payload in nonStringPayloads {
    do {
      _ = try JSONDecoder().decode(
        URITemplate.self,
        from: payload
      )
      Issue.record("A non-String JSON value unexpectedly decoded.")
    } catch DecodingError.typeMismatch(_, let context) {
      #expect(context.codingPath.isEmpty)
    } catch {
      Issue.record(
        """
        Expected a String type mismatch; observed \
        \(String(reflecting: error)).
        """
      )
    }
  }
}

private func verifyNullJSONFailsWithValueNotFound() {
  do {
    _ = try JSONDecoder().decode(
      URITemplate.self,
      from: Data("null".utf8)
    )
    Issue.record("JSON null unexpectedly decoded.")
  } catch DecodingError.valueNotFound(_, let context) {
    #expect(context.codingPath.isEmpty)
  } catch {
    Issue.record(
      """
      Expected valueNotFound for JSON null; observed \
      \(String(reflecting: error)).
      """
    )
  }
}

private func verifyTruncatedJSONFailsWithDataCorrupted() {
  for payload in [Data(), Data(#""truncated"#.utf8)] {
    do {
      _ = try JSONDecoder().decode(
        URITemplate.self,
        from: payload
      )
      Issue.record("Truncated JSON unexpectedly decoded.")
    } catch DecodingError.dataCorrupted(let context) {
      #expect(context.codingPath.isEmpty)
    } catch {
      Issue.record(
        """
        Expected dataCorrupted for truncated JSON; observed \
        \(String(reflecting: error)).
        """
      )
    }
  }
}

private let legacyPrivateASTPayloads: [Data] = {
  var payloads: [Data] = []
  // The old synthesized representation of an empty template.
  payloads.append(Data(#"{"storage":[]}"#.utf8))
  // The old encoder's concrete representation of a valid template.
  payloads.append(
    Data(
      """
      {
        "storage": [
          {"literal":{"_0":"café/%2f"}},
          {
            "expression": {
              "_0": {
                "expansionType": 64,
                "variables": [
                  {
                    "variableName": "name%2F",
                    "expansionModifier": {"type": 1}
                  },
                  {
                    "variableName": "x",
                    "expansionModifier": {"type": 4, "data": 2}
                  },
                  {
                    "variableName": "list",
                    "expansionModifier": {"type": 2}
                  }
                ]
              }
            }
          }
        ]
      }
      """.utf8
    )
  )
  // The audited empty-expression payload must remain safely rejected too.
  payloads.append(
    Data(
      """
      {
        "storage": [
          {
            "expression": {
              "_0": {
                "variables": [],
                "expansionType": 1
              }
            }
          }
        ]
      }
      """.utf8
    )
  )
  return payloads
}()
