import Foundation
import HDXLURITemplate

// RFC-derived Code Components in this file are attributed in
// THIRD_PARTY_NOTICES.md.

// MARK: - Benchmark-only wire DTOs

package struct CompiledCacheLiteralDTO: Codable, Equatable, Sendable {

  package var text: String

  package init(text: String) {
    self.text = text
  }

}

package struct CompiledCacheOperatorDTO: Codable, Equatable, Sendable {

  /// RFC 6570 expression-prefix codes. The simple operator has an empty code.
  package static let simple = Self(code: "")
  package static let reserved = Self(code: "+")
  package static let fragment = Self(code: "#")
  package static let label = Self(code: ".")
  package static let pathSegment = Self(code: "/")
  package static let pathParameter = Self(code: ";")
  package static let query = Self(code: "?")
  package static let queryContinuation = Self(code: "&")

  package var code: String

  package init(code: String) {
    self.code = code
  }

}

package struct CompiledCacheModifierDTO: Codable, Equatable, Sendable {

  /// Stable wire names. Prefix values use code `"prefix"` plus `prefixLength`.
  package static let unmodified = Self(
    code: "unmodified",
    prefixLength: nil
  )
  package static let explode = Self(
    code: "explode",
    prefixLength: nil
  )

  package var code: String
  package var prefixLength: Int?

  package init(
    code: String,
    prefixLength: Int?
  ) {
    self.code = code
    self.prefixLength = prefixLength
  }

  package static func prefix(
    _ length: Int
  ) -> Self {
    Self(
      code: "prefix",
      prefixLength: length
    )
  }

}

package struct CompiledCacheVariableDTO: Codable, Equatable, Sendable {

  package var name: String
  package var modifier: CompiledCacheModifierDTO

  package init(
    name: String,
    modifier: CompiledCacheModifierDTO
  ) {
    self.name = name
    self.modifier = modifier
  }

}

package struct CompiledCacheExpressionDTO: Codable, Equatable, Sendable {

  package var expansionOperator: CompiledCacheOperatorDTO
  package var variables: [CompiledCacheVariableDTO]

  package init(
    expansionOperator: CompiledCacheOperatorDTO,
    variables: [CompiledCacheVariableDTO]
  ) {
    self.expansionOperator = expansionOperator
    self.variables = variables
  }

}

/// Exactly one of `literal` and `expression` must be non-`nil`.
///
/// Optionals are intentional here: they let corruption tests create structurally
/// invalid, but still decodable, binary property lists.
package struct CompiledCacheComponentDTO: Codable, Equatable, Sendable {

  package var literal: CompiledCacheLiteralDTO?
  package var expression: CompiledCacheExpressionDTO?

  package init(
    literal: CompiledCacheLiteralDTO? = nil,
    expression: CompiledCacheExpressionDTO? = nil
  ) {
    self.literal = literal
    self.expression = expression
  }

}

package struct CompiledCacheTemplateDTO: Codable, Equatable, Sendable {

  package var components: [CompiledCacheComponentDTO]

  package init(
    components: [CompiledCacheComponentDTO]
  ) {
    self.components = components
  }

  /// Compiles one exact source after the public parser has established that it
  /// is valid. Cache loading does not use this initializer.
  package init(
    compiling source: String
  ) throws {
    let parsedTemplate: URITemplate
    do {
      parsedTemplate = try URITemplate(parsing: source)
    } catch {
      throw CompiledCachePrototypeError.invalidAuthoritativeSource(index: 0)
    }

    let compiledTemplate: Self
    do {
      compiledTemplate = try CompiledCachePrototype.compileValidatedSource(
        source
      )
    } catch {
      throw
        CompiledCachePrototypeError
        .compilerCouldNotRepresentSource(index: 0)
    }

    guard
      let validation = CompiledCachePrototype.validateAndRender(
        compiledTemplate
      ),
      validation.renderedSource.utf8.elementsEqual(source.utf8),
      validation.sortedVariableNames == parsedTemplate.variableNames.sorted()
    else {
      throw
        CompiledCachePrototypeError
        .compilerCouldNotRepresentSource(index: 0)
    }

    self = compiledTemplate
  }

  package var exactRenderedSource: String? {
    CompiledCachePrototype.validateAndRender(self)?.renderedSource
  }

  package var sortedVariableNames: [String]? {
    CompiledCachePrototype.validateAndRender(self)?.sortedVariableNames
  }

  package var isStructurallyValid: Bool {
    CompiledCachePrototype.validateAndRender(self) != nil
  }

}

