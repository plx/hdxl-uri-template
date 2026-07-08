import Foundation
import Testing
@testable import HDXLURITemplate

extension Tag {
  @Tag
  static var infalliblyUnwrapAssumptions: Self
}

// -------------------------------------------------------------------------- //
// MARK: Unicode scalar range invariants
// -------------------------------------------------------------------------- //

/// Range used by Apple's `UnicodeScalar.init(_: UInt32)` to reject UTF-16 surrogates.
private let utf16SurrogateGap: ClosedRange<UInt32> = 0xD800...0xDFFF

/// The Unicode maximum code point.
private let unicodeMaximum: UInt32 = 0x10FFFF

private func firstCodePointNotConvertibleToUnicodeScalar(
  in ranges: [ClosedRange<UInt32>]
) -> UInt32? {
  for range in ranges {
    for codePoint in range where UnicodeScalar(codePoint) == nil {
      return codePoint
    }
  }
  return nil
}

private func firstRangeViolatingUnicodeScalarInvariants(
  in ranges: [ClosedRange<UInt32>]
) -> ClosedRange<UInt32>? {
  for range in ranges {
    guard range.lowerBound <= range.upperBound else { return range }
    guard range.upperBound <= unicodeMaximum else { return range }
    let overlapsSurrogateGap = range.lowerBound <= utf16SurrogateGap.upperBound
      && range.upperBound >= utf16SurrogateGap.lowerBound
    if overlapsSurrogateGap { return range }
  }
  return nil
}

@Test(
  "`rfc_ucschar_uint32_ranges` are structurally within the convertible-to-`UnicodeScalar` envelope",
  .tags(.infalliblyUnwrapAssumptions)
)
private func rfcUcscharRangesAreStructurallyValid() {
  let violator = firstRangeViolatingUnicodeScalarInvariants(in: rfc_ucschar_uint32_ranges)
  #expect(
    violator == nil,
    """
    A range in `rfc_ucschar_uint32_ranges` violates the invariants that make \
    `UnicodeScalar.init(_: UInt32)` infallible — either it is malformed \
    (lower > upper), extends above `0x10FFFF`, or overlaps the UTF-16 \
    surrogate gap (`0xD800...0xDFFF`). Offending range: \
    \(violator.map { String(describing: $0) } ?? "<none>").
    """
  )
}

@Test(
  "Every `UInt32` in `rfc_ucschar_uint32_ranges` converts to a non-nil `UnicodeScalar`",
  .tags(.infalliblyUnwrapAssumptions)
)
private func rfcUcscharValuesConvertToUnicodeScalar() {
  let failingCodePoint = firstCodePointNotConvertibleToUnicodeScalar(in: rfc_ucschar_uint32_ranges)
  #expect(
    failingCodePoint == nil,
    """
    `UnicodeScalar.init(_: UInt32)` unexpectedly returned `nil` for a value \
    drawn from `rfc_ucschar_uint32_ranges`. This breaks the assumption used \
    by `infalliblyUnwrap` at the construction site of `rfc_ucschar_ranges`. \
    First failing code point: \
    \(failingCodePoint.map { "U+\(String($0, radix: 16, uppercase: true))" } ?? "<none>").
    """
  )
}

@Test(
  "`rfc_iprivate_uint32_ranges` are structurally within the convertible-to-`UnicodeScalar` envelope",
  .tags(.infalliblyUnwrapAssumptions)
)
private func rfcIprivateRangesAreStructurallyValid() {
  let violator = firstRangeViolatingUnicodeScalarInvariants(in: rfc_iprivate_uint32_ranges)
  #expect(
    violator == nil,
    """
    A range in `rfc_iprivate_uint32_ranges` violates the invariants that make \
    `UnicodeScalar.init(_: UInt32)` infallible — either it is malformed \
    (lower > upper), extends above `0x10FFFF`, or overlaps the UTF-16 \
    surrogate gap (`0xD800...0xDFFF`). Offending range: \
    \(violator.map { String(describing: $0) } ?? "<none>").
    """
  )
}

@Test(
  "Every `UInt32` in `rfc_iprivate_uint32_ranges` converts to a non-nil `UnicodeScalar`",
  .tags(.infalliblyUnwrapAssumptions)
)
private func rfcIprivateValuesConvertToUnicodeScalar() {
  let failingCodePoint = firstCodePointNotConvertibleToUnicodeScalar(in: rfc_iprivate_uint32_ranges)
  #expect(
    failingCodePoint == nil,
    """
    `UnicodeScalar.init(_: UInt32)` unexpectedly returned `nil` for a value \
    drawn from `rfc_iprivate_uint32_ranges`. This breaks the assumption used \
    by `infalliblyUnwrap` at the construction site of `rfc_iprivate_ranges`. \
    First failing code point: \
    \(failingCodePoint.map { "U+\(String($0, radix: 16, uppercase: true))" } ?? "<none>").
    """
  )
}

// -------------------------------------------------------------------------- //
// MARK: `addingPercentEncoding` non-nil assumption
// -------------------------------------------------------------------------- //

