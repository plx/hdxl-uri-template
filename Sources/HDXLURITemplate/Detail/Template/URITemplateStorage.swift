// -------------------------------------------------------------------------- //
// MARK: URITemplateStorage - Definition
// -------------------------------------------------------------------------- //

internal final class URITemplateStorage {

  // ------------------------------------------------------------------------ //
  // MARK: Fields
  // ------------------------------------------------------------------------ //

  internal let components: [URITemplateComponent]

  /// The authoritative, syntactically-valid source for `components`.
  internal let templateSource: String

  /// The distinct public variable-name strings, computed once during
  /// initialization.
  internal let variableNames: Set<String>

  // ------------------------------------------------------------------------ //
  // MARK: `init`
  // ------------------------------------------------------------------------ //

  internal init(parsing template: String) throws {
    let components = try template.parseIntoURITemplateComponents()
    var variableNames: Set<String> = []
    for component in components {
      guard case .expression(let expression) = component else {
        continue
      }
      for variable in expression.variables {
        variableNames.insert(variable.variableName.rawValue)
      }
    }
    #if HEAVY_DEBUG
      pedanticAssert(components.allSatisfy(\.isValid))
      defer { pedanticAssert(isValid) }
    #endif
    self.components = components
    self.templateSource = template
    self.variableNames = variableNames
  }

  // ------------------------------------------------------------------------ //
  // MARK: `templateRepresentation`
  // ------------------------------------------------------------------------ //

  internal var templateRepresentation: String {
    templateSource
  }

}

// -------------------------------------------------------------------------- //
// MARK: - Sendable
// -------------------------------------------------------------------------- //

extension URITemplateStorage: Sendable {}

// -------------------------------------------------------------------------- //
// MARK: - Equatable
// -------------------------------------------------------------------------- //

extension URITemplateStorage: Equatable {

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

  internal func hash(into hasher: inout Hasher) {
    components.hash(into: &hasher)
  }

}

// -------------------------------------------------------------------------- //
// MARK: - CustomStringConvertible
// -------------------------------------------------------------------------- //

extension URITemplateStorage: CustomStringConvertible {

  internal var description: String {
    "storage for uri template: \"\(templateRepresentation)\""
  }

}

// -------------------------------------------------------------------------- //
// MARK: - CustomDebugStringConvertible
// -------------------------------------------------------------------------- //

extension URITemplateStorage: CustomDebugStringConvertible {

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

  internal var isValid: Bool {
    components.allSatisfy(\.isValid)
  }

}