package struct CompiledCacheEnvelope: Codable, Equatable, Sendable {

  package var formatVersion: Int
  package var authoritativeSources: [String]
  package var authoritativeSourceDigest: Data
  package var templates: [CompiledCacheTemplateDTO]
  package var integrityDigest: Data

  package init(
    formatVersion: Int,
    authoritativeSources: [String],
    authoritativeSourceDigest: Data,
    templates: [CompiledCacheTemplateDTO],
    integrityDigest: Data
  ) {
    self.formatVersion = formatVersion
    self.authoritativeSources = authoritativeSources
    self.authoritativeSourceDigest = authoritativeSourceDigest
    self.templates = templates
    self.integrityDigest = integrityDigest
  }

}

// MARK: - Load result

package enum CompiledCacheFallbackReason:
  String,
  Codable,
  Equatable,
  Sendable
{

  case decodeOrTruncated
  case unsupportedVersion
  case integrityMismatch
  case authoritativeSourceMismatch
  case payloadSourceMismatch
  case structuralValidation

}

package enum CompiledCacheOutcome: Equatable, Sendable {

  case hit
  case fallback(CompiledCacheFallbackReason)

}

package struct CompiledCacheResult: Equatable, Sendable {

  package let outcome: CompiledCacheOutcome
  package let sources: [String]
  package let sortedVariableNames: [[String]]
  package let stableResultDigest: String

  package init(
    outcome: CompiledCacheOutcome,
    sources: [String],
    sortedVariableNames: [[String]],
    stableResultDigest: String
  ) {
    self.outcome = outcome
    self.sources = sources
    self.sortedVariableNames = sortedVariableNames
    self.stableResultDigest = stableResultDigest
  }

}

// MARK: - Test fault construction

package enum CompiledCacheFault: Equatable, Sendable {

  case truncated
  case corruptIntegrity
  case unsupportedVersion(Int)
  case authoritativeSourceMismatch
  case payloadSourceMismatch
  case unknownOperator
  case unknownModifier
  case invalidPrefix(Int)
  case emptyExpression

}

package enum CompiledCachePrototypeError: Error, Equatable, Sendable {

  case invalidAuthoritativeSource(index: Int)
  case compilerCouldNotRepresentSource(index: Int)
  case fallbackTemplateCountMismatch(expected: Int, actual: Int)
  case fallbackSourceMismatch(index: Int)
  case faultRequiresDecodableCache

}

// MARK: - Prototype

