import Foundation

// RFC-derived Code Components in this file are attributed in
// THIRD_PARTY_NOTICES.md.

// -------------------------------------------------------------------------- //
// MARK: URITemplateVariableName - Definition
// -------------------------------------------------------------------------- //

@usableFromInline
internal struct URITemplateVariableName: RawRepresentable {
  
  @usableFromInline
  internal typealias RawValue = String
  
  @usableFromInline
  internal var rawValue: RawValue
  
  @usableFromInline
  internal static let validationRegularExpression: NSRegularExpression = try! URITemplateVariableName.prepareValidationRegularExpression()
  
  @inlinable
  internal init(rawValue: RawValue) {
#if HEAVY_DEBUG
    pedanticAssert(!rawValue.isEmpty)
    pedanticAssert(Self.validationRegularExpression.matchesEntirety(of: rawValue))
    defer { pedanticAssert(isValid) }
#endif
    self.rawValue = rawValue
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
    return lhs.rawValue < rhs.rawValue
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: - CustomStringConvertible
// -------------------------------------------------------------------------- //

extension URITemplateVariableName : CustomStringConvertible {
  
  @inlinable
  internal var description: String {
    rawValue
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: - CustomDebugStringConvertible
// -------------------------------------------------------------------------- //

extension URITemplateVariableName : CustomDebugStringConvertible {
  
  @inlinable
  internal var debugDescription: String {
    "URITemplateVariableName(rawValue: \"\(rawValue)\")"
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: - Validation Support
// -------------------------------------------------------------------------- //

extension URITemplateVariableName {
    
  @inlinable
  static func prepareValidationRegularExpression() throws -> NSRegularExpression {
    // RFC 6570 section 2.3 defines a nonempty `varchar` sequence followed by
    // zero or more dot-separated `varchar` sequences. Percent-encoded
    // triplets are lexical name content and are not decoded here.
    /*
     variable-list =  varspec *( "," varspec )
     varspec       =  varname [ modifier-level4 ]
     varname       =  varchar *( ["."] varchar )
     varchar       =  ALPHA / DIGIT / "_" / pct-encoded
     */
    
//    let singleVariableMention: String =
//      """
//      (?:
//        %[[0-9][a-f][A-F]][[0-9][a-f][A-F]]
//        |
//        [_[a-z][A-Z][0-9]]
//      )+
//      (?:
//        \\.
//        (?:
//          %[[0-9][a-f][A-F]][[0-9][a-f][A-F]]
//          |
//          [_[a-z][A-Z][0-9]]
//        )+
//      )*
//      """
//    
//    let completePattern: String =
//      """
//      \(singleVariableMention)
//      (?:
//        ,
//        \(singleVariableMention)
//      )*
//      """
//
    return try NSRegularExpression(
//      pattern: completePattern,
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
      !rawValue.isEmpty,
      URITemplateVariableName.validationRegularExpression.matchesEntirety(
        of: rawValue
      )
    else {
      return false
    }
    return true
  }
  
}
