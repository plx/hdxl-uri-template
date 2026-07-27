import Foundation

// -------------------------------------------------------------------------- //
// MARK: URITemplate - Definition
// -------------------------------------------------------------------------- //

/// Type representing an already-parsed, known-*valid* URI template.
///
/// The public API is minimal and immutable; it's immutable for two reasons:
///
/// 1. to make it trivial to preserve the internal state (e.g. maintain the invariants)
/// 2. to keep the internal types internal (implementation uses `newtype`-like types--making them public would be "noisy")
///
/// Despite being immutable, it is currently implemented as a struct wrapping
/// class-backed storage. The parsed source and components are immutable; the
/// storage class coordinates lazy caches for frequently-used derived values.
///
public struct URITemplate {
  
  @usableFromInline
  internal var storage: URITemplateStorage
  
  @inlinable
  internal init(storage: URITemplateStorage) {
#if HEAVY_DEBUG
    pedanticAssert(storage.isValid)
    defer { pedanticAssert(storage.isValid) }
#endif
    self.storage = storage
  }

  // ------------------------------------------------------------------------ //
  // MARK: Initialization
  // ------------------------------------------------------------------------ //
  
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

// -------------------------------------------------------------------------- //
// MARK: URITemplate - Equatable
// -------------------------------------------------------------------------- //

extension URITemplate : Sendable { }
extension URITemplate : Equatable { }
extension URITemplate : Hashable { }
extension URITemplate : Codable { }

// -------------------------------------------------------------------------- //
// MARK: - CustomStringConvertible
// -------------------------------------------------------------------------- //

extension URITemplate : CustomStringConvertible {
  
  @inlinable
  public var description: String {
    storage.description
  }
  
}


// -------------------------------------------------------------------------- //
// MARK: - CustomDebugStringConvertible
// -------------------------------------------------------------------------- //

extension URITemplate : CustomDebugStringConvertible {
  
  @inlinable
  public var debugDescription: String {
    "URITemplate(storage: \(String(reflecting: storage))) ('\(templateRepresentation)')"
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: - Validatable
// -------------------------------------------------------------------------- //

extension URITemplate {
  
  @inlinable
  public var isValid: Bool {
    storage.isValid
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: - Core API
// -------------------------------------------------------------------------- //

extension URITemplate {
  
  /// Returns the exact validated source string from which this template was
  /// parsed.
  ///
  /// The returned source is syntactically valid and reparses to an equivalent
  /// `URITemplate`.
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