/// A benchmark-only compiled-cache experiment.
///
/// The authoritative source is supplied independently on every load. The cache
/// is therefore disposable: any rejected cache takes one path through the
/// injected public parser. A cache hit validates and consumes only the DTOs; it
/// never calls `URITemplate.init(parsing:)`.
package enum CompiledCachePrototype {

  package static let currentFormatVersion = 1

  private static let sourceDigestDomain =
    Data("HDXLURITemplate.API03.authoritative-source.v1".utf8)
  private static let cacheIntegrityDomain =
    Data("HDXLURITemplate.API03.compiled-cache.v1".utf8)
  private static let resultDigestDomain =
    Data("HDXLURITemplate.API03.result.v1".utf8)

  // MARK: Encoding

  package static func encode(
    authoritativeSources: [String]
  ) throws -> Data {
    var templates: [CompiledCacheTemplateDTO] = []
    templates.reserveCapacity(authoritativeSources.count)

    for (index, source) in authoritativeSources.enumerated() {
      let parsedTemplate: URITemplate
      do {
        parsedTemplate = try URITemplate(parsing: source)
      } catch {
        throw CompiledCachePrototypeError.invalidAuthoritativeSource(
          index: index
        )
      }

      let compiledTemplate: CompiledCacheTemplateDTO
      do {
        compiledTemplate = try compileValidatedSource(source)
      } catch {
        throw CompiledCachePrototypeError.compilerCouldNotRepresentSource(
          index: index
        )
      }

      guard
        let validation = validateAndRender(compiledTemplate),
        validation.renderedSource.utf8.elementsEqual(source.utf8),
        validation.sortedVariableNames == parsedTemplate.variableNames.sorted()
      else {
        throw CompiledCachePrototypeError.compilerCouldNotRepresentSource(
          index: index
        )
      }

      templates.append(compiledTemplate)
    }

    let sourceDigest = authoritativeSourceDigest(
      for: authoritativeSources
    )
    var envelope = CompiledCacheEnvelope(
      formatVersion: currentFormatVersion,
      authoritativeSources: authoritativeSources,
      authoritativeSourceDigest: sourceDigest,
      templates: templates,
      integrityDigest: Data()
    )
    envelope.integrityDigest = integrityDigest(for: envelope)

    let encoder = PropertyListEncoder()
    encoder.outputFormat = .binary
    return try encoder.encode(envelope)
  }

  // MARK: Loading

  package static func load(
    _ cache: Data,
    authoritativeSources: [String],
    fallback: ([String]) throws -> [URITemplate] = {
      try $0.map {
        try URITemplate(parsing: $0)
      }
    }
  ) throws -> CompiledCacheResult {
    let envelope: CompiledCacheEnvelope
    do {
      envelope = try PropertyListDecoder().decode(
        CompiledCacheEnvelope.self,
        from: cache
      )
    } catch {
      return try fallbackResult(
        reason: .decodeOrTruncated,
        authoritativeSources: authoritativeSources,
        fallback: fallback
      )
    }

    guard envelope.formatVersion == currentFormatVersion else {
      return try fallbackResult(
        reason: .unsupportedVersion,
        authoritativeSources: authoritativeSources,
        fallback: fallback
      )
    }

    guard
      envelope.integrityDigest == integrityDigest(for: envelope)
    else {
      return try fallbackResult(
        reason: .integrityMismatch,
        authoritativeSources: authoritativeSources,
        fallback: fallback
      )
    }

    guard
      envelope.authoritativeSourceDigest
        == authoritativeSourceDigest(for: envelope.authoritativeSources)
    else {
      return try fallbackResult(
        reason: .structuralValidation,
        authoritativeSources: authoritativeSources,
        fallback: fallback
      )
    }

    guard
      envelope.authoritativeSourceDigest
        == authoritativeSourceDigest(for: authoritativeSources),
      exactUTF8ArraysEqual(
        envelope.authoritativeSources,
        authoritativeSources
      )
    else {
      return try fallbackResult(
        reason: .authoritativeSourceMismatch,
        authoritativeSources: authoritativeSources,
        fallback: fallback
      )
    }

    guard envelope.templates.count == authoritativeSources.count else {
      return try fallbackResult(
        reason: .payloadSourceMismatch,
        authoritativeSources: authoritativeSources,
        fallback: fallback
      )
    }

    var renderedSources: [String] = []
    var sortedVariableNames: [[String]] = []
    renderedSources.reserveCapacity(envelope.templates.count)
    sortedVariableNames.reserveCapacity(envelope.templates.count)

    for template in envelope.templates {
      guard let validation = validateAndRender(template) else {
        return try fallbackResult(
          reason: .structuralValidation,
          authoritativeSources: authoritativeSources,
          fallback: fallback
        )
      }
      renderedSources.append(validation.renderedSource)
      sortedVariableNames.append(validation.sortedVariableNames)
    }

    for (renderedSource, authoritativeSource) in zip(
      renderedSources,
      envelope.authoritativeSources
    ) {
      guard
        renderedSource.utf8.elementsEqual(authoritativeSource.utf8)
      else {
        return try fallbackResult(
          reason: .payloadSourceMismatch,
          authoritativeSources: authoritativeSources,
          fallback: fallback
        )
      }
    }

    return makeResult(
      outcome: .hit,
      sources: renderedSources,
      sortedVariableNames: sortedVariableNames
    )
  }

  /// Produces the same stable public projection used by cache hits and
  /// fallbacks. Other benchmark lanes use this to compare results without
  /// depending on Swift's randomized `Hashable` implementation.
  package static func summarize(
    _ templates: [URITemplate]
  ) -> CompiledCacheResult {
    let sources = templates.map(\.templateRepresentation)
    let sortedVariableNames = templates.map {
      $0.variableNames.sorted()
    }
    return makeResult(
      outcome: .hit,
      sources: sources,
      sortedVariableNames: sortedVariableNames
    )
  }

  package static func stableResultDigest(
    sources: [String],
    sortedVariableNames: [[String]]
  ) -> String {
    resultDigest(
      sources: sources,
      sortedVariableNames: sortedVariableNames
    )
  }

  // MARK: Safe test faults

  package static func applying(
    _ fault: CompiledCacheFault,
    to validCache: Data
  ) throws -> Data {
    if case .truncated = fault {
      guard !validCache.isEmpty else {
        throw CompiledCachePrototypeError.faultRequiresDecodableCache
      }
      return Data(validCache.prefix(validCache.count / 2))
    }

    guard
      var envelope = try? PropertyListDecoder().decode(
        CompiledCacheEnvelope.self,
        from: validCache
      )
    else {
      throw CompiledCachePrototypeError.faultRequiresDecodableCache
    }

    switch fault {
    case .truncated:
      preconditionFailure("Handled before decoding.")

    case .corruptIntegrity:
      envelope.integrityDigest = flippedFirstByte(
        of: envelope.integrityDigest
      )
      return try encodeEnvelope(envelope)

    case .unsupportedVersion(let requestedVersion):
      envelope.formatVersion =
        requestedVersion == currentFormatVersion
        ? currentFormatVersion + 1
        : requestedVersion

    case .authoritativeSourceMismatch:
      if envelope.authoritativeSources.isEmpty {
        envelope.authoritativeSources = ["x"]
      } else {
        envelope.authoritativeSources[0].append("x")
      }
      envelope.authoritativeSourceDigest = authoritativeSourceDigest(
        for: envelope.authoritativeSources
      )

    case .payloadSourceMismatch:
      mutatePayloadToRemainValidButMismatchSource(
        in: &envelope
      )

    case .unknownOperator:
      mutateFirstExpression(in: &envelope) {
        $0.expansionOperator.code = "unknown"
      }

    case .unknownModifier:
      mutateFirstVariable(in: &envelope) {
        $0.modifier = CompiledCacheModifierDTO(
          code: "unknown",
          prefixLength: nil
        )
      }

    case .invalidPrefix(let length):
      mutateFirstVariable(in: &envelope) {
        $0.modifier = .prefix(
          (1...9999).contains(length) ? 0 : length
        )
      }

    case .emptyExpression:
      mutateFirstExpression(in: &envelope) {
        $0.variables = []
      }
    }

    envelope.integrityDigest = integrityDigest(for: envelope)
    return try encodeEnvelope(envelope)
  }

}