/// Curated representative inputs that exercise the code paths feeding into
/// `String.escaped(forValueExpansionType:)`. Includes empty strings, plain
/// ASCII, reserved/sub-delim characters, Latin Extended, CJK, emoji ZWJ
/// sequences, combining marks, control characters, private-use scalars,
/// and supplementary-plane scalars.
private let percentEncodingSanityStrings: [String] = [
  "",
  " ",
  "abc",
  "ABCxyz0123",
  "Hello, World!",
  "/path/to/resource",
  "?query=value&other=value",
  "<script>alert('xss')</script>",
  "key:value;foo=bar",
  "café",
  "naïve façade jalapeño",
  "日本語テスト",
  "Ω≈ç√∫˜µ≤≥÷",
  "👨‍👩‍👧‍👦",
  "👋🏽",
  "e\u{0301}",                    // combining acute accent
  "a\u{0301}\u{0302}\u{0303}",    // multiple combining marks
  "%20already%encoded%2F",
  "100% pure",
  "\t\n\r\u{0000}\u{0001}\u{007F}",
  "\u{E000}\u{F8FF}",              // BMP private use area
  "\u{10000}",                     // first non-BMP scalar
  "\u{FFFD}",                      // replacement character
  "\u{1F600}\u{1F4A9}",            // supplementary-plane emoji
  "\u{F0000}\u{FFFFD}",            // supplementary private-use plane A
  "\u{100000}\u{10FFFD}",          // supplementary private-use plane B
  String(repeating: "x", count: 1024)
]

@Test(
  "`addingPercentEncoding(withAllowedCharacters:)` returns non-nil for representative Swift `String` inputs across all expansion types",
  .tags(.infalliblyUnwrapAssumptions),
  arguments: URIValueExpansionType.allCases
)
private func addingPercentEncodingNeverReturnsNil(expansionType: URIValueExpansionType) {
  let allowedCharacters = CharacterSet.allowedCharacters(forValueExpansionType: expansionType)
  let unescapedAllowedCharacters = allowedCharacters.subtracting(rfc_pct_encode)

  for testString in percentEncodingSanityStrings {
    #expect(
      testString.addingPercentEncoding(withAllowedCharacters: allowedCharacters) != nil,
      """
      `String.addingPercentEncoding(withAllowedCharacters:)` returned `nil` \
      for input \(testString.debugDescription) with the full allowed-character \
      set for expansion type \(expansionType). This breaks the assumption used \
      by `infalliblyUnwrap` at the non-triplets branch of `String.escaped(forValueExpansionType:)`.
      """
    )
    #expect(
      testString.addingPercentEncoding(withAllowedCharacters: unescapedAllowedCharacters) != nil,
      """
      `String.addingPercentEncoding(withAllowedCharacters:)` returned `nil` \
      for input \(testString.debugDescription) with the allowed-character set \
      minus `rfc_pct_encode` for expansion type \(expansionType). This breaks \
      the assumption used by `infalliblyUnwrap` inside the per-chunk loop of \
      `String.escaped(forValueExpansionType:)`.
      """
    )
  }
}

@Test(
  "`addingPercentEncoding` returns non-nil for `String.UnicodeScalarView` slices that survive `decomposedIntoEscapedAndUnescapedParts`",
  .tags(.infalliblyUnwrapAssumptions),
  arguments: URIValueExpansionType.allCases
)
private func decomposedChunksRoundTripThroughAddingPercentEncoding(expansionType: URIValueExpansionType) {
  let unescapedAllowedCharacters = CharacterSet
    .allowedCharacters(forValueExpansionType: expansionType)
    .subtracting(rfc_pct_encode)

  for testString in percentEncodingSanityStrings {
    for piece in testString.unicodeScalars.decomposedIntoEscapedAndUnescapedParts {
      guard case .unescaped(let chunk) = piece else { continue }
      #expect(
        chunk.addingPercentEncoding(withAllowedCharacters: unescapedAllowedCharacters) != nil,
        """
        `addingPercentEncoding(withAllowedCharacters:)` returned `nil` for an \
        unescaped chunk \(chunk.debugDescription) (carved from \
        \(testString.debugDescription)) under expansion type \(expansionType). \
        This breaks the assumption used by `infalliblyUnwrap` at the per-chunk \
        call site in `String.escaped(forValueExpansionType:)`.
        """
      )
    }
  }
}

// -------------------------------------------------------------------------- //
// MARK: `infalliblyUnwrap` itself
// -------------------------------------------------------------------------- //

@Test(
  "`infalliblyUnwrap` returns the wrapped value for non-`nil` inputs",
  .tags(.infalliblyUnwrapAssumptions)
)
private func infalliblyUnwrapReturnsWrappedValue() {
  #expect(infalliblyUnwrap(Int?.some(42), explanation: "test") == 42)
  #expect(infalliblyUnwrap(String?.some("hello"), explanation: "test") == "hello")
  #expect(infalliblyUnwrap([1, 2, 3] as [Int]?, explanation: "test") == [1, 2, 3])
  #expect(infalliblyUnwrap(UnicodeScalar(0x41), explanation: "test") == "A")
}
