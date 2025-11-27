import Foundation
import os.lock

// MARK: URITemplateStorage

/// Internal storage class for `URITemplate`, holding parsed components and cached derived properties.
///
/// This class provides COW-style semantics for `URITemplate` while caching
/// frequently-accessed derived properties like template representation and variable names.
@usableFromInline
internal final class URITemplateStorage {

  // MARK: - Fields

  /// The parsed template components (literals and expressions).
  @usableFromInline
  internal var components: [URITemplateComponent] {
    didSet {
      guard components != oldValue else {
        return
      }
      resetCachedDerivedProperties()
    }
  }
  
  /// Used to coordinate access to cached fields, which is necessary b/c they may be mutated w/out exclusive ownership.
  ///
  /// For `components` we can assume it's only ever mutated by an exclusive owner, b/c this class is storage for
  /// a struct implementing the standard COW-style semantics.
  ///
  /// For the cached properties, however, these are getting created-and-cached via (non-mutating) getters on the struct,
  /// which means they're not *necessarily* going to have exclusive ownership, which introduces the risk for problems
  /// (and does so *even though* the values-to-be-cached should be identical, given what we said about `components`).
  ///
  /// As such, we use this lock to protect the cached fields during (a) reads and (b) updates.
  /// TODO: see how it'd look to setup a cached-fields struct, migrate it into the struct, and keep all the cached state together.
  @usableFromInline
  internal var cachedFieldLock: OSAllocatedUnfairLock<Void>
  
  // MARK: `init`

  /// Creates an empty template storage.
  @inlinable
  internal convenience init() {
    self.init(
      components: []
    )
  }

  /// Creates storage with a single component.
  ///
  /// - Parameter component: The single template component.
  @inlinable
  internal convenience init(component: URITemplateComponent) {
    self.init(
      components: [component]
    )
  }

  /// Creates storage with the given components.
  ///
  /// - Parameter components: The template components.
  @inlinable
  internal required init(components: [URITemplateComponent]) {
    self.components = components
    self.cachedFieldLock = OSAllocatedUnfairLock()
  }

  /// Creates storage by parsing a template string.
  ///
  /// - Parameter template: The template string to parse.
  ///
  /// - Throws: An error if parsing fails.
  @inlinable
  internal convenience init(parsing template: String) throws {
    if template.isEmpty {
      self.init()
    } else {
      self.init(
        components: try template.parseIntoURITemplateComponents()
      )
    }
  }
    
  /// Resets all cached derived properties.
  @inlinable
  func resetCachedDerivedProperties() {
    cachedFieldLock.precondition(.notOwner) // deadlock detection/prevention
    cachedFieldLock.withLock {
      _templateRepresentation = nil
      _templateVariables = nil
      _templateVariableNames = nil
      _templateRepresentation = nil
    }
  }
  
  // MARK: `templateRepresentation`

  /// Cached template representation string.
  @usableFromInline
  internal var _templateRepresentation: String? = nil

  /// The reconstructed template string representation.
  @inlinable
  internal var templateRepresentation: String {
    cachedFieldLock.precondition(.notOwner) // deadlock detection/prevention
    return cachedFieldLock.withLock {
      _withLockTemplateRepresentation
    }
  }

  /// Thread-safe accessor for template representation (requires lock ownership).
  @inlinable
  internal var _withLockTemplateRepresentation: String {
    cachedFieldLock.precondition(.owner) // deadlock detection/prevention
    return _templateRepresentation.obtainAssuredValue(
      guaranteedBy: components
        .lazy
        .map {
          (component: URITemplateComponent) -> String
          in
          component.templateRepresentation
        }.joined(separator: "")
    )
  }

  // MARK: `templateVariables`

  /// Cached set of template variables.
  @usableFromInline
  internal var _templateVariables: Set<URITemplateVariable>? = nil

  /// The set of all variables in the template.
  @inlinable
  internal var templateVariables: Set<URITemplateVariable> {
    cachedFieldLock.precondition(.notOwner)
    return cachedFieldLock.withLock {
      _withLockTemplateVariables
    }
  }

  /// Thread-safe accessor for template variables (requires lock ownership).
  @inlinable
  internal var _withLockTemplateVariables: Set<URITemplateVariable> {
    cachedFieldLock.precondition(.owner)
    return _templateVariables.obtainAssuredValue(
      guaranteedBy: _withLockPrepareTemplateVariables()
    )
  }