// MARK: - Compilation

extension CompiledCachePrototype {

  fileprivate static func compileValidatedSource(
    _ source: String
  ) throws -> CompiledCacheTemplateDTO {
    guard !source.isEmpty else {
      return CompiledCacheTemplateDTO(components: [])
    }

    var components: [CompiledCacheComponentDTO] = []
    var literalStart = source.startIndex
    var cursor = source.startIndex

    while cursor < source.endIndex {
      switch source[cursor] {
      case "{":
        if literalStart < cursor {
          components.append(
            CompiledCacheComponentDTO(
              literal: CompiledCacheLiteralDTO(
                text: String(source[literalStart..<cursor])
              )
            )
          )
        }

        let expressionStart = source.index(after: cursor)
        guard
          let expressionEnd = source[
            expressionStart..<source.endIndex
          ].firstIndex(of: "}")
        else {
          throw
            CompiledCachePrototypeError
            .compilerCouldNotRepresentSource(index: 0)
        }

        let expressionSource = String(
          source[expressionStart..<expressionEnd]
        )
        components.append(
          CompiledCacheComponentDTO(
            expression: try compileExpression(expressionSource)
          )
        )
        cursor = source.index(after: expressionEnd)
        literalStart = cursor

      case "}":
        throw
          CompiledCachePrototypeError
          .compilerCouldNotRepresentSource(index: 0)

      default:
        cursor = source.index(after: cursor)
      }
    }

    if literalStart < source.endIndex {
      components.append(
        CompiledCacheComponentDTO(
          literal: CompiledCacheLiteralDTO(
            text: String(source[literalStart..<source.endIndex])
          )
        )
      )
    }

    return CompiledCacheTemplateDTO(
      components: components
    )
  }

