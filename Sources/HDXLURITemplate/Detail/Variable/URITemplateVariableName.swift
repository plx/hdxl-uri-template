import Foundation

// MARK: URITemplateVariableName

@usableFromInline
package struct URITemplateVariableName: RawRepresentable {
  
  @usableFromInline
  package typealias RawValue = String
  
  @usableFromInline
  package var rawValue: RawValue
  
  @usableFromInline
  package static let validationRegularExpression: NSRegularExpression = try! URITemplateVariableName.prepareValidationRegularExpression()
  
  @inlinable
  package init(rawValue: RawValue) {
    self.rawValue = rawValue
  }
  
}

// MARK: - Synthesized Conformances

extension URITemplateVariableName : Sendable { }
extension URITemplateVariableName : Equatable { }
extension URITemplateVariableName : Hashable { }

// MARK: URITemplateVariableName - Comparable

extension URITemplateVariableName : Comparable {
  
  @inlinable
  package static func <(
    lhs: URITemplateVariableName,
    rhs: URITemplateVariableName
  ) -> Bool {
    lhs.rawValue < rhs.rawValue
  }
  
}

// MARK: - CustomStringConvertible

extension URITemplateVariableName : CustomStringConvertible {
  
  @inlinable
  package var description: String {
    rawValue
  }
  
}

// MARK: - CustomDebugStringConvertible

extension URITemplateVariableName : CustomDebugStringConvertible {
  
  @inlinable
  package var debugDescription: String {
    "URITemplateVariableName(rawValue: \"\(rawValue)\")"
  }
  
}

// MARK: - Codable

extension URITemplateVariableName : Codable {
  
  @inlinable
  package func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }
  
  @inlinable
  package init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    let storage = try container.decode(String.self)
    guard Self.validationRegularExpression.matchesEntirety(of: storage) else {
      throw DataValidationError(
        forType: Self.self,
        problemDescription: "Decoded invalid underlying string \"\(storage)\"!"
      )
    }
    self.init(rawValue: storage)
  }
  
}

// MARK: - Validation Support

extension URITemplateVariableName {
    
  @inlinable
  package static func prepareValidationRegularExpression() throws -> NSRegularExpression {
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

// MARK: - Validatable

extension URITemplateVariableName {
  
  @inlinable
  package var isValid: Bool {
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
