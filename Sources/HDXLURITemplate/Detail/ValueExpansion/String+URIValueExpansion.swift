import Foundation

extension CharacterSet {
  @usableFromInline
  static let hexadecimalDigits: CharacterSet = .init(charactersIn: "0123456789ABCDEFabcdef")
}

extension String.UnicodeScalarView {

  @inlinable
  internal func hasPercentEscape(at position: Index) -> Bool {
    self[position] == "%"
    &&
    distance(from: position, to: endIndex) >= 3
    &&
    CharacterSet.hexadecimalDigits.contains(self[index(position, offsetBy: 1)])
    &&
    CharacterSet.hexadecimalDigits.contains(self[index(position, offsetBy: 2)])
  }

}

@usableFromInline
enum EscapedStringDecomposition {
  case escaped(String)
  case unescaped(String)
}

extension String.UnicodeScalarView {

  @inlinable
  internal var decomposedIntoEscapedAndUnescapedParts: [EscapedStringDecomposition] {
    var result: [EscapedStringDecomposition] = []
    var currentString: String = ""

    var currentPosition: Index = startIndex
    while currentPosition < endIndex {
      switch hasPercentEscape(at: currentPosition) {
      case true:
        if !currentString.isEmpty {
          result.append(.unescaped(currentString))
          currentString = ""
        }

        result.append(
          .escaped(
            String(self[currentPosition..<index(currentPosition, offsetBy: 3)])
          )
        )
        currentPosition = index(currentPosition, offsetBy: 3)
      case false:
        currentString.append(String(self[currentPosition]))
        currentPosition = index(after: currentPosition)
      }
    }
    if !currentString.isEmpty {
      result.append(.unescaped(currentString))
      currentString = ""
    }
    return result

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

    let unescapedAllowedCharacters = allowedCharacters.subtracting(rfc_pct_encode)
    let decomposition = unicodeScalars.decomposedIntoEscapedAndUnescapedParts
    var chunks: [String] = []
    chunks.reserveCapacity(decomposition.count)
    for decompositionElement in decomposition {
      switch decompositionElement {
      case .escaped(let percentEscapedString):
        chunks.append(percentEscapedString)
      case .unescaped(let unescapedString):
        let escapedString = infalliblyUnwrap(
          unescapedString.addingPercentEncoding(
            withAllowedCharacters: unescapedAllowedCharacters
          ),
          explanation: """
            `unescapedString` was carved out of `self` (a Swift `String`) by \
            `decomposedIntoEscapedAndUnescapedParts`, which slices on \
            `UnicodeScalarView` indices. Slicing a Swift `String` always \
            yields well-formed Unicode — no unpaired UTF-16 surrogates — and \
            `addingPercentEncoding(withAllowedCharacters:)` only returns \
            `nil` to surface that exact Objective-C-bridge failure mode. \
            So the operation cannot fail for any chunk produced here, \
            regardless of the supplied `CharacterSet`.
            """
        )
        chunks.append(escapedString)
      }
    }

    return chunks.joined()
  }

}