  fileprivate static func compileExpression(
    _ source: String
  ) throws -> CompiledCacheExpressionDTO {
    guard !source.isEmpty else {
      throw
        CompiledCachePrototypeError
        .compilerCouldNotRepresentSource(index: 0)
    }

    var variableList = source
    let expansionOperator: CompiledCacheOperatorDTO

    if let firstCharacter = variableList.first {
      switch firstCharacter {
      case "+":
        expansionOperator = .reserved
      case "#":
        expansionOperator = .fragment
      case ".":
        expansionOperator = .label
      case "/":
        expansionOperator = .pathSegment
      case ";":
        expansionOperator = .pathParameter
      case "?":
        expansionOperator = .query
      case "&":
        expansionOperator = .queryContinuation
      default:
        expansionOperator = .simple
      }

      if expansionOperator != .simple {
        variableList.removeFirst()
      }
    } else {
      expansionOperator = .simple
    }

    let variables =
      try variableList
      .split(separator: ",", omittingEmptySubsequences: false)
      .map {
        try compileVariable(String($0))
      }

    return CompiledCacheExpressionDTO(
      expansionOperator: expansionOperator,
      variables: variables
    )
  }

  fileprivate static func compileVariable(
    _ source: String
  ) throws -> CompiledCacheVariableDTO {
    guard !source.isEmpty else {
      throw
        CompiledCachePrototypeError
        .compilerCouldNotRepresentSource(index: 0)
    }

    if source.hasSuffix("*") {
      return CompiledCacheVariableDTO(
        name: String(source.dropLast()),
        modifier: .explode
      )
    }

    if let colon = source.lastIndex(of: ":") {
      let prefixStart = source.index(after: colon)
      let prefixSource = source[prefixStart..<source.endIndex]
      guard let prefixLength = Int(prefixSource) else {
        throw
          CompiledCachePrototypeError
          .compilerCouldNotRepresentSource(index: 0)
      }
      return CompiledCacheVariableDTO(
        name: String(source[..<colon]),
        modifier: .prefix(prefixLength)
      )
    }

    return CompiledCacheVariableDTO(
      name: source,
      modifier: .unmodified
    )
  }

}

// MARK: - Structural validation and exact rendering

extension CompiledCachePrototype {

  fileprivate struct ValidatedTemplate {
    var renderedSource: String
    var sortedVariableNames: [String]
  }

  fileprivate static func validateAndRender(
    _ template: CompiledCacheTemplateDTO
  ) -> ValidatedTemplate? {
    var source = ""
    var variableNames = Set<String>()
    var previousWasLiteral = false

    for component in template.components {
      switch (component.literal, component.expression) {
      case (.some(let literal), .none):
        guard
          !previousWasLiteral,
          isValidLiteral(literal.text)
        else {
          return nil
        }
        source.append(contentsOf: literal.text)
        previousWasLiteral = true

      case (.none, .some(let expression)):
        guard
          isKnownOperator(expression.expansionOperator),
          !expression.variables.isEmpty
        else {
          return nil
        }

        source.append("{")
        source.append(contentsOf: expression.expansionOperator.code)

        for (index, variable) in expression.variables.enumerated() {
          guard
            isValidVariableName(variable.name),
            let modifierSource = validatedModifierSource(
              variable.modifier
            )
          else {
            return nil
          }

          if index > 0 {
            source.append(",")
          }
          source.append(contentsOf: variable.name)
          source.append(contentsOf: modifierSource)
          variableNames.insert(variable.name)
        }

        source.append("}")
        previousWasLiteral = false

      case (.none, .none), (.some, .some):
        return nil
      }
    }

    return ValidatedTemplate(
      renderedSource: source,
      sortedVariableNames: variableNames.sorted()
    )
  }

