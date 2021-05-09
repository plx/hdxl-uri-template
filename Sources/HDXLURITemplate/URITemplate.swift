//
//  URITemplate.swift
//

import Foundation
import HDXLCommonUtilities

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
/// Despite being immutable, it's still implemented as a struct-wrapping-a-class.
/// Using this COW-like implementation approach is also for two reasons:
///
/// 1. to have a place to cache frequently-used derived properties
/// 2. to provide value semantics for an internal-use-only mutable API
///
/// Note that (2) exists primarily for testing. I'm not opposed in principle to
/// including mutable methods on the public API, but it doesn't seem necessary.
///
@frozen
public struct URITemplate {
  
  @usableFromInline
  internal var storage: URITemplateStorage
  
  @inlinable
  internal init(storage: URITemplateStorage) {
    // /////////////////////////////////////////////////////////////////////////
    pedantic_assert(storage.isValid)
    defer { pedantic_assert(storage.isValid) }
    // /////////////////////////////////////////////////////////////////////////
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
// MARK: URITemplate - Core API
// -------------------------------------------------------------------------- //

public extension URITemplate {
  
  /// Returns a URI template string *equivalent* to this template.
  /// In general should be identical to the template from-which it was parsed,
  /// but at present I don't guarantee that it's identical.
  @inlinable
  var templateRepresentation: String {
    get {
      return self.storage.templateRepresentation
    }
  }
  
  /// The names of the variables within the template (as `String`s).
  @inlinable
  var variableNames: Set<String> {
    get {
      return self.storage.variableNames
    }
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: URITemplate - Validatable
// -------------------------------------------------------------------------- //

extension URITemplate : Validatable {
  
  @inlinable
  public var isValid: Bool {
    get {
      return self.storage.isValid
    }
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: URITemplate - Equatable
// -------------------------------------------------------------------------- //

extension URITemplate : Equatable {
  
  @inlinable
  public static func ==(
    lhs: URITemplate,
    rhs: URITemplate) -> Bool {
    return lhs.storage == rhs.storage
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: URITemplate - Comparable
// -------------------------------------------------------------------------- //

extension URITemplate : Comparable {
  
  @inlinable
  public static func <(
    lhs: URITemplate,
    rhs: URITemplate) -> Bool {
    return lhs.storage < rhs.storage
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: URITemplate - Hashable
// -------------------------------------------------------------------------- //

extension URITemplate : Hashable {
  
  @inlinable
  public func hash(into hasher: inout Hasher) {
    self.storage.hash(into: &hasher)
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: URITemplate - CustomStringConvertible
// -------------------------------------------------------------------------- //

extension URITemplate : CustomStringConvertible {
  
  @inlinable
  public var description: String {
    get {
      return self.storage.description
    }
  }
  
}


// -------------------------------------------------------------------------- //
// MARK: URITemplate - CustomDebugStringConvertible
// -------------------------------------------------------------------------- //

extension URITemplate : CustomDebugStringConvertible {
  
  @inlinable
  public var debugDescription: String {
    get {
      return "URITemplate(storage: \(self.storage.debugDescription)) ('\(self.templateRepresentation)')"
    }
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: URITemplate - Codable
// -------------------------------------------------------------------------- //

extension URITemplate : Codable {
  
  // synthesized ok
  
}
