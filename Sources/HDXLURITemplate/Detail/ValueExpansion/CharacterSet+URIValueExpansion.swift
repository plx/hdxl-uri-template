import Foundation

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

/*
 For each defined variable in the variable-list, perform variable
 expansion, as defined in Section 3.2.1, with the allowed characters
 being those in the unreserved set.
 */
@usableFromInline
internal let simpleExpansionAllowedCharacterSet: CharacterSet = rfc_unreserved

/*
 Reserved expansion, as indicated by the plus ("+") operator for Level
 2 and above templates, is identical to simple string expansion except
 that the substituted values may also contain pct-encoded triplets and
 characters in the reserved set.
 */
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

/*
 Fragment expansion, as indicated by the crosshatch ("#") operator for
 Level 2 and above templates, is identical to reserved expansion
 except that a crosshatch character (fragment delimiter) is appended
 first to the result string if any of the variables are defined.
 */
@usableFromInline
internal let fragmentAllowedCharacterSet: CharacterSet = reservedExpansionAllowedCharacterSet

/*
 For each defined variable in the variable-list, append "." to the
 result string and then perform variable expansion, as defined in
 Section 3.2.1, with the allowed characters being those in the
 unreserved set.
 */
@usableFromInline
internal let labelAllowedCharacterSet: CharacterSet = rfc_unreserved

/*
 Note that the expansion process for path segment expansion is
 identical to that of label expansion aside from the substitution of
 "/" instead of ".".  However, unlike ".", a "/" is a reserved
 character and will be pct-encoded if found in a value.
 */
@usableFromInline
internal let pathSegmentAllowedCharacterSet: CharacterSet = labelAllowedCharacterSet

/*
 o  perform variable expansion, as defined in Section 3.2.1, with the
 allowed characters being those in the unreserved set.
 */
@usableFromInline
internal let pathParameterAllowedCharacterSet: CharacterSet = rfc_unreserved

/*
 o  perform variable expansion, as defined in Section 3.2.1, with the
 allowed characters being those in the unreserved set.
 */
@usableFromInline
internal let queryAllowedCharacterSet: CharacterSet = rfc_unreserved

/*
 o  perform variable expansion, as defined in Section 3.2.1, with the
 allowed characters being those in the unreserved set.
 */
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
    "!$^'()",
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
  guard let lowerBound = UnicodeScalar($0.lowerBound) else {
    fatalError("Lower-bound \($0.lowerBound) of `UInt32` range \($0) couldn't be converted to `UnicodeScalar`!")
  }
  guard let upperBound = UnicodeScalar($0.upperBound) else {
    fatalError("Upper-bound \($0.upperBound) of `UInt32` range \($0) couldn't be converted to `UnicodeScalar`!")
  }
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
  guard let lowerBound = UnicodeScalar($0.lowerBound) else {
    fatalError("Lower-bound \($0.lowerBound) of `UInt32` range \($0) couldn't be converted to `UnicodeScalar`!")
  }
  guard let upperBound = UnicodeScalar($0.upperBound) else {
    fatalError("Upper-bound \($0.upperBound) of `UInt32` range \($0) couldn't be converted to `UnicodeScalar`!")
  }
  return lowerBound...upperBound
}

@usableFromInline
internal let rfc_iprivate = CharacterSet(
  unionOf: rfc_iprivate_ranges
)