  fileprivate static func isKnownOperator(
    _ expansionOperator: CompiledCacheOperatorDTO
  ) -> Bool {
    switch expansionOperator.code {
    case "", "+", "#", ".", "/", ";", "?", "&":
      true
    default:
      false
    }
  }

  fileprivate static func validatedModifierSource(
    _ modifier: CompiledCacheModifierDTO
  ) -> String? {
    switch (modifier.code, modifier.prefixLength) {
    case ("unmodified", .none):
      ""
    case ("explode", .none):
      "*"
    case ("prefix", .some(let length))
    where (1...9999).contains(length):
      ":\(length)"
    default:
      nil
    }
  }

  fileprivate static func isValidVariableName(
    _ name: String
  ) -> Bool {
    let bytes = Array(name.utf8)
    guard !bytes.isEmpty else {
      return false
    }

    var index = 0
    var segmentHasContent = false

    while index < bytes.count {
      let byte = bytes[index]

      if byte == 0x2E {
        guard segmentHasContent else {
          return false
        }
        segmentHasContent = false
        index += 1
        continue
      }

      if isASCIIAlphaNumericOrUnderscore(byte) {
        segmentHasContent = true
        index += 1
        continue
      }

      if byte == 0x25 {
        guard
          index + 2 < bytes.count,
          isASCIIHexDigit(bytes[index + 1]),
          isASCIIHexDigit(bytes[index + 2])
        else {
          return false
        }
        segmentHasContent = true
        index += 3
        continue
      }

      return false
    }

    return segmentHasContent
  }

  fileprivate static func isValidLiteral(
    _ literal: String
  ) -> Bool {
    let scalars = Array(literal.unicodeScalars)
    guard !scalars.isEmpty else {
      return false
    }

    var index = 0
    while index < scalars.count {
      let scalarValue = scalars[index].value

      if scalarValue == 0x25 {
        guard
          index + 2 < scalars.count,
          isASCIIHexDigit(scalars[index + 1].value),
          isASCIIHexDigit(scalars[index + 2].value)
        else {
          return false
        }
        index += 3
        continue
      }

      guard isAllowedLiteralScalar(scalarValue) else {
        return false
      }
      index += 1
    }

    return true
  }

  fileprivate static func isAllowedLiteralScalar(
    _ scalar: UInt32
  ) -> Bool {
    switch scalar {
    case 0x21,
      0x23...0x24,
      0x26...0x3B,
      0x3D,
      0x3F...0x5B,
      0x5D,
      0x5F,
      0x61...0x7A,
      0x7E,
      0xA0...0xD7FF,
      0xE000...0xF8FF,
      0xF900...0xFDCF,
      0xFDF0...0xFFEF,
      0x10000...0x1FFFD,
      0x20000...0x2FFFD,
      0x30000...0x3FFFD,
      0x40000...0x4FFFD,
      0x50000...0x5FFFD,
      0x60000...0x6FFFD,
      0x70000...0x7FFFD,
      0x80000...0x8FFFD,
      0x90000...0x9FFFD,
      0xA0000...0xAFFFD,
      0xB0000...0xBFFFD,
      0xC0000...0xCFFFD,
      0xD0000...0xDFFFD,
      0xE1000...0xEFFFD,
      0xF0000...0xFFFFD,
      0x100000...0x10FFFD:
      true
    default:
      false
    }
  }

  fileprivate static func isASCIIAlphaNumericOrUnderscore(
    _ byte: UInt8
  ) -> Bool {
    (0x30...0x39).contains(byte)
      || (0x41...0x5A).contains(byte)
      || byte == 0x5F
      || (0x61...0x7A).contains(byte)
  }

  fileprivate static func isASCIIHexDigit(
    _ byte: UInt8
  ) -> Bool {
    (0x30...0x39).contains(byte)
      || (0x41...0x46).contains(byte)
      || (0x61...0x66).contains(byte)
  }

  fileprivate static func isASCIIHexDigit(
    _ scalar: UInt32
  ) -> Bool {
    guard let byte = UInt8(exactly: scalar) else {
      return false
    }
    return isASCIIHexDigit(byte)
  }

