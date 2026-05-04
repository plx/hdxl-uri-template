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
  internal func escaped(forValueExpansionType valueExpansionType: URIValueExpansionType) -> String? {
    guard !isEmpty else { return self }

    let allowedCharacters = CharacterSet.allowedCharacters(
      forValueExpansionType: valueExpansionType
    )

    guard valueExpansionType.allowsPercentEncodedTriplets else {
      return addingPercentEncoding(
        withAllowedCharacters: allowedCharacters
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
        guard
          let escapedString = unescapedString.addingPercentEncoding(
            withAllowedCharacters: unescapedAllowedCharacters
          )
        else {
          return nil
        }
        chunks.append(escapedString)
      }
    }

    return chunks.joined()
  }

}
