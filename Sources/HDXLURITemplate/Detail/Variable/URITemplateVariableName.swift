import Foundation

// -------------------------------------------------------------------------- //
// MARK: URITemplateVariableName - Definition
// -------------------------------------------------------------------------- //

@usableFromInline
internal struct URITemplateVariableName {
  
  @usableFromInline
  internal typealias Storage = String
  
  @usableFromInline
  internal var storage: Storage
  
  @usableFromInline
  internal static let validationRegularExpression: NSRegularExpression = try! URITemplateVariableName.prepareValidationRegularExpression()
  
  @inlinable
  internal init(storage: Storage) {
#if HEAVY_DEBUG
    pedanticAssert(!storage.isEmpty)
    pedanticAssert(Self.validationRegularExpression.matchesEntirety(of: storage))
    defer { pedanticAssert(isValid) }
#endif
    self.storage = storage
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: - Synthesized Conformances
// -------------------------------------------------------------------------- //

extension URITemplateVariableName : Sendable { }
extension URITemplateVariableName : Equatable { }
extension URITemplateVariableName : Hashable { }

// -------------------------------------------------------------------------- //
// MARK: URITemplateVariableName - Comparable
// -------------------------------------------------------------------------- //

extension URITemplateVariableName : Comparable {
  
  @inlinable
  internal static func <(
    lhs: URITemplateVariableName,
    rhs: URITemplateVariableName
  ) -> Bool {
#if HEAVY_DEBUG
    pedanticAssert(lhs.isValid)
    pedanticAssert(rhs.isValid)
#endif
    // /////////////////////////////////////////////////////////////////////////
    return lhs.storage < rhs.storage
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: - CustomStringConvertible
// -------------------------------------------------------------------------- //

extension URITemplateVariableName : CustomStringConvertible {
  
  @inlinable
  internal var description: String {
    storage
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: - CustomDebugStringConvertible
// -------------------------------------------------------------------------- //

extension URITemplateVariableName : CustomDebugStringConvertible {
  
  @inlinable
  internal var debugDescription: String {
    "URITemplateVariableName(storage: \"\(storage)\")"
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: URITemplateVariableName - Codable
// -------------------------------------------------------------------------- //

extension URITemplateVariableName : Codable {
  
  @inlinable
  func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(storage)
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
// MARK: URITemplateVariableName - Validation Support
// -------------------------------------------------------------------------- //

extension URITemplateVariableName {
  
  @inlinable
  static func prepareValidationRegularExpression() throws -> NSRegularExpression {
    // NOTE: `varname       =  varchar *( ["."] varchar )`
    // *appears* nonsensical and is *probably* a mistake...
    // ...IMHO it *should* be `varname = varchar *( ["."] varname )`.
    //
    // As such, I've tentatively implemented it as:
    //
    // - a non-empty varchar
    // - optionally followed by one or more sequences like "`.`, non-empty varchar"
    //
    // here's the original RFC text:
    /*

     variable-list =  varspec *( "," varspec )
     varspec       =  varname [ modifier-level4 ]
     varname       =  varchar *( ["."] varchar )
     varchar       =  ALPHA / DIGIT / "_" / pct-encoded
     
     A varname MAY contain one or more pct-encoded triplets.  These
     triplets are considered an essential part of the variable name and
     are not decoded during processing.  A varname containing pct-encoded
     characters is not the same variable as a varname with those same
     characters decoded.  Applications that provide URI Templates are
     expected to be consistent in their use of pct-encoding within
     variable names.
     */
    return try NSRegularExpression(
      pattern:
      """
      (?:
        %[[0-9][a-f][A-F]][[0-9][a-f][A-F]]
        |
        [_[a-z][A-Z][0-9]]
      )+
      (?:
        \\.
        (?:
          %[[0-9][a-f][A-F]][[0-9][a-f][A-F]]
          |
          [_[a-z][A-Z][0-9]]
        )+
      )*
      """,
      options: .allowCommentsAndWhitespace
    )
  }
    
}

// -------------------------------------------------------------------------- //
// MARK: - Validatable
// -------------------------------------------------------------------------- //

extension URITemplateVariableName {
  
  @inlinable
  internal var isValid: Bool {
    guard
      !storage.isEmpty,
      URITemplateVariableName.validationRegularExpression.matchesEntirety(
        of: storage
      )
    else {
      return false
    }
    return true
  }
  
}
