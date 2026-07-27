import HDXLURITemplate
import Testing

@Test("Seeded prefix corpus agrees with an independent logical-unit oracle")
private func seededPrefixCorpusMatchesReferenceUnits() throws {
  let prefixLengths = [1, 2, 3, 7, 13, 20, 21]

  for seed in PrefixReferenceUnit.all.indices {
    let sourceUnits = (0..<20).map {
      PrefixReferenceUnit.all[
        (seed * 7 + $0 * 5) % PrefixReferenceUnit.all.count
      ]
    }
    let source = sourceUnits.map(\.source).joined()

    for prefixLength in prefixLengths {
      let selectedUnits = sourceUnits.prefix(prefixLength)
      for operatorReference in PrefixOperatorReference.all {
        let expectedValue = selectedUnits.map {
          operatorReference.preservesPercentEncoding
            ? $0.reserved
            : $0.ordinary
        }.joined()
        let template = try URITemplate(
          parsing: operatorReference.template(
            prefixLength: prefixLength
          )
        )

        #expect(
          try template.evaluateAsString(
            parameters: ["x": .text(source)]
          ) == operatorReference.expansion(expectedValue: expectedValue)
        )
      }
    }
  }
}

private struct PrefixReferenceUnit {

  let source: String
  let ordinary: String
  let reserved: String

  static let all = [
    Self(source: "A", ordinary: "A", reserved: "A"),
    Self(source: "~", ordinary: "~", reserved: "~"),
    Self(source: "/", ordinary: "%2F", reserved: "/"),
    Self(source: "?", ordinary: "%3F", reserved: "?"),
    Self(
      source: "é",
      ordinary: "%C3%A9",
      reserved: "%C3%A9"
    ),
    Self(
      source: "€",
      ordinary: "%E2%82%AC",
      reserved: "%E2%82%AC"
    ),
    Self(
      source: "𝄞",
      ordinary: "%F0%9D%84%9E",
      reserved: "%F0%9D%84%9E"
    ),
    Self(
      source: "\u{301}",
      ordinary: "%CC%81",
      reserved: "%CC%81"
    ),
    Self(source: "%41", ordinary: "%2541", reserved: "%41"),
    Self(source: "%2F", ordinary: "%252F", reserved: "%2F"),
    Self(
      source: "%c3%a9",
      ordinary: "%25c3%25a9",
      reserved: "%c3%a9"
    ),
    Self(
      source: "%E2%82%AC",
      ordinary: "%25E2%2582%25AC",
      reserved: "%E2%82%AC"
    ),
    Self(
      source: "%F0%9D%84%9E",
      ordinary: "%25F0%259D%2584%259E",
      reserved: "%F0%9D%84%9E"
    ),
    Self(source: "%80", ordinary: "%2580", reserved: "%80"),
    Self(source: "%C0", ordinary: "%25C0", reserved: "%C0"),
    Self(source: "%F5", ordinary: "%25F5", reserved: "%F5"),
    Self(source: "%25", ordinary: "%2525", reserved: "%25"),
  ]

}

private struct PrefixOperatorReference {

  let symbol: String
  let expansionPrefix: String
  let usesVariableName: Bool
  let preservesPercentEncoding: Bool

  static let all = [
    Self(
      symbol: "",
      expansionPrefix: "",
      usesVariableName: false,
      preservesPercentEncoding: false
    ),
    Self(
      symbol: "+",
      expansionPrefix: "",
      usesVariableName: false,
      preservesPercentEncoding: true
    ),
    Self(
      symbol: "#",
      expansionPrefix: "#",
      usesVariableName: false,
      preservesPercentEncoding: true
    ),
    Self(
      symbol: ".",
      expansionPrefix: ".",
      usesVariableName: false,
      preservesPercentEncoding: false
    ),
    Self(
      symbol: "/",
      expansionPrefix: "/",
      usesVariableName: false,
      preservesPercentEncoding: false
    ),
    Self(
      symbol: ";",
      expansionPrefix: ";",
      usesVariableName: true,
      preservesPercentEncoding: false
    ),
    Self(
      symbol: "?",
      expansionPrefix: "?",
      usesVariableName: true,
      preservesPercentEncoding: false
    ),
    Self(
      symbol: "&",
      expansionPrefix: "&",
      usesVariableName: true,
      preservesPercentEncoding: false
    ),
  ]

  func template(prefixLength: Int) -> String {
    "{\(symbol)x:\(prefixLength)}"
  }

  func expansion(expectedValue: String) -> String {
    if usesVariableName {
      return "\(expansionPrefix)x=\(expectedValue)"
    }
    return "\(expansionPrefix)\(expectedValue)"
  }

}
