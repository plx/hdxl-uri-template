import Foundation

// MARK: URITemplate

/// Type representing an already-parsed, known-*valid* URI template.
///
/// The public API is minimal and immutable; it's immutable for two reasons:
///
/// 1. to make it trivial to preserve the internal state (e.g. maintain the invariants)
/// 2. to keep the internal types internal (implementation uses `newtype`-like types--making them public would be "noisy")
///
/// Despite being immutable, it's still implemented as a struct-wrapping-a-class.
/// Using this COW-like implementation approach is also for two reasons:
///
/// 1. to have a place to cache frequently-used derived properties
/// 2. to provide value semantics for an internal-use-only mutable API
///
/// Note that (2) exists primarily for testing. I'm not opposed in principle to
/// including mutable methods on the public API, but it doesn't seem necessary.
///
public struct URITemplate {
  
  // MARK: - Stored Properties  

  @usableFromInline
  internal var storage: URITemplateStorage

  // MARK: - Initialization
  
  @inlinable
  internal init(storage: URITemplateStorage) {
    self.storage = storage
  }

  /// Public initializer, constructs a template by parsing a template string.
  ///
  /// - parameter template: A string containing a URI template.
  ///
  /// - returns: The corresponding `URITemplate`, ready for use.
  /// - throws: `ParseError` If `template` is invalid, will throw an error.
  ///
  @inlinable
  public init(parsing template: String) throws {
    do {
      self.init(
        storage: try URITemplateStorage(parsing: template)
      )
    }
    catch let underlyingError {
      throw ParseError(
        template: template,
        underlyingError: underlyingError
      )
    }
  }
  
}

// MARK: - Synthesized Conformances

extension URITemplate : Sendable { }
extension URITemplate : Equatable { }
extension URITemplate : Hashable { }
extension URITemplate : Codable { }

// MARK: - Comparable

extension URITemplate : Comparable {
  
  /// Compares two templates lexicographically by their template representations.
  ///
  /// - Parameters:
  ///   - lhs: The left-hand side template.
  ///   - rhs: The right-hand side template.
  ///
  /// - Returns: `true` if `lhs` is lexicographically less than `rhs`.
  @inlinable
  public static func <(
    lhs: URITemplate,
    rhs: URITemplate
  ) -> Bool {
    lhs.storage < rhs.storage
  }
  
}

// MARK: - CustomStringConvertible

extension URITemplate : CustomStringConvertible {

  /// The template representation string.
  @inlinable
  public var description: String {
    templateRepresentation
  }

}

// MARK: - CustomDebugStringConvertible

extension URITemplate : CustomDebugStringConvertible {

  /// A detailed debug description including storage and template representation.
  @inlinable
  public var debugDescription: String {
    "URITemplate(storage: \(String(reflecting: storage))) ('\(templateRepresentation)')"
  }

}

// MARK: - Validatable

extension URITemplate {

  /// Indicates whether the template is structurally valid.
  ///
  /// - Invariant: A successfully-parsed template is always valid.
  @inlinable
  public var isValid: Bool {
    storage.isValid
  }

}

// MARK: - Core API

extension URITemplate {
  
  /// Returns a URI template string *equivalent* to this template.
  /// In general should be identical to the template from-which it was parsed,
  /// but at present I don't guarantee that it's identical.
  @inlinable
  public var templateRepresentation: String {
    storage.templateRepresentation
  }
  
  /// The names of the variables within the template (as `String`s).
  @inlinable
  public var variableNames: Set<String> {
    storage.variableNames
  }
  
}