  fileprivate static func exactUTF8ArraysEqual(
    _ lhs: [String],
    _ rhs: [String]
  ) -> Bool {
    guard lhs.count == rhs.count else {
      return false
    }
    return zip(lhs, rhs).allSatisfy { pair in
      pair.0.utf8.elementsEqual(pair.1.utf8)
    }
  }

}

// MARK: - Stable digests

extension CompiledCachePrototype {

  fileprivate static func authoritativeSourceDigest(
    for sources: [String]
  ) -> Data {
    var fields = [
      sourceDigestDomain,
      decimalData(sources.count),
    ]
    fields.append(contentsOf: sources.map { Data($0.utf8) })
    return StableDigest.sha256(lengthPrefixed: fields)
  }

  fileprivate static func integrityDigest(
    for envelope: CompiledCacheEnvelope
  ) -> Data {
    var fields: [Data] = [
      cacheIntegrityDomain,
      decimalData(envelope.formatVersion),
      decimalData(envelope.authoritativeSources.count),
    ]
    fields.append(
      contentsOf: envelope.authoritativeSources.map {
        Data($0.utf8)
      }
    )
    fields.append(
      contentsOf: [
        envelope.authoritativeSourceDigest,
        decimalData(envelope.templates.count),
      ]
    )

    for template in envelope.templates {
      fields.append(decimalData(template.components.count))

      for component in template.components {
        if let literal = component.literal {
          fields.append(Data([1]))
          fields.append(Data(literal.text.utf8))
        } else {
          fields.append(Data([0]))
        }

        if let expression = component.expression {
          fields.append(Data([1]))
          fields.append(Data(expression.expansionOperator.code.utf8))
          fields.append(decimalData(expression.variables.count))

          for variable in expression.variables {
            fields.append(Data(variable.name.utf8))
            fields.append(Data(variable.modifier.code.utf8))
            if let prefixLength = variable.modifier.prefixLength {
              fields.append(Data([1]))
              fields.append(decimalData(prefixLength))
            } else {
              fields.append(Data([0]))
            }
          }
        } else {
          fields.append(Data([0]))
        }
      }
    }

    return StableDigest.sha256(lengthPrefixed: fields)
  }

  fileprivate static func resultDigest(
    sources: [String],
    sortedVariableNames: [[String]]
  ) -> String {
    var fields: [Data] = [
      resultDigestDomain,
      decimalData(sources.count),
    ]

    for index in sources.indices {
      fields.append(Data(sources[index].utf8))
      let names =
        index < sortedVariableNames.count
        ? sortedVariableNames[index]
        : []
      fields.append(decimalData(names.count))
      fields.append(contentsOf: names.map { Data($0.utf8) })
    }

    return StableDigest.hex(
      StableDigest.sha256(lengthPrefixed: fields)
    )
  }

  fileprivate static func decimalData<T: BinaryInteger>(
    _ value: T
  ) -> Data {
    Data(String(value).utf8)
  }

}

// MARK: - Result and fallback

extension CompiledCachePrototype {

  fileprivate static func makeResult(
    outcome: CompiledCacheOutcome,
    sources: [String],
    sortedVariableNames: [[String]]
  ) -> CompiledCacheResult {
    CompiledCacheResult(
      outcome: outcome,
      sources: sources,
      sortedVariableNames: sortedVariableNames,
      stableResultDigest: resultDigest(
        sources: sources,
        sortedVariableNames: sortedVariableNames
      )
    )
  }

  fileprivate static func fallbackResult(
    reason: CompiledCacheFallbackReason,
    authoritativeSources: [String],
    fallback: ([String]) throws -> [URITemplate]
  ) throws -> CompiledCacheResult {
    // Deliberately invoke the injected parser exactly once. Everything below
    // derives from that one returned collection.
    let templates = try fallback(authoritativeSources)

    guard templates.count == authoritativeSources.count else {
      throw CompiledCachePrototypeError.fallbackTemplateCountMismatch(
        expected: authoritativeSources.count,
        actual: templates.count
      )
    }

    let parsedSources = templates.map(\.templateRepresentation)
    for index in parsedSources.indices {
      guard
        parsedSources[index].utf8.elementsEqual(
          authoritativeSources[index].utf8
        )
      else {
        throw CompiledCachePrototypeError.fallbackSourceMismatch(
          index: index
        )
      }
    }

    return makeResult(
      outcome: .fallback(reason),
      sources: parsedSources,
      sortedVariableNames: templates.map {
        $0.variableNames.sorted()
      }
    )
  }

}

