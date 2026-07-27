import Foundation

// RFC-derived Code Components in this file are attributed in
// THIRD_PARTY_NOTICES.md.

extension CharacterSet {

  internal static func allowedCharacters(
    forValueExpansionType valueExpansionType: URIValueExpansionType
  ) -> Self {
    switch valueExpansionType {
    case .simple:
      simpleExpansionAllowedCharacterSet
    case .reserved:
      reservedExpansionAllowedCharacterSet
    case .fragment:
      fragmentAllowedCharacterSet
    case .label:
      labelAllowedCharacterSet
    case .pathSegment:
      pathSegmentAllowedCharacterSet
    case .pathParameter:
      pathParameterAllowedCharacterSet
    case .query:
      queryAllowedCharacterSet
    case .queryContinuation:
      queryContinuationAllowedCharacterSet
    }
  }

}

// -------------------------------------------------------------------------- //
// MARK: Character Sets - Allowed By Expansion Type
// -------------------------------------------------------------------------- //

// RFC 6570 section 3.2.2 permits only unreserved characters in simple
// expansion values.
internal let simpleExpansionAllowedCharacterSet: CharacterSet = rfc_unreserved

// RFC 6570 section 3.2.3 additionally preserves reserved characters and
// valid percent-encoded triplets.
internal let reservedExpansionAllowedCharacterSet: CharacterSet = CharacterSet(
  unionOf: [
    rfc_unreserved,
    rfc_reserved,
    rfc_pct_encode,
    // ^ technically a misnomer b/c the RFC uses "pct-encode" to refer to a
    // BNF-grammar-spec like % DIGIT DIGIT, but what I did here works for our purposes
  ]
)

// RFC 6570 section 3.2.4 gives fragment values the reserved-expansion
// character set; prefix insertion is handled separately.
internal let fragmentAllowedCharacterSet: CharacterSet = reservedExpansionAllowedCharacterSet

// RFC 6570 section 3.2.5 permits only unreserved characters in label values.
internal let labelAllowedCharacterSet: CharacterSet = rfc_unreserved

// RFC 6570 section 3.2.6 uses the label value character set for path
// segments; the slash separator is inserted outside the value.
internal let pathSegmentAllowedCharacterSet: CharacterSet = labelAllowedCharacterSet

// RFC 6570 section 3.2.7 permits only unreserved path-parameter values.
internal let pathParameterAllowedCharacterSet: CharacterSet = rfc_unreserved

// RFC 6570 section 3.2.8 permits only unreserved query values.
internal let queryAllowedCharacterSet: CharacterSet = rfc_unreserved

// RFC 6570 section 3.2.9 applies the same rule to query continuations.
internal let queryContinuationAllowedCharacterSet: CharacterSet = rfc_unreserved

// -------------------------------------------------------------------------- //
// MARK: Character Sets - From RFC
// -------------------------------------------------------------------------- //

internal let rfcALPHA: CharacterSet = CharacterSet(
  charactersIn: [
    "abcdefghijklmnopqrstuvwxyz",
    "ABCDEFGHIJKLMNOPQRSTUVWXYZ",
  ].joined(separator: "")
)

internal let rfcDIGIT: CharacterSet = CharacterSet(
  charactersIn: "0123456789"
)

internal let rfcHEXDIG: CharacterSet = CharacterSet(
  charactersIn: [
    "0123456789",
    "abcdef",
    "ABCDEF",
  ].joined(separator: "")
)

internal let rfc_pct_encode: CharacterSet = CharacterSet(
  charactersIn: "%"
)

internal let rfc_gen_delims: CharacterSet = CharacterSet(
  charactersIn: ":/?#[]@"
)

internal let rfc_sub_delims: CharacterSet = CharacterSet(
  charactersIn: [
    "!$&'()",
    "*+,;=",
  ].joined(separator: "")
)

internal let rfc_unreserved: CharacterSet = CharacterSet(
  unionOf: [
    rfcALPHA,
    rfcDIGIT,
    CharacterSet(charactersIn: "-._~"),
  ]
)

internal let rfc_reserved: CharacterSet = CharacterSet(
  unionOf: [
    rfc_gen_delims,
    rfc_sub_delims,
  ]
)

internal let rfc_iprivate_uint32_ranges: [ClosedRange<UInt32>] = [
  //  %xE000-F8FF
  0xE000...0xF8FF,
  // %xF0000-FFFFD
  0xF0000...0xFFFFD,
  // %x100000-10FFFD
  0x100000...0x10FFFD,
]

internal let rfc_iprivate_ranges: [ClosedRange<UnicodeScalar>] = rfc_iprivate_uint32_ranges.map() {
  let lowerBound = infalliblyUnwrap(
    UnicodeScalar($0.lowerBound),
    explanation: """
      `rfc_iprivate_uint32_ranges` adapts the `iprivate` production reproduced \
      by RFC 6570 §1.5 from RFC 3987 §2.2. Every value in that table \
      sits inside one of Unicode's private-use planes (`0xE000...0xF8FF`, \
      `0xF0000...0xFFFFD`, or `0x100000...0x10FFFD`) — well above the \
      UTF-16 surrogate gap and at or below the Unicode maximum. \
      `UnicodeScalar.init(_: UInt32)` only returns `nil` for surrogate \
      values or values above `0x10FFFF`, so the conversion cannot fail here.
      """
  )
  let upperBound = infalliblyUnwrap(
    UnicodeScalar($0.upperBound),
    explanation: """
      Same rationale as the lower bound above: every upper bound in \
      `rfc_iprivate_uint32_ranges` lies inside a Unicode private-use plane, \
      outside the surrogate gap, and at or below the Unicode maximum, so \
      `UnicodeScalar.init(_: UInt32)` cannot fail for any value in this table.
      """
  )
  return lowerBound...upperBound
}

internal let rfc_iprivate = CharacterSet(
  unionOf: rfc_iprivate_ranges
)
