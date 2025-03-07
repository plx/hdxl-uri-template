//
//  URIValueExpansionModifier+Parsing.swift
//

import Foundation

internal extension URIValueExpansionModifier {
  
  @usableFromInline
  enum ParseError : Error {
    case invalidPrefixSpecification(String)
  }
  
  @inlinable
  init(parsing string: inout String) throws {
    if string.hasSuffix("*") {
      self = .explode
      string.conditionallyRemove(suffix: "*")
    } else if let colonIndex = string.lastIndex(of: ":") {
      guard (2...5).contains(
        string.distance(
          from: colonIndex,
          to: string.endIndex
        )
      ),
      let prefixLength = Int(
        string[
          string.index(after: colonIndex)
            ..<
          string.endIndex
        ]
      ),
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