// MARK: - Fault mutation helpers

extension CompiledCachePrototype {

  fileprivate static func encodeEnvelope(
    _ envelope: CompiledCacheEnvelope
  ) throws -> Data {
    let encoder = PropertyListEncoder()
    encoder.outputFormat = .binary
    return try encoder.encode(envelope)
  }

  fileprivate static func flippedFirstByte(
    of data: Data
  ) -> Data {
    guard !data.isEmpty else {
      return Data([0xFF])
    }
    var result = data
    result[result.startIndex] ^= 0xFF
    return result
  }

  fileprivate static func ensureFirstTemplate(
    in envelope: inout CompiledCacheEnvelope
  ) {
    if envelope.templates.isEmpty {
      envelope.templates.append(
        CompiledCacheTemplateDTO(components: [])
      )
    }
  }

  fileprivate static func mutateFirstExpression(
    in envelope: inout CompiledCacheEnvelope,
    _ mutation: (inout CompiledCacheExpressionDTO) -> Void
  ) {
    ensureFirstTemplate(in: &envelope)

    for templateIndex in envelope.templates.indices {
      for componentIndex
        in envelope.templates[templateIndex].components.indices
      {
        guard
          var expression =
            envelope
            .templates[templateIndex]
            .components[componentIndex]
            .expression
        else {
          continue
        }
        mutation(&expression)
        envelope
          .templates[templateIndex]
          .components[componentIndex]
          .expression = expression
        return
      }
    }

    var expression = CompiledCacheExpressionDTO(
      expansionOperator: .simple,
      variables: [
        CompiledCacheVariableDTO(
          name: "x",
          modifier: .unmodified
        )
      ]
    )
    mutation(&expression)
    envelope.templates[0].components.append(
      CompiledCacheComponentDTO(
        expression: expression
      )
    )
  }

  fileprivate static func mutateFirstVariable(
    in envelope: inout CompiledCacheEnvelope,
    _ mutation: (inout CompiledCacheVariableDTO) -> Void
  ) {
    ensureFirstTemplate(in: &envelope)

    for templateIndex in envelope.templates.indices {
      for componentIndex
        in envelope.templates[templateIndex].components.indices
      {
        guard
          var expression =
            envelope
            .templates[templateIndex]
            .components[componentIndex]
            .expression,
          !expression.variables.isEmpty
        else {
          continue
        }
        mutation(&expression.variables[0])
        envelope
          .templates[templateIndex]
          .components[componentIndex]
          .expression = expression
        return
      }
    }

    var variable = CompiledCacheVariableDTO(
      name: "x",
      modifier: .unmodified
    )
    mutation(&variable)
    envelope.templates[0].components.append(
      CompiledCacheComponentDTO(
        expression: CompiledCacheExpressionDTO(
          expansionOperator: .simple,
          variables: [variable]
        )
      )
    )
  }

  fileprivate static func mutatePayloadToRemainValidButMismatchSource(
    in envelope: inout CompiledCacheEnvelope
  ) {
    ensureFirstTemplate(in: &envelope)

    for templateIndex in envelope.templates.indices {
      for componentIndex
        in envelope.templates[templateIndex].components.indices
      {
        if var literal =
          envelope
          .templates[templateIndex]
          .components[componentIndex]
          .literal
        {
          literal.text.append("x")
          envelope
            .templates[templateIndex]
            .components[componentIndex]
            .literal = literal
          return
        }

        if var expression =
          envelope
          .templates[templateIndex]
          .components[componentIndex]
          .expression,
          !expression.variables.isEmpty
        {
          expression.variables[0].name.append("x")
          envelope
            .templates[templateIndex]
            .components[componentIndex]
            .expression = expression
          return
        }
      }
    }

    envelope.templates[0].components.append(
      CompiledCacheComponentDTO(
        literal: CompiledCacheLiteralDTO(text: "x")
      )
    )
  }

}
