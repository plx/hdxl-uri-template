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

    // RFC 6570 Section 2.4.2: Percent-encoded triplets in values should be treated
    // as literals. For reserved/fragment expansion, preserve them; for other
    // expansions, re-encode them (the % becomes %25).
    let decomposition = unicodeScalars.decomposedIntoEscapedAndUnescapedParts
    var chunks: [String] = []
    chunks.reserveCapacity(decomposition.count)

    let allowedCharacters = CharacterSet.allowedCharacters(forValueExpansionType: valueExpansionType)

    for decompositionElement in decomposition {
      switch decompositionElement {
      case .escaped(let percentEscapedString):
        // For reserved and fragment expansion, preserve existing percent-encoded triplets
        // For other expansion types, re-encode the triplet (% becomes %25)
        if valueExpansionType == .reserved || valueExpansionType == .fragment {
          chunks.append(percentEscapedString)
        } else {
          // Re-encode the already-encoded triplet by encoding each character
          guard
            let reEncodedString = percentEscapedString.addingPercentEncoding(
              withAllowedCharacters: allowedCharacters
            )
          else {
            return nil
          }
          chunks.append(reEncodedString)
        }
      case .unescaped(let unescapedString):
        guard
          let escapedString = unescapedString.addingPercentEncoding(
            withAllowedCharacters: allowedCharacters
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
