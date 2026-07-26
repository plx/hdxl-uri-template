import Foundation

extension URIValueExpansionModifier {
  
  @usableFromInline
  internal enum ParseError : Error {
    case invalidPrefixSpecification(String)
  }
  
  @inlinable
  internal init(parsing string: inout String) throws {
    if string.hasSuffix("*") {
      self = .explode
      string.conditionallyRemove(suffix: "*")
    } else if let colonIndex = string.lastIndex(of: ":") {
      let prefixSpecification = string[
        string.index(after: colonIndex)
          ..<
        string.endIndex
      ]
      let prefixBytes = prefixSpecification.utf8
      guard
        (1...4).contains(prefixBytes.count),
        let firstByte = prefixBytes.first,
        (0x31...0x39).contains(firstByte),
        prefixBytes.dropFirst().allSatisfy({
          (0x30...0x39).contains($0)
        }),
        let prefixLength = Int(prefixSpecification),
        Self.rangeOfValidPrefixCodePointCounts.contains(prefixLength) else {
        throw ParseError.invalidPrefixSpecification(
          String(
            string[
              colonIndex
                ..<
                string.endIndex
            ]
          )
        )
      }
      self = .prefix(prefixLength)
      string.removeSubrange(
        colonIndex
          ..<
        string.endIndex
      )
    } else {
      self = .unmodified
      // no need to update the string
    }
  }
  
}
