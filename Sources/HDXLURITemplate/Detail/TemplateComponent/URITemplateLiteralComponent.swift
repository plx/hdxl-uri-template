//
//  URITemplateLiteralComponent.swift
//

import Foundation
import HDXLCommonUtilities

// -------------------------------------------------------------------------- //
// MARK: URITemplateLiteralComponent - Definition
// -------------------------------------------------------------------------- //

@frozen
@usableFromInline
internal struct URITemplateLiteralComponent {
  
  @usableFromInline
  internal typealias Storage = String
  
  @usableFromInline
  internal var storage: Storage
  
  @usableFromInline
  internal static let validationRegularExpression: NSRegularExpression = try! URITemplateLiteralComponent.prepareValidationRegularExpression()
  
  @inlinable
  internal init(storage: Storage) {
    // /////////////////////////////////////////////////////////////////////////
    pedantic_assert(!storage.isEmpty)
    pedantic_assert(Self.validationRegularExpression.matchesEntirety(of: storage))
    defer { pedantic_assert(self.isValid) }
    // /////////////////////////////////////////////////////////////////////////
    self.storage = storage
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: URITemplateLiteralComponent - Validatable
// -------------------------------------------------------------------------- //

extension URITemplateLiteralComponent : Validatable {
  
  @inlinable
  internal var isValid: Bool {
    get {
      guard
        !self.storage.isEmpty,
        URITemplateLiteralComponent.validationRegularExpression.matchesEntirety(
          of: self.storage
        ) else {
          return false
      }
      return true
    }
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: URITemplateLiteralComponent - Equatable
// -------------------------------------------------------------------------- //

extension URITemplateLiteralComponent : Equatable {
  
  @inlinable
  internal static func ==(
    lhs: URITemplateLiteralComponent,
    rhs: URITemplateLiteralComponent) -> Bool {
    // /////////////////////////////////////////////////////////////////////////
    pedantic_assert(lhs.isValid)
    pedantic_assert(rhs.isValid)
    // /////////////////////////////////////////////////////////////////////////
    return lhs.storage == rhs.storage
  }

  @inlinable
  internal static func !=(
    lhs: URITemplateLiteralComponent,
    rhs: URITemplateLiteralComponent) -> Bool {
    // /////////////////////////////////////////////////////////////////////////
    pedantic_assert(lhs.isValid)
    pedantic_assert(rhs.isValid)
    // /////////////////////////////////////////////////////////////////////////
    return lhs.storage != rhs.storage
  }

}

// -------------------------------------------------------------------------- //
// MARK: URITemplateLiteralComponent - Comparable
// -------------------------------------------------------------------------- //

extension URITemplateLiteralComponent : Comparable {
  
  @inlinable
  internal static func <(
    lhs: URITemplateLiteralComponent,
    rhs: URITemplateLiteralComponent) -> Bool {
    // /////////////////////////////////////////////////////////////////////////
    pedantic_assert(lhs.isValid)
    pedantic_assert(rhs.isValid)
    // /////////////////////////////////////////////////////////////////////////
    return lhs.storage < rhs.storage
  }
  
  @inlinable
  internal static func >(
    lhs: URITemplateLiteralComponent,
    rhs: URITemplateLiteralComponent) -> Bool {
    // /////////////////////////////////////////////////////////////////////////
    pedantic_assert(lhs.isValid)
    pedantic_assert(rhs.isValid)
    // /////////////////////////////////////////////////////////////////////////
    return lhs.storage > rhs.storage
  }

  @inlinable
  internal static func <=(
    lhs: URITemplateLiteralComponent,
    rhs: URITemplateLiteralComponent) -> Bool {
    // /////////////////////////////////////////////////////////////////////////
    pedantic_assert(lhs.isValid)
    pedantic_assert(rhs.isValid)
    // /////////////////////////////////////////////////////////////////////////
    return lhs.storage <= rhs.storage
  }
  
  @inlinable
  internal static func >=(
    lhs: URITemplateLiteralComponent,
    rhs: URITemplateLiteralComponent) -> Bool {
    // /////////////////////////////////////////////////////////////////////////
    pedantic_assert(lhs.isValid)
    pedantic_assert(rhs.isValid)
    // /////////////////////////////////////////////////////////////////////////
    return lhs.storage >= rhs.storage
  }

}

// -------------------------------------------------------------------------- //
// MARK: URITemplateLiteralComponent - Hashable
// -------------------------------------------------------------------------- //

extension URITemplateLiteralComponent : Hashable {
  
  @inlinable
  internal func hash(into hasher: inout Hasher) {
    self.storage.hash(into: &hasher)
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: URITemplateLiteralComponent - CustomStringConvertible
// -------------------------------------------------------------------------- //

extension URITemplateLiteralComponent : CustomStringConvertible {
  
  @inlinable
  internal var description: String {
    get {
      return self.storage
    }
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: URITemplateLiteralComponent - CustomDebugStringConvertible
// -------------------------------------------------------------------------- //

extension URITemplateLiteralComponent : CustomDebugStringConvertible {
  
  @inlinable
  internal var debugDescription: String {
    get {
      return "URITemplateLiteralComponent(storage: \"\(self.storage)\")"
    }
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: URITemplateLiteralComponent - Codable
// -------------------------------------------------------------------------- //

extension URITemplateLiteralComponent : Codable {
  
  @inlinable
  func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(self.storage)
  }
  
  @inlinable
  init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    let storage = try container.decode(String.self)
    guard Self.validationRegularExpression.matchesEntirety(of: storage) else {
      throw DataValidationError(
        forType: Self.self,
        problemDescription: "Decoded invalid underlying string \"\(storage)\"!"
      )
    }
    self.init(storage: storage)
  }

}

// -------------------------------------------------------------------------- //
// MARK: URITemplateLiteralComponent - Validation Support
// -------------------------------------------------------------------------- //

internal extension URITemplateLiteralComponent {
  
  @inlinable
  static func prepareValidationRegularExpression() throws -> NSRegularExpression {
    /*
     The characters outside of expressions in a URI Template string are
     intended to be copied literally to the URI reference if the character
     is allowed in a URI (reserved / unreserved / pct-encoded) or, if not
     allowed, copied to the URI reference as the sequence of pct-encoded
     triplets corresponding to that character's encoding in UTF-8
     [RFC3629].
     
     literals      =  %x21 / %x23-24 / %x26 / %x28-3B / %x3D / %x3F-5B
     /  %x5D / %x5F / %x61-7A / %x7E / ucschar / iprivate
     /  pct-encoded
     ; any Unicode character except: CTL, SP,
     ;  DQUOTE, "'", "%" (aside from pct-encoded),
     ;  "<", ">", "\", "^", "`", "{", "|", "}"
     */
    return try NSRegularExpression(
      pattern:
      """
      (?:
        %[[0-9][a-f][A-F]][[0-9][a-f][A-F]]
        |
        [
          \\u0021
          \\u0023
          \\u0024
          \\u0026
          \\u003D
          \\u005D
          \\u005F
          \\u0073
        ]
        |
        [
          [\\u0028-\\u003B]
          [\\u003F-\\u005B]
          [\\u0061-\\u007A]
          [\\u00A0-\\uD7FF]
          [\\uF900-\\uFDCF]
          [\\uFDF0-\\uFFEF]
          [\\U00010000-\\U0001FFFD]
          [\\U00020000-\\U0002FFFD]
          [\\U00030000-\\U0003FFFD]
          [\\U00040000-\\U0004FFFD]
          [\\U00050000-\\U0005FFFD]
          [\\U00060000-\\U0006FFFD]
          [\\U00070000-\\U0007FFFD]
          [\\U00080000-\\U0008FFFD]
          [\\U00090000-\\U0009FFFD]
          [\\U000A0000-\\U000AFFFD]
          [\\U000B0000-\\U000BFFFD]
          [\\U000C0000-\\U000CFFFD]
          [\\U000D0000-\\U000DFFFD]
          [\\U000E1000-\\U000EFFFD]
          [\\U0000E000-\\U0000F8FF]
          [\\U000F0000-\\U000FFFFD]
          [\\U00100000-\\U0010FFFD]
        ]
      )+
      """,
      options: .allowCommentsAndWhitespace
    )
  }

}

