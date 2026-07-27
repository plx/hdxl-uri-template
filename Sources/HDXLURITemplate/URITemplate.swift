import Foundation

// -------------------------------------------------------------------------- //
// MARK: URITemplate - Definition
// -------------------------------------------------------------------------- //

/// An immutable, parsed, and validated RFC 6570 URI template.
///
/// A template preserves its exact accepted source and can be reused safely
/// for metadata access and expansion. Its value semantics, equality, hashing,
/// `Sendable` conformance, and semantic string-based `Codable` representation
/// are public contracts; its parsed representation is not.
///
/// - Important: This package's initial contract is Swift-only. Code that used
///   the removed `HDXLURITemplate` wrapper should migrate to
///   ``init(parsing:)``, ``templateRepresentation``, ``variableNames``, and
///   the native evaluation APIs. Archives of the removed wrapper are not a
///   supported persistence format.
///
public struct URITemplate {

  internal let storage: URITemplateStorage

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

  /// Constructs a template by parsing and validating `template`.
  ///
  /// - parameter template: A string containing a URI template.
  ///
  /// - Returns: The corresponding `URITemplate`, ready for use.
  /// - Throws: ``ParseError`` when `template` is invalid.
  ///
  public init(parsing template: String) throws {
    self.init(
      storage: try Self.parsedStorage(from: template)
    )
  }

  internal static func parsedStorage(
    from template: String
  ) throws -> URITemplateStorage {
    do {
      return try URITemplateStorage(parsing: template)
    } catch let diagnostic as URITemplateSourceDiagnostic {
      throw ParseError(
        template: template,
        kind: diagnostic.kind,
        sourceRange: template.utf8OffsetRange(
          for: diagnostic.sourceRange
        )
      )
    } catch {
      throw ParseError(
        template: template,
        kind: .other,
        sourceRange: 0..<template.utf8.count
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
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(templateRepresentation)
  }

  /// Decodes and validates one URI-template source string.
  ///
  /// Decoding always reparses the source through ``init(parsing:)`` so it
  /// cannot construct state that the public parser would reject. Historical
  /// payloads synthesized from private parser storage are unsupported.
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

  /// A representation of this template suitable for diagnostic display.
  public var description: String {
    storage.description
  }

}

// -------------------------------------------------------------------------- //
// MARK: - CustomDebugStringConvertible
// -------------------------------------------------------------------------- //

extension URITemplate: CustomDebugStringConvertible {

  /// A detailed representation of this template suitable for debugging.
  public var debugDescription: String {
    "URITemplate(storage: \(String(reflecting: storage))) ('\(templateRepresentation)')"
  }

}

// -------------------------------------------------------------------------- //
// MARK: - Validatable
// -------------------------------------------------------------------------- //

extension URITemplate {

  /// Whether the template's internal state satisfies all invariants.
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
  public var templateRepresentation: String {
    storage.templateRepresentation
  }

  /// The names of the variables within the template (as `String`s).
  public var variableNames: Set<String> {
    storage.variableNames
  }

}
