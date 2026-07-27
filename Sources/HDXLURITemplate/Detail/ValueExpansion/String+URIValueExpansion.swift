import Foundation

// RFC-derived Code Components in this file are attributed in
// THIRD_PARTY_NOTICES.md.

extension UInt8 {

  internal var asciiHexadecimalDigitValue: UInt8? {
    switch self {
    case 0x30...0x39:
      self - 0x30
    case 0x41...0x46:
      self - 0x41 + 10
    case 0x61...0x66:
      self - 0x61 + 10
    default:
      nil
    }
  }

  internal var isASCIIHexadecimalDigit: Bool {
    asciiHexadecimalDigitValue != nil
  }

  internal var isUTF8ContinuationByte: Bool {
    (0x80...0xBF).contains(self)
  }

  internal func isValidUTF8SecondByte(
    after leadingByte: UInt8
  ) -> Bool {
    switch leadingByte {
    case 0xE0:
      (0xA0...0xBF).contains(self)
    case 0xED:
      (0x80...0x9F).contains(self)
    case 0xF0:
      (0x90...0xBF).contains(self)
    case 0xF4:
      (0x80...0x8F).contains(self)
    default:
      isUTF8ContinuationByte
    }
  }

}

extension String.UTF8View {

  internal func percentEncodedByte(
    startingAt position: Index
  ) -> (value: UInt8, endIndex: Index)? {
    guard position != endIndex, self[position] == 0x25 else { return nil }

    let firstDigitPosition = index(after: position)
    guard firstDigitPosition != endIndex else { return nil }

    let secondDigitPosition = index(after: firstDigitPosition)
    guard secondDigitPosition != endIndex else { return nil }
    guard
      let highNibble = self[firstDigitPosition].asciiHexadecimalDigitValue,
      let lowNibble = self[secondDigitPosition].asciiHexadecimalDigitValue
    else {
      return nil
    }

    return (
      value: highNibble << 4 | lowNibble,
      endIndex: index(after: secondDigitPosition)
    )
  }

  internal func indexAfterPercentEncodedTriplet(
    startingAt position: Index
  ) -> Index? {
    percentEncodedByte(startingAt: position)?.endIndex
  }

  /// Returns the boundary after one URI-value code point beginning at a
  /// syntactically-valid percent triplet.
  ///
  /// A well-formed percent-encoded UTF-8 scalar consumes all of its triplets.
  /// A triplet that cannot begin such a scalar is an opaque one-unit fallback;
  /// this preserves the established reserved-expansion behavior for arbitrary
  /// `%HH` input without joining it to unrelated following triplets.
  internal func indexAfterPercentEncodedURIValueCodePoint(
    startingAt position: Index
  ) -> Index? {
    guard
      let firstByte = percentEncodedByte(startingAt: position)
    else {
      return nil
    }

    switch firstByte.value {
    case 0x00...0x7F:
      return firstByte.endIndex

    case 0xC2...0xDF:
      guard
        let secondByte = percentEncodedByte(
          startingAt: firstByte.endIndex
        ),
        secondByte.value.isUTF8ContinuationByte
      else {
        return firstByte.endIndex
      }
      return secondByte.endIndex

    case 0xE0...0xEF:
      return indexAfterThreeBytePercentEncodedScalar(
        startingWith: firstByte
      )

    case 0xF0...0xF4:
      return indexAfterFourBytePercentEncodedScalar(
        startingWith: firstByte
      )

    default:
      return firstByte.endIndex
    }
  }

  internal func indexAfterThreeBytePercentEncodedScalar(
    startingWith firstByte: (value: UInt8, endIndex: Index)
  ) -> Index {
    guard
      let secondByte = percentEncodedByte(
        startingAt: firstByte.endIndex
      ),
      secondByte.value.isValidUTF8SecondByte(after: firstByte.value),
      let thirdByte = percentEncodedByte(
        startingAt: secondByte.endIndex
      ),
      thirdByte.value.isUTF8ContinuationByte
    else {
      return firstByte.endIndex
    }
    return thirdByte.endIndex
  }

  internal func indexAfterFourBytePercentEncodedScalar(
    startingWith firstByte: (value: UInt8, endIndex: Index)
  ) -> Index {
    guard
      let secondByte = percentEncodedByte(
        startingAt: firstByte.endIndex
      ),
      secondByte.value.isValidUTF8SecondByte(after: firstByte.value),
      let thirdByte = percentEncodedByte(
        startingAt: secondByte.endIndex
      ),
      thirdByte.value.isUTF8ContinuationByte,
      let fourthByte = percentEncodedByte(
        startingAt: thirdByte.endIndex
      ),
      fourthByte.value.isUTF8ContinuationByte
    else {
      return firstByte.endIndex
    }
    return fourthByte.endIndex
  }

  /// Returns the boundary after one literal scalar in a valid Swift string.
  internal func indexAfterLiteralUnicodeScalar(
    startingAt position: Index
  ) -> Index {
    let scalarByteCount =
      switch self[position] {
      case 0x00...0x7F:
        1
      case 0xC2...0xDF:
        2
      case 0xE0...0xEF:
        3
      default:
        4
      }
    var result = position
    for _ in 0..<scalarByteCount {
      result = index(after: result)
    }
    return result
  }

