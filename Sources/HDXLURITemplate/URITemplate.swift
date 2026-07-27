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
/// - Important: This package's initial contract is Swift-only. Code that used
///   the removed `HDXLURITemplate` wrapper should migrate to
///   ``init(parsing:)``, ``templateRepresentation``, ``variableNames``, and
///   the native evaluation APIs. Archives of the removed wrapper are not a
///   supported persistence format.
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
    } catch let underlyingError {
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

extension URITemplate: Sendable {}
extension URITemplate: Equatable {}
extension URITemplate: Hashable {}

// -------------------------------------------------------------------------- //
// MARK: URITemplate - Codable
// -------------------------------------------------------------------------- //

extension URITemplate: Codable {

  /// Encodes this template as its exact validated URI-template source string.
  ///
  /// The semantic source string is the complete public persistence format.
  /// Private parser storage and compiled caches are never part of the encoded
  /// representation.
  @inlinable
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(templateRepresentation)
  }

  /// Decodes and validates one URI-template source string.
  ///
  /// Decoding always reparses the source through ``init(parsing:)`` so it
  /// cannot construct state that the public parser would reject. Historical
  /// payloads synthesized from private parser storage are unsupported.
  @inlinable
  public init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()
    let template = try container.decode(String.self)
    do {
      try self.init(parsing: template)
    } catch {
      throw DecodingError.dataCorrupted(
        DecodingError.Context(
          codingPath: container.codingPath,
          debugDescription: "Invalid URI template string.",
          underlyingError: error
        )
      )
    }
  }

}

// -------------------------------------------------------------------------- //
// MARK: - CustomStringConvertible
// -------------------------------------------------------------------------- //

extension URITemplate: CustomStringConvertible {

  @inlinable
  public var description: String {
    storage.description
  }

}

// -------------------------------------------------------------------------- //
// MARK: - CustomDebugStringConvertible
// -------------------------------------------------------------------------- //

extension URITemplate: CustomDebugStringConvertible {

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
