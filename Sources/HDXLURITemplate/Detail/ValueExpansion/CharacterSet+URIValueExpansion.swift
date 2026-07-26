import Foundation

// RFC-derived Code Components in this file are attributed in
// THIRD_PARTY_NOTICES.md.

extension CharacterSet {
  
  @inlinable
  internal static func allowedCharacters(forValueExpansionType valueExpansionType: URIValueExpansionType) -> Self {
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
@usableFromInline
internal let simpleExpansionAllowedCharacterSet: CharacterSet = rfc_unreserved

// RFC 6570 section 3.2.3 additionally preserves reserved characters and
// valid percent-encoded triplets.
@usableFromInline
internal let reservedExpansionAllowedCharacterSet: CharacterSet = CharacterSet(
  unionOf: [
    rfc_unreserved,
    rfc_reserved,
    rfc_pct_encode
    // ^ technically a misnomer b/c the RFC uses "pct-encode" to refer to a
    // BNF-grammar-spec like % DIGIT DIGIT, but what I did here works for our purposes
  ]
)

// RFC 6570 section 3.2.4 gives fragment values the reserved-expansion
// character set; prefix insertion is handled separately.
@usableFromInline
internal let fragmentAllowedCharacterSet: CharacterSet = reservedExpansionAllowedCharacterSet

// RFC 6570 section 3.2.5 permits only unreserved characters in label values.
@usableFromInline
internal let labelAllowedCharacterSet: CharacterSet = rfc_unreserved

// RFC 6570 section 3.2.6 uses the label value character set for path
// segments; the slash separator is inserted outside the value.
@usableFromInline
internal let pathSegmentAllowedCharacterSet: CharacterSet = labelAllowedCharacterSet

// RFC 6570 section 3.2.7 permits only unreserved path-parameter values.
@usableFromInline
internal let pathParameterAllowedCharacterSet: CharacterSet = rfc_unreserved

// RFC 6570 section 3.2.8 permits only unreserved query values.
@usableFromInline
internal let queryAllowedCharacterSet: CharacterSet = rfc_unreserved

// RFC 6570 section 3.2.9 applies the same rule to query continuations.
@usableFromInline
internal let queryContinuationAllowedCharacterSet: CharacterSet = rfc_unreserved


// -------------------------------------------------------------------------- //
// MARK: Character Sets - From RFC
// -------------------------------------------------------------------------- //

@usableFromInline
internal let rfcALPHA:CharacterSet = CharacterSet(
  charactersIn: [
    "abcdefghijklmnopqrstuvwxyz",
    "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
  ].joined(separator: "")
)

@usableFromInline
internal let rfcDIGIT:CharacterSet = CharacterSet(
  charactersIn: "0123456789"
)

@usableFromInline
internal let rfcHEXDIG:CharacterSet = CharacterSet(
  charactersIn: [
    "0123456789",
    "abcdef",
    "ABCDEF"
  ].joined(separator: "")
)

@usableFromInline
internal let rfc_pct_encode:CharacterSet = CharacterSet(
  charactersIn: "%"
)

@usableFromInline
internal let rfc_gen_delims:CharacterSet = CharacterSet(
  charactersIn: ":/?#[]@"
)

@usableFromInline
internal let rfc_sub_delims:CharacterSet = CharacterSet(
  charactersIn: [
    "!$&'()",
    "*+,;="
  ].joined(separator: "")
)

@usableFromInline
internal let rfc_unreserved:CharacterSet = CharacterSet(
  unionOf: [
    rfcALPHA,
    rfcDIGIT,
    CharacterSet(charactersIn: "-._~")
  ]
)

@usableFromInline
internal let rfc_reserved:CharacterSet = CharacterSet(
  unionOf: [
    rfc_gen_delims,
    rfc_sub_delims
  ]
)

@usableFromInline
internal let rfc_ucschar_uint32_ranges: [ClosedRange<UInt32>] = [
  //  %xA0-D7FF / %xF900-FDCF / %xFDF0-FFEF
  0xA0...0xD7FF,
  0xF900...0xFDFC,
  0xFDF0...0xFFEF,
  
  //  %x10000-1FFFD / %x20000-2FFFD / %x30000-3FFFD
  0x10000...0x1FFFD,
  0x20000...0x2FFFD,
  0x30000...0x3FFFD,
  
  //  %x40000-4FFFD / %x50000-5FFFD / %x60000-6FFFD
  0x40000...0x4FFFD,
  0x50000...0x5FFFD,
  0x60000...0x6FFFD,
  
  //  %x70000-7FFFD / %x80000-8FFFD / %x90000-9FFFD
  0x70000...0x7FFFD,
  0x80000...0x8FFFD,
  0x90000...0x9FFFD,
  
  //  %xA0000-AFFFD / %xB0000-BFFFD / %xC0000-CFFFD
  0xA0000...0xAFFFD,
  0xB0000...0xBFFFD,
  0xC0000...0xCFFFD,
  
  //  %xD0000-DFFFD / %xE1000-EFFFD
  0xD0000...0xDFFFD,
  0xE1000...0xEFFFD
]

@usableFromInline
internal let rfc_ucschar_ranges: [ClosedRange<UnicodeScalar>] = rfc_ucschar_uint32_ranges.map() {
  let lowerBound = infalliblyUnwrap(
    UnicodeScalar($0.lowerBound),
    explanation: """
      `rfc_ucschar_uint32_ranges` adapts the `ucschar` production reproduced \
      by RFC 6570 §1.5 from RFC 3987 §2.2. Every value in that table \
      lies in `0x00A0...0xD7FF` or `0xE000...0x10FFFD`, which sits outside \
      the UTF-16 surrogate gap (`0xD800...0xDFFF`) and at or below the \
      Unicode maximum (`0x10FFFF`). Those two cases are the only reasons \
      `UnicodeScalar.init(_: UInt32)` returns `nil`, so the conversion \
      cannot fail for any value drawn from this table.
      """
  )
  let upperBound = infalliblyUnwrap(
    UnicodeScalar($0.upperBound),
    explanation: """
      Same rationale as the lower bound above: every upper bound in \
      `rfc_ucschar_uint32_ranges` adapts the RFC 6570 §1.5 `ucschar` table, \
      which originates in RFC 3987 §2.2, and lies outside the UTF-16 surrogate \
      gap and at or below the Unicode maximum. `UnicodeScalar.init(_: UInt32)` \
      only returns `nil` for those two cases, neither of which can occur here.
      """
  )
  return lowerBound...upperBound
}

@usableFromInline
internal let rfc_ucschar:CharacterSet = CharacterSet(
  unionOf: rfc_ucschar_ranges
)

@usableFromInline
internal let rfc_iprivate_uint32_ranges: [ClosedRange<UInt32>] = [
  //  %xE000-F8FF
  0xE000...0xF8FF,
  // %xF0000-FFFFD
  0xF0000...0xFFFFD,
  // %x100000-10FFFD
  0x100000...0x10FFFD
]

@usableFromInline
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

@usableFromInline
internal let rfc_iprivate = CharacterSet(
  unionOf: rfc_iprivate_ranges
)