  /// Returns the source boundary and representation of one URI-value unit.
  internal func uriValueCodePoint(
    startingAt position: Index
  ) -> (endIndex: Index, isPercentEncoded: Bool) {
    if let endIndex = indexAfterPercentEncodedURIValueCodePoint(
      startingAt: position
    ) {
      return (endIndex: endIndex, isPercentEncoded: true)
    }
    return (
      endIndex: indexAfterLiteralUnicodeScalar(startingAt: position),
      isPercentEncoded: false
    )
  }

}

extension String {

  internal func escaped(
    forValueExpansionType valueExpansionType: URIValueExpansionType
  ) -> String {
    guard !isEmpty else { return self }

    let allowedCharacters = CharacterSet.allowedCharacters(
      forValueExpansionType: valueExpansionType
    )

    guard valueExpansionType.allowsPercentEncodedTriplets else {
      return infalliblyUnwrap(
        addingPercentEncoding(
          withAllowedCharacters: allowedCharacters
        ),
        explanation: """
          `String.addingPercentEncoding(withAllowedCharacters:)` returns \
          `String?` purely as a holdover from its Objective-C bridge: the \
          underlying `NSString` API treats unpaired UTF-16 surrogates in \
          the receiver as an encode-failure and reports them by returning \
          `nil`. Swift's `String` type guarantees structurally well-formed \
          Unicode at construction time — no unpaired surrogates ever — so \
          for any Swift-`String` receiver the operation cannot fail, \
          regardless of the supplied `CharacterSet`.
          """
      )
    }

    return escapedScanningURIValueCodePoints(
      allowedCharacters: allowedCharacters,
      preservesPercentEncodedTriplets: true,
      maximumDecodedCodePointCount: nil
    )
  }

  internal func escaped(
    forValueExpansionType valueExpansionType: URIValueExpansionType,
    maximumDecodedCodePointCount: Int
  ) -> String {
    guard !isEmpty else { return self }

    return escapedScanningURIValueCodePoints(
      allowedCharacters: CharacterSet.allowedCharacters(
        forValueExpansionType: valueExpansionType
      ),
      preservesPercentEncodedTriplets:
        valueExpansionType.allowsPercentEncodedTriplets,
      maximumDecodedCodePointCount: maximumDecodedCodePointCount
    )
  }

  internal func escapedPreservingPercentEncodedTriplets(
    allowedCharacters: CharacterSet
  ) -> String {
    escapedScanningURIValueCodePoints(
      allowedCharacters: allowedCharacters,
      preservesPercentEncodedTriplets: true,
      maximumDecodedCodePointCount: nil
    )
  }

  internal func escapedScanningURIValueCodePoints(
    allowedCharacters: CharacterSet,
    preservesPercentEncodedTriplets: Bool,
    maximumDecodedCodePointCount: Int?
  ) -> String {
    if let maximumDecodedCodePointCount {
      guard maximumDecodedCodePointCount > 0 else { return "" }
    }

    let unescapedAllowedCharacters = allowedCharacters.subtracting(rfc_pct_encode)
    let input = utf8
    var result: [UInt8] = []
    if maximumDecodedCodePointCount == nil {
      result.reserveCapacity(input.count)
    }

    var position = input.startIndex
    var decodedCodePointCount = 0
    while position != input.endIndex {
      if let maximumDecodedCodePointCount {
        guard
          decodedCodePointCount < maximumDecodedCodePointCount
        else {
          break
        }
      }
      decodedCodePointCount += 1

      let codePoint = input.uriValueCodePoint(startingAt: position)
      if codePoint.isPercentEncoded, preservesPercentEncodedTriplets {
        result.append(
          contentsOf: input[position..<codePoint.endIndex]
        )
      } else {
        appendEscapedURIValueBytes(
          input[position..<codePoint.endIndex],
          allowedCharacters: unescapedAllowedCharacters,
          to: &result
        )
      }
      position = codePoint.endIndex
    }

    // The scanner emits only ASCII bytes, and therefore always valid UTF-8.
    // swiftlint:disable:next optional_data_string_conversion
    return String(decoding: result, as: UTF8.self)
  }

  internal func constrained(
    toDecodedURIValueCodePointCount maximumCodePointCount: Int
  ) -> String {
    guard maximumCodePointCount > 0 else { return "" }

    let input = utf8
    var position = input.startIndex
    var decodedCodePointCount = 0
    while position != input.endIndex {
      guard decodedCodePointCount < maximumCodePointCount else { break }
      decodedCodePointCount += 1
      position = input.uriValueCodePoint(startingAt: position).endIndex
    }
    guard position != input.endIndex else { return self }
    // The boundary never divides a literal scalar or percent triplet.
    // swiftlint:disable:next optional_data_string_conversion
    return String(decoding: input[..<position], as: UTF8.self)
  }

}

internal func appendEscapedURIValueBytes(
  _ bytes: some Sequence<UInt8>,
  allowedCharacters: CharacterSet,
  to result: inout [UInt8]
) {
  for byte in bytes {
    let isAllowedASCII =
      byte < 0x80 && allowedCharacters.contains(UnicodeScalar(byte))
    if isAllowedASCII {
      result.append(byte)
      continue
    }

    result.append(0x25)
    let highNibble = byte >> 4
    let lowNibble = byte & 0x0F
    result.append(
      highNibble < 10
        ? highNibble + 0x30
        : highNibble + 0x37
    )
    result.append(
      lowNibble < 10
        ? lowNibble + 0x30
        : lowNibble + 0x37
    )
  }
}