  /// Collects all variables from components (requires lock ownership).
  @inlinable
  func _withLockPrepareTemplateVariables() -> Set<URITemplateVariable> {
    cachedFieldLock.precondition(.owner)
    var result: Set<URITemplateVariable> = []
    for component in components {
      component.injectTemplateVariables(into: &result)
    }
    return result
  }
  
  // MARK: `templateVariableNames`

  /// Cached set of variable names as `URITemplateVariableName`.
  @usableFromInline
  internal var _templateVariableNames: Set<URITemplateVariableName>? = nil

  /// The set of variable names as `URITemplateVariableName` objects.
  @inlinable
  internal var templateVariablesNames: Set<URITemplateVariableName> {
    _templateVariableNames.obtainAssuredValue(
      guaranteedBy: Set(
        _withLockTemplateVariables
          .lazy
          .map { $0.variableName }
      )
    )
  }
  
  // MARK: `variableNames`

  /// Cached set of variable names as strings.
  @usableFromInline
  internal var _variableNames: Set<String>? = nil

  /// The set of variable names as plain strings.
  @inlinable
  internal var variableNames: Set<String> {
    cachedFieldLock.precondition(.notOwner) // deadlock detection/prevention
    return cachedFieldLock.withLock {
      withLockVariableNames
    }
  }

  /// Thread-safe accessor for variable names (requires lock ownership).
  @inlinable
  internal var withLockVariableNames: Set<String> {
    cachedFieldLock.precondition(.owner)
    return _variableNames.obtainAssuredValue(
      guaranteedBy: Set(
        _withLockTemplateVariables
          .lazy
          .map(\.variableName.rawValue)
      )
    )
  }

}
// MARK: - Synthesized Conformances

extension URITemplateStorage: @unchecked Sendable { }

// MARK: - Equatable

extension URITemplateStorage : Equatable {

  @inlinable
  internal static func ==(
    lhs: URITemplateStorage,
    rhs: URITemplateStorage
  ) -> Bool {
    guard lhs !== rhs else {
      return true
    }
    return lhs.components == rhs.components
  }
  
}

// MARK: - Comparable

extension URITemplateStorage : Comparable {

  @inlinable
  internal static func <(
    lhs: URITemplateStorage,
    rhs: URITemplateStorage
  ) -> Bool {
    guard lhs !== rhs else {
      return false
    }
    return lhs.templateRepresentation < rhs.templateRepresentation
  }
  
}

// MARK: - Hashable

extension URITemplateStorage : Hashable {

  @inlinable
  internal func hash(into hasher: inout Hasher) {
    components.hash(into: &hasher)
  }

}

// MARK: - CustomStringConvertible

extension URITemplateStorage : CustomStringConvertible {

  @usableFromInline
  internal var description: String {
    "storage for uri template: \"\(templateRepresentation)\""
  }

}

// MARK: - CustomDebugStringConvertible

extension URITemplateStorage : CustomDebugStringConvertible {

  @usableFromInline
  internal var debugDescription: String {
    let components = components
      .lazy
      .map(\.debugDescription)
      .joined(separator: ", ")
    return "URITemplateStorage(components: [ \(components) ])"
  }

}

// MARK: - Codable

extension URITemplateStorage : Codable {

  /// Encodes the storage's components.
  @inlinable
  internal func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(components)
  }

  /// Creates storage by decoding components from the given decoder.
  ///
  /// - Throws: `DataValidationError` if any decoded component is invalid.
  @inlinable
  internal convenience init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    let components = try container.decode([URITemplateComponent].self)
    guard components.allSatisfy(\.isValid) else {
      throw DataValidationError(
        forType: URITemplateStorage.self,
        problemDescription: "Decoded invalid `components` \(components.debugDescription)!",
        repairDescription: nil,
        repairSuggestion: nil
      )
    }
    self.init(components: components)
  }
  
}

// MARK: - Core API

extension URITemplateStorage {
  
  @inlinable
  internal var underestimatedExpansionLength: Int {
    // TODO: consider caching, but also consider *not* caching if we pass the expansion variables in, too
    components.reduce(0) { length, component in
      length + component.underestimatedExpansionLength
    }
  }
  
}

// MARK: - Validatable

extension URITemplateStorage {

  /// Indicates whether all components are valid.
  @inlinable
  internal var isValid: Bool {
    components.allSatisfy(\.isValid)
  }

}
