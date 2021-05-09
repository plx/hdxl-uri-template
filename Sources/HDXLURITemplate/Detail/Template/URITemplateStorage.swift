//
//  URITemplateStorage.swift
//

import Foundation
import HDXLCommonUtilities

// -------------------------------------------------------------------------- //
// MARK: URITemplateStorage - Definition
// -------------------------------------------------------------------------- //

@usableFromInline
internal final class URITemplateStorage {
  
  // ------------------------------------------------------------------------ //
  // MARK: `init`
  // ------------------------------------------------------------------------ //
  
  @inlinable
  internal convenience init() {
    self.init(
      components: []
    )
  }
  
  @inlinable
  internal convenience init(component: URITemplateComponent) {
    // /////////////////////////////////////////////////////////////////////////
    pedantic_assert(component.isValid)
    // /////////////////////////////////////////////////////////////////////////
    self.init(
      components: [component]
    )
  }
  
  @inlinable
  internal required init(components: [URITemplateComponent]) {
    // /////////////////////////////////////////////////////////////////////////
    pedantic_assert(components.allElementsAreValid)
    defer { pedantic_assert(self.isValid) }
    // /////////////////////////////////////////////////////////////////////////
    self.components = components
  }
  
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
  
  // ------------------------------------------------------------------------ //
  // MARK: `components`
  // ------------------------------------------------------------------------ //
  
  @usableFromInline
  internal var components: [URITemplateComponent] {
    didSet {
      self.resetCachedDerivedProperties()
    }
  }
  
  @inlinable
  func resetCachedDerivedProperties() {
    self._templateRepresentation = nil
    self._templateVariables = nil
    self._templateVariableNames = nil
    self._templateRepresentation = nil
  }
  
  // ------------------------------------------------------------------------ //
  // MARK: `templateRepresentation`
  // ------------------------------------------------------------------------ //
  
  @usableFromInline
  internal var _templateRepresentation: String? = nil
  
  @inlinable
  internal var templateRepresentation: String {
    get {
      return self._templateRepresentation.obtainAssuredValue(
        fallingBackUpon: self.prepareTemplateRepresentation()
      )
    }
  }
  
  @inlinable
  internal func prepareTemplateRepresentation() -> String {
    return self.components
      .lazy
      .map() {
        (component: URITemplateComponent) -> String
        in
        component.templateRepresentation
    }.joined(separator: "")
  }
  
  // ------------------------------------------------------------------------ //
  // MARK: `templateVariables`
  // ------------------------------------------------------------------------ //
  
  @usableFromInline
  internal var _templateVariables: Set<URITemplateVariable>? = nil
  
  @inlinable
  internal var templateVariables: Set<URITemplateVariable> {
    get {
      return self._templateVariables.obtainAssuredValue(
        fallingBackUpon: self.prepareTemplateVariables()
      )
    }
  }
  
  @inlinable
  func prepareTemplateVariables() -> Set<URITemplateVariable> {
    var result: Set<URITemplateVariable> = []
    for component in self.components {
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
    get {
      return self._templateVariableNames.obtainAssuredValue(
        fallingBackUpon: self.prepareTemplateVariableNames()
      )
    }
  }
  
  @inlinable
  func prepareTemplateVariableNames() -> Set<URITemplateVariableName> {
    return Set(
      self.templateVariables
        .lazy
        .map() { $0.variableName }
    )
  }
  
  // ------------------------------------------------------------------------ //
  // MARK: `variableNames`
  // ------------------------------------------------------------------------ //
  
  @usableFromInline
  internal var _variableNames: Set<String>? = nil
  
  @inlinable
  internal var variableNames: Set<String> {
    get {
      return self._variableNames.obtainAssuredValue(
        fallingBackUpon: self.prepareVariableNames()
      )
    }
  }
  
  @inlinable
  func prepareVariableNames() -> Set<String> {
    return Set(
      self.templateVariables
        .lazy
        .map() { $0.variableName.storage }
    )
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: URITemplateStorage - Validatable
// -------------------------------------------------------------------------- //

extension URITemplateStorage : Validatable {
  
  @inlinable
  internal var isValid: Bool {
    get {
      return self.components.allElementsAreValid
    }
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: URITemplateStorage - Equatable
// -------------------------------------------------------------------------- //

extension URITemplateStorage : Equatable {
  
  @inlinable
  internal static func ==(
    lhs: URITemplateStorage,
    rhs: URITemplateStorage) -> Bool {
    // /////////////////////////////////////////////////////////////////////////
    pedantic_assert(lhs.isValid)
    pedantic_assert(rhs.isValid)
    // /////////////////////////////////////////////////////////////////////////
    guard lhs !== rhs else {
      return true
    }
    return lhs.components == rhs.components
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: URITemplateStorage - Comparable
// -------------------------------------------------------------------------- //

extension URITemplateStorage : Comparable {
  
  @inlinable
  internal static func <(
    lhs: URITemplateStorage,
    rhs: URITemplateStorage) -> Bool {
    // /////////////////////////////////////////////////////////////////////////
    pedantic_assert(lhs.isValid)
    pedantic_assert(rhs.isValid)
    // /////////////////////////////////////////////////////////////////////////
    guard lhs !== rhs else {
      return false
    }
    return lhs.templateRepresentation < rhs.templateRepresentation
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: URITemplateStorage - Hashable
// -------------------------------------------------------------------------- //

extension URITemplateStorage : Hashable {
  
  @inlinable
  internal func hash(into hasher: inout Hasher) {
    self.components.hash(into: &hasher)
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: URITemplateStorage - CustomStringConvertible
// -------------------------------------------------------------------------- //

extension URITemplateStorage : CustomStringConvertible {
  
  @inlinable
  internal var description: String {
    get {
      return "storage for uri template: \"\(self.templateRepresentation)\""
    }
  }
  
  
}

// -------------------------------------------------------------------------- //
// MARK: URITemplateStorage - CustomDebugStringConvertible
// -------------------------------------------------------------------------- //

extension URITemplateStorage : CustomDebugStringConvertible {
  
  @inlinable
  internal var debugDescription: String {
    get {
      let components = self.components
        .lazy
        .map({$0.debugDescription})
        .enclosedJoin(
          endcaps: .squareBrackets,
          separator: ", "
      )
      return "URITemplateStorage(components: \(components))"
    }
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: URITemplateStorage - Codable
// -------------------------------------------------------------------------- //

extension URITemplateStorage : Codable {
  
  @inlinable
  internal func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(
      self.components
    )
  }
  
  @inlinable
  internal convenience init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    let components = try container.decode([URITemplateComponent].self)
    guard components.allElementsAreValid else {
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
