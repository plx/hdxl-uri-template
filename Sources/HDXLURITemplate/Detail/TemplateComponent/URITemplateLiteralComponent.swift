import Foundation

// -------------------------------------------------------------------------- //
// MARK: URITemplateLiteralComponent - Definition
// -------------------------------------------------------------------------- //

@usableFromInline
internal struct URITemplateLiteralComponent: RawRepresentable {
  
  @usableFromInline
  internal typealias Storage = String
  
  @usableFromInline
  internal var rawValue: Storage
  
  @usableFromInline
  internal static let validationRegularExpression: NSRegularExpression = try! URITemplateLiteralComponent.prepareValidationRegularExpression()
  
  @inlinable
  internal init(rawValue: Storage) {
#if HEAVY_DEBUG
    pedanticAssert(!storage.isEmpty)
    pedanticAssert(Self.validationRegularExpression.matchesEntirety(of: storage))
    defer { pedanticAssert(isValid) }
#endif
    self.rawValue = rawValue
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: - Synthesized Conformances
// -------------------------------------------------------------------------- //

extension URITemplateLiteralComponent : Sendable { }
extension URITemplateLiteralComponent : Equatable { }
extension URITemplateLiteralComponent : Hashable { }

// -------------------------------------------------------------------------- //
// MARK: - Comparable
// -------------------------------------------------------------------------- //

extension URITemplateLiteralComponent : Comparable {
  
  @inlinable
  internal static func <(
    lhs: URITemplateLiteralComponent,
    rhs: URITemplateLiteralComponent
  ) -> Bool {
#if HEAVY_DEBUG
    pedanticAssert(lhs.isValid)
    pedanticAssert(rhs.isValid)
#endif
    return lhs.rawValue < rhs.rawValue
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: - CustomStringConvertible
// -------------------------------------------------------------------------- //

extension URITemplateLiteralComponent : CustomStringConvertible {
  
  @usableFromInline
  internal var description: String { rawValue }
  
}

// -------------------------------------------------------------------------- //
// MARK: - CustomDebugStringConvertible
// -------------------------------------------------------------------------- //

extension URITemplateLiteralComponent : CustomDebugStringConvertible {
  
  @usableFromInline
  internal var debugDescription: String {
    "URITemplateLiteralComponent(storage: \"\(rawValue)\")"
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: - Codable
// -------------------------------------------------------------------------- //

extension URITemplateLiteralComponent : Codable {
  
  @inlinable
  func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }
  
  @inlinable
  init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    let rawValue = try container.decode(String.self)
    guard Self.validationRegularExpression.matchesEntirety(of: rawValue) else {
      throw DataValidationError(
        forType: Self.self,
        problemDescription: "Decoded invalid underlying string \"\(rawValue)\"!"
      )
    }
    self.init(rawValue: rawValue)
  }

}

// -------------------------------------------------------------------------- //
// MARK: URITemplateLiteralComponent - Validation Support
// -------------------------------------------------------------------------- //

extension URITemplateLiteralComponent {
  
  @inlinable
  internal static func prepareValidationRegularExpression() throws -> NSRegularExpression {
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

// -------------------------------------------------------------------------- //
// MARK: - Validatable
// -------------------------------------------------------------------------- //

extension URITemplateLiteralComponent {
  
  @inlinable
  internal var isValid: Bool {
    !rawValue.isEmpty
    &&
    URITemplateLiteralComponent.validationRegularExpression.matchesEntirety(
      of: rawValue
    )
  }
  
}
