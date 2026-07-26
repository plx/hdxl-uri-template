import Foundation

extension UInt8 {

  @inlinable
  internal var isASCIIHexadecimalDigit: Bool {
    switch self {
    case 0x30...0x39, 0x41...0x46, 0x61...0x66:
      true
    default:
      false
    }
  }

}

extension String.UTF8View {

  @inlinable
  internal func indexAfterPercentEncodedTriplet(
    startingAt position: Index
  ) -> Index? {
    guard position != endIndex, self[position] == 0x25 else { return nil }

    let firstDigitPosition = index(after: position)
    guard firstDigitPosition != endIndex else { return nil }

    let secondDigitPosition = index(after: firstDigitPosition)
    guard secondDigitPosition != endIndex else { return nil }
    guard
      self[firstDigitPosition].isASCIIHexadecimalDigit,
      self[secondDigitPosition].isASCIIHexadecimalDigit
    else {
      return nil
    }

    return index(after: secondDigitPosition)
  }

}

extension String {

  @inlinable
  internal func escaped(forValueExpansionType valueExpansionType: URIValueExpansionType) -> String {
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

    return escapedPreservingPercentEncodedTriplets(
      allowedCharacters: allowedCharacters
    )
  }

  @inlinable
  internal func escapedPreservingPercentEncodedTriplets(
    allowedCharacters: CharacterSet
  ) -> String {
    let unescapedAllowedCharacters = allowedCharacters.subtracting(rfc_pct_encode)
    let input = utf8
    var result: [UInt8] = []
    result.reserveCapacity(input.count)

    var position = input.startIndex
    while position != input.endIndex {
      let byte = input[position]
      let nextPosition = input.index(after: position)

      if let positionAfterTriplet = input.indexAfterPercentEncodedTriplet(
        startingAt: position
      ) {
        result.append(contentsOf: input[position..<positionAfterTriplet])
        position = positionAfterTriplet
        continue
      }

      if byte < 0x80 && unescapedAllowedCharacters.contains(UnicodeScalar(byte)) {
        result.append(byte)
      } else {
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

      position = nextPosition
    }

    // The scanner emits only ASCII bytes, and therefore always valid UTF-8.
    // swiftlint:disable:next optional_data_string_conversion
    return String(decoding: result, as: UTF8.self)
  }

}
