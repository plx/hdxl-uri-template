import Foundation
import Testing

@testable import HDXLURITemplate

private let rfc3986GenDelimiters = ":/?#[]@"
private let rfc3986SubDelimiters = "!$&'()*+,;="
private let rfc3986UnreservedCharacters =
  "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~"
private let rfc3986ReservedCharacters =
  rfc3986GenDelimiters + rfc3986SubDelimiters

private struct PublicOperatorCase {
  let template: String
  let prefix: String
  let preservesReservedCharacters: Bool
}

private let publicOperatorCases = [
  PublicOperatorCase(
    template: "{x}",
    prefix: "",
    preservesReservedCharacters: false
  ),
  PublicOperatorCase(
    template: "{+x}",
    prefix: "",
    preservesReservedCharacters: true
  ),
  PublicOperatorCase(
    template: "{#x}",
    prefix: "#",
    preservesReservedCharacters: true
  ),
  PublicOperatorCase(
    template: "{.x}",
    prefix: ".",
    preservesReservedCharacters: false
  ),
  PublicOperatorCase(
    template: "{/x}",
    prefix: "/",
    preservesReservedCharacters: false
  ),
  PublicOperatorCase(
    template: "{;x}",
    prefix: ";x=",
    preservesReservedCharacters: false
  ),
  PublicOperatorCase(
    template: "{?x}",
    prefix: "?x=",
    preservesReservedCharacters: false
  ),
  PublicOperatorCase(
    template: "{&x}",
    prefix: "&x=",
    preservesReservedCharacters: false
  ),
]

private func expectedExpansion(
  ofASCIIByte byte: UInt8,
  preservingReservedCharacters: Bool
) -> String {
  let shouldRemainUnescaped =
    rfc3986UnreservedCharacters.utf8.contains(byte)
    || (preservingReservedCharacters
      && rfc3986ReservedCharacters.utf8.contains(byte))
  guard !shouldRemainUnescaped else {
    return String(UnicodeScalar(byte))
  }
  return String(format: "%%%02X", Int(byte))
}

@Test("RFC 3986 ASCII character sets and operator sets are exact")
private func rfc3986ASCIICharacterSetsAndOperatorSetsAreExact() {
  for byte in UInt8.min...UInt8(0x7F) {
    let scalar = UnicodeScalar(byte)
    let isGenDelimiter = rfc3986GenDelimiters.utf8.contains(byte)
    let isSubDelimiter = rfc3986SubDelimiters.utf8.contains(byte)
    let isUnreserved = rfc3986UnreservedCharacters.utf8.contains(byte)
    let isReserved = rfc3986ReservedCharacters.utf8.contains(byte)

    #expect(rfc_gen_delims.contains(scalar) == isGenDelimiter)
    #expect(rfc_sub_delims.contains(scalar) == isSubDelimiter)
    #expect(rfc_unreserved.contains(scalar) == isUnreserved)
    #expect(rfc_reserved.contains(scalar) == isReserved)

    for expansionType in URIValueExpansionType.allCases {
      let preservesReservedCharacters =
        expansionType == .reserved || expansionType == .fragment
      let expectedAllowed =
        isUnreserved
        || (preservesReservedCharacters
          && (isReserved || byte == 0x25))
      #expect(
        CharacterSet.allowedCharacters(
          forValueExpansionType: expansionType
        ).contains(scalar) == expectedAllowed
      )
    }
  }

  for scalar in ["é", "日", "😀"] as [UnicodeScalar] {
    #expect(!rfc_gen_delims.contains(scalar))
    #expect(!rfc_sub_delims.contains(scalar))
    #expect(!rfc_unreserved.contains(scalar))
    #expect(!rfc_reserved.contains(scalar))
    for expansionType in URIValueExpansionType.allCases {
      #expect(
        !CharacterSet.allowedCharacters(
          forValueExpansionType: expansionType
        ).contains(scalar)
      )
    }
  }
}

@Test("Every ASCII byte follows every public operator's RFC character set")
private func everyASCIIByteFollowsEveryPublicOperatorCharacterSet() throws {
  let templates = try publicOperatorCases.map {
    (
      testCase: $0,
      template: try URITemplate(parsing: $0.template)
    )
  }

  for byte in UInt8.min...UInt8(0x7F) {
    let value = String(UnicodeScalar(byte))
    let parameters: [String: URIVariableValue] = ["x": .text(value)]

    for entry in templates {
      let expected =
        entry.testCase.prefix
        + expectedExpansion(
          ofASCIIByte: byte,
          preservingReservedCharacters:
            entry.testCase.preservesReservedCharacters
        )
      #expect(
        try entry.template.evaluateAsString(parameters: parameters)
          == expected,
        """
        Unexpected expansion for byte \(byte) under \
        \(entry.testCase.template).
        """
      )
    }
  }
}

@Test("Reserved and fragment expansion preserve triplets and encode nonmembers")
private func reservedAndFragmentExpansionPreserveTripletsAndEncodeNonmembers()
  throws
{
  let simple = try URITemplate(parsing: "{x}")
  let reserved = try URITemplate(parsing: "{+x}")
  let fragment = try URITemplate(parsing: "{#x}")

  let nonmemberParameters: [String: URIVariableValue] = [
    "x": .text("^ \u{0000}é")
  ]
  #expect(
    try reserved.evaluateAsString(parameters: nonmemberParameters)
      == "%5E%20%00%C3%A9"
  )
  #expect(
    try fragment.evaluateAsString(parameters: nonmemberParameters)
      == "#%5E%20%00%C3%A9"
  )

  let tripletParameters: [String: URIVariableValue] = [
    "x": .text("%20%2f%AF")
  ]
  #expect(
    try reserved.evaluateAsString(parameters: tripletParameters)
      == "%20%2f%AF"
  )
  #expect(
    try fragment.evaluateAsString(parameters: tripletParameters)
      == "#%20%2f%AF"
  )
  #expect(
    try simple.evaluateAsString(parameters: tripletParameters)
      == "%2520%252f%25AF"
  )

  let reproducerParameters: [String: URIVariableValue] = [
    "x": .text("a&b^c")
  ]
  #expect(
    try reserved.evaluateAsString(parameters: reproducerParameters)
      == "a&b%5Ec"
  )
  #expect(
    try fragment.evaluateAsString(parameters: reproducerParameters)
      == "#a&b%5Ec"
  )
}
