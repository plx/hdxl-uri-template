import Foundation
import os.lock

// -------------------------------------------------------------------------- //
// MARK: URITemplateStorage - Definition
// -------------------------------------------------------------------------- //

@usableFromInline
internal final class URITemplateStorage {

  // ------------------------------------------------------------------------ //
  // MARK: Fields
  // ------------------------------------------------------------------------ //

  @usableFromInline
  internal let components: [URITemplateComponent]

  /// The authoritative, syntactically-valid source for `components`.
  @usableFromInline
  internal let templateSource: String

  /// Coordinates reads and updates of fields populated by nonmutating getters.
  ///
  /// The parsed source and components are immutable, but cache population may
  /// occur without exclusive ownership of the public value. The lock protects
  /// that remaining lazy state.
  /// TODO: see how it'd look to setup a cached-fields struct, migrate it into the struct, and keep all the cached state together.
  @usableFromInline
  internal var cachedFieldLock: OSAllocatedUnfairLock<Void>

  // ------------------------------------------------------------------------ //
  // MARK: `init`
  // ------------------------------------------------------------------------ //

  @usableFromInline
  internal init(parsing template: String) throws {
    let components = try template.parseIntoURITemplateComponents()
    #if HEAVY_DEBUG
      pedanticAssert(components.allSatisfy(\.isValid))
      defer { pedanticAssert(isValid) }
    #endif
    self.components = components
    self.templateSource = template
    self.cachedFieldLock = OSAllocatedUnfairLock()
  }

  // ------------------------------------------------------------------------ //
  // MARK: `templateRepresentation`
  // ------------------------------------------------------------------------ //

  @inlinable
  internal var templateRepresentation: String {
    templateSource
  }

  // ------------------------------------------------------------------------ //
  // MARK: `templateVariables`
  // ------------------------------------------------------------------------ //

  @usableFromInline
  internal var _templateVariables: Set<URITemplateVariable>? = nil

  @inlinable
  internal var templateVariables: Set<URITemplateVariable> {
    cachedFieldLock.precondition(.notOwner)
    return cachedFieldLock.withLock {
      _withLockTemplateVariables
    }
  }

  @inlinable
  internal var _withLockTemplateVariables: Set<URITemplateVariable> {
    cachedFieldLock.precondition(.owner)
    return _templateVariables.obtainAssuredValue(
      guaranteedBy: _withLockPrepareTemplateVariables()
    )
  }

  @inlinable
  func _withLockPrepareTemplateVariables() -> Set<URITemplateVariable> {
    cachedFieldLock.precondition(.owner)
    var result: Set<URITemplateVariable> = []
    for component in components {
      component.injectTemplateVariables(into: &result)
    }
    return result
  }

  // ------------------------------------------------------------------------ //
  // MARK: `templateVariableNames`
  // ------------------------------------------------------------------------ //

  @usableFromInline
  internal var _templateVariableNames: Set<URITemplateVariableName>? = nil

  @inlinable
  internal var templateVariablesNames: Set<URITemplateVariableName> {
    cachedFieldLock.precondition(.notOwner)
    return cachedFieldLock.withLock {
      withLockTemplateVariableNames
    }
  }

  @inlinable
  internal var withLockTemplateVariableNames: Set<URITemplateVariableName> {
    cachedFieldLock.precondition(.owner)
    return _templateVariableNames.obtainAssuredValue(
      guaranteedBy: Set(
        _withLockTemplateVariables
          .lazy
          .map { $0.variableName }
      )
    )
  }

  // ------------------------------------------------------------------------ //
  // MARK: `variableNames`
  // ------------------------------------------------------------------------ //

  @usableFromInline
  internal var _variableNames: Set<String>? = nil

  @inlinable
  internal var variableNames: Set<String> {
    cachedFieldLock.precondition(.notOwner)
    return cachedFieldLock.withLock {
      withLockVariableNames
    }
  }

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

// -------------------------------------------------------------------------- //
// MARK: - Sendable
// -------------------------------------------------------------------------- //

extension URITemplateStorage: @unchecked Sendable {}

// -------------------------------------------------------------------------- //
// MARK: - Equatable
// -------------------------------------------------------------------------- //

extension URITemplateStorage: Equatable {

  @inlinable
  internal static func == (
    lhs: URITemplateStorage,
    rhs: URITemplateStorage
  ) -> Bool {
    #if HEAVY_DEBUG
      pedanticAssert(lhs.isValid)
      pedanticAssert(rhs.isValid)
    #endif
    guard lhs !== rhs else {
      return true
    }
    return lhs.components == rhs.components
  }

}

// -------------------------------------------------------------------------- //
// MARK: - Hashable
// -------------------------------------------------------------------------- //

extension URITemplateStorage: Hashable {

  @inlinable
  internal func hash(into hasher: inout Hasher) {
    components.hash(into: &hasher)
  }

}

// -------------------------------------------------------------------------- //
// MARK: - CustomStringConvertible
// -------------------------------------------------------------------------- //

extension URITemplateStorage: CustomStringConvertible {

  @usableFromInline
  internal var description: String {
    "storage for uri template: \"\(templateRepresentation)\""
  }

}

// -------------------------------------------------------------------------- //
// MARK: - CustomDebugStringConvertible
// -------------------------------------------------------------------------- //

extension URITemplateStorage: CustomDebugStringConvertible {

  @usableFromInline
  internal var debugDescription: String {
    let components = components
      .lazy
      .map(\.debugDescription)
      .joined(separator: ", ")
    return "URITemplateStorage(components: [ \(components) ])"
  }

}

// -------------------------------------------------------------------------- //
// MARK: - Validatable
// -------------------------------------------------------------------------- //

extension URITemplateStorage {

  @inlinable
  internal var isValid: Bool {
    components.allSatisfy(\.isValid)
  }

}
