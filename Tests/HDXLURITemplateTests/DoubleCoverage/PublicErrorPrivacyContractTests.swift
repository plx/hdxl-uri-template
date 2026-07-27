import Foundation
import HDXLURITemplate
import Testing

private let maximumDefaultDiagnosticByteCount = 512

private struct ParsePrivacyProbe: Sendable, CustomTestStringConvertible {
  let label: String
  let source: String
  let sentinels: [String]

  var testDescription: String {
    label
  }
}

private let parsePrivacyProbes: [ParsePrivacyProbe] = {
  let chunkSentinel = "PARSE_CHUNK_SENTINEL_41B9E0F3"
  let strayOpenSentinel = "PARSE_STRAY_OPEN_SENTINEL_5B7CD008"
  let unexpectedCloseSentinel = "PARSE_CLOSE_SENTINEL_78EAA9D4"
  let literalSentinel = "PARSE_LITERAL_SENTINEL_0C7EF94A"
  let variableSentinel = "parsevariablesentinelb782ef31"
  let modifierVariableSentinel = "parsemodifiervariablesentinel89a6c102"
  let invalidModifier = ":00000"

  return [
    ParsePrivacyProbe(
      label: "empty expression",
      source: "{}",
      sentinels: ["{}"]
    ),
    ParsePrivacyProbe(
      label: "stray opening brace",
      source: "{\(strayOpenSentinel){x}",
      sentinels: [strayOpenSentinel]
    ),
    ParsePrivacyProbe(
      label: "unexpected closing brace",
      source: "\(unexpectedCloseSentinel)}",
      sentinels: [unexpectedCloseSentinel]
    ),
    ParsePrivacyProbe(
      label: "unterminated expression",
      source:
        String(repeating: chunkSentinel, count: 1_024)
        + "{",
      sentinels: [chunkSentinel]
    ),
    ParsePrivacyProbe(
      label: "invalid literal",
      source:
        String(repeating: literalSentinel, count: 1_024)
        + " ",
      sentinels: [literalSentinel]
    ),
    ParsePrivacyProbe(
      label: "missing expression variable",
      source: "{?}",
      sentinels: ["{?}", "?"]
    ),
    ParsePrivacyProbe(
      label: "invalid variable name",
      source: "{\(variableSentinel)!}",
      sentinels: [variableSentinel]
    ),
    ParsePrivacyProbe(
      label: "invalid prefix modifier",
      source: "{\(modifierVariableSentinel)\(invalidModifier)}",
      sentinels: [modifierVariableSentinel, invalidModifier]
    ),
  ]
}()

private struct CompositeValuePrivacyProbe: Sendable, CustomTestStringConvertible {
  let label: String
  let value: URIVariableValue
  let valueType: URIVariableValueType
  let payloadSentinels: [String]

  var testDescription: String {
    label
  }
}

private let compositeValuePrivacyProbes = [
  CompositeValuePrivacyProbe(
    label: "list",
    value: .list([
      String(repeating: "LIST_VALUE_SENTINEL_3172FA8B", count: 1_024)
    ]),
    valueType: .list,
    payloadSentinels: ["LIST_VALUE_SENTINEL_3172FA8B"]
  ),
  CompositeValuePrivacyProbe(
    label: "association",
    value: .association(
      key: String(
        repeating: "ASSOCIATION_KEY_SENTINEL_C51E7122",
        count: 1_024
      ),
      value: String(
        repeating: "ASSOCIATION_VALUE_SENTINEL_E86B9904",
        count: 1_024
      )
    ),
    valueType: .association,
    payloadSentinels: [
      "ASSOCIATION_KEY_SENTINEL_C51E7122",
      "ASSOCIATION_VALUE_SENTINEL_E86B9904",
    ]
  ),
]

@Test(
  "Parse error default diagnostics redact source text",
  arguments: parsePrivacyProbes
)
private func parseErrorDefaultDiagnosticsRedactSourceText(
  probe: ParsePrivacyProbe
) {
  do {
    _ = try URITemplate(parsing: probe.source)
    Issue.record("Expected the malformed template to fail parsing.")
  } catch let error as URITemplate.ParseError {
    #expect(error.template == probe.source)
    #expect(error.localizedDescription.contains("parsed"))
    verifySafeDefaultDiagnostics(
      for: error,
      excluding: probe.sentinels
    )
    #expect(error.failureReason?.isEmpty == false)
    #expect(error.sourceRange.upperBound <= probe.source.utf8.count)
  } catch {
    Issue.record("Expected URITemplate.ParseError.")
  }
}

@Test(
  "Evaluation error default diagnostics redact composite values",
  arguments: compositeValuePrivacyProbes
)
private func evaluationErrorDefaultDiagnosticsRedactCompositeValues(
  probe: CompositeValuePrivacyProbe
) throws {
  let templateSentinel = "EVALUATION_TEMPLATE_SENTINEL_6D30EED1"
  let variableName = String(
    repeating: "privatevariablesentinel719e20a4",
    count: 64
  )
  let template = try URITemplate(
    parsing: "https://example.com/\(templateSentinel){?\(variableName):1}"
  )
  let parameters: [String: URIVariableValue] = [
    variableName: probe.value
  ]
  let sentinels =
    [templateSentinel, variableName]
    + probe.payloadSentinels

  do {
    _ = try template.evaluateAsString(parameters: parameters)
    Issue.record("Expected composite prefix evaluation to fail.")
  } catch let error as URITemplate.EvaluationError {
    #expect(error.template == template)
    #expect(error.parameters == parameters)
    #expect(error.localizedDescription.contains("evaluated"))
    #expect(error.kind == .prefixModifierNotApplicable)
    #expect(error.kind.description == "prefixModifierNotApplicable")
    #expect(
      String(reflecting: error.kind)
        == "URITemplate.EvaluationError.Kind.prefixModifierNotApplicable"
    )
    #expect(error.failingVariableName == variableName)
    #expect(error.expressionOperatorToken == "?")
    #expect(error.prefixModifierCodePointCount == 1)
    #expect(error.failingValueType == probe.valueType)
    #expect(error.failureReason?.contains("Prefix modifier `:1`") == true)
    #expect(error.failureReason?.contains("query expansion") == true)
    #expect(
      error.failureReason?.contains(probe.valueType.description) == true
    )
    #expect(error.description.contains("Prefix modifier `:1`"))
    #expect(error.debugDescription.contains("query expansion"))
    #expect(
      (error as NSError).localizedFailureReason?
        .contains(probe.valueType.description) == true
    )
    verifySafeDefaultDiagnostics(
      for: error,
      excluding: sentinels
    )
    if let underlyingError = error.underlyingError {
      verifySafeDefaultDiagnostics(
        for: underlyingError,
        labelPrefix: "underlying expansion error",
        excluding: sentinels
      )
      #expect(
        underlyingError.localizedDescription.contains("Prefix modifier")
      )
      #expect(
        underlyingError.localizedDescription.contains(
          probe.valueType.description
        )
      )
      #expect(underlyingError.localizedDescription.contains(":1"))
      #expect(underlyingError.localizedDescription.contains("query"))
    } else {
      Issue.record("Expected a structured underlying expansion error.")
    }
  } catch {
    Issue.record("Expected URITemplate.EvaluationError.")
  }
}

@Test("URL conversion error diagnostics redact rendered output")
private func urlConversionErrorDiagnosticsRedactRenderedOutput() throws {
  let templateSentinel = "URL_TEMPLATE_SENTINEL_554A24C8"
  let valueSentinel = "URL_VALUE_SENTINEL_57C3F96B"
  let template = try URITemplate(
    parsing: "https://[\(templateSentinel){value}"
  )
  let parameters: [String: URIVariableValue] = [
    "value": .text(String(repeating: valueSentinel, count: 2_048))
  ]
  let sentinels = [templateSentinel, valueSentinel]
  let rendered = try template.evaluateAsString(parameters: parameters)

  #expect(rendered.contains(templateSentinel))
  #expect(rendered.contains(valueSentinel))
  #expect(URL(string: rendered) == nil)

  do {
    _ = try template.evaluate(parameters: parameters)
    Issue.record("Expected URL construction to fail.")
  } catch let error as URITemplate.EvaluationError {
    #expect(error.template == template)
    #expect(error.parameters == parameters)
    #expect(error.kind == .invalidURL)
    #expect(String(describing: error.kind) == "invalidURL")
    #expect(
      String(reflecting: error.kind)
        == "URITemplate.EvaluationError.Kind.invalidURL"
    )
    #expect(error.failingVariableName == nil)
    #expect(error.expressionOperatorToken == nil)
    #expect(error.prefixModifierCodePointCount == nil)
    #expect(error.failingValueType == nil)
    #expect(error.failureReason?.contains("valid URL") == true)
    #expect(error.description.contains("valid URL"))
    #expect(error.debugDescription.contains("valid URL"))
    #expect(
      (error as NSError).localizedFailureReason?
        .contains("valid URL") == true
    )
    verifySafeDefaultDiagnostics(
      for: error,
      excluding: sentinels
    )
    if let underlyingError = error.underlyingError,
      let urlError = underlyingError as? URLError
    {
      #expect(urlError.code == .badURL)
      #expect(urlError.localizedDescription.contains("URL"))
      verifySafeDefaultDiagnostics(
        for: underlyingError,
        labelPrefix: "underlying URL error",
        excluding: sentinels
      )
    } else {
      Issue.record("Expected an underlying bad-URL error.")
    }
  } catch {
    Issue.record("Expected URITemplate.EvaluationError.")
  }
}

private func verifySafeDefaultDiagnostics<Failure: Error>(
  for error: Failure,
  labelPrefix: String = "public error",
  excluding sentinels: [String]
) {
  for surface in defaultDiagnosticSurfaces(for: error) {
    let label = "\(labelPrefix) \(surface.label)"
    if surface.value.utf8.count > maximumDefaultDiagnosticByteCount {
      Issue.record("\(label) exceeded the default diagnostic size bound.")
    }
    for sentinel in sentinels where surface.value.contains(sentinel) {
      Issue.record("\(label) disclosed a test sentinel.")
    }
  }
}

private func defaultDiagnosticSurfaces<Failure: Error>(
  for error: Failure
) -> [(label: String, value: String)] {
  let erasedError: any Error = error
  let anyValue: Any = error
  let localizedError = erasedError as? any LocalizedError
  let customStringConvertible =
    erasedError as any CustomStringConvertible
  let customDebugStringConvertible =
    erasedError as any CustomDebugStringConvertible
  let nsError = erasedError as NSError
  var surfaces: [(label: String, value: String)] = [
    ("concrete String(describing:)", String(describing: error)),
    ("concrete String(reflecting:)", String(reflecting: error)),
    ("erased String(describing:)", String(describing: erasedError)),
    ("erased String(reflecting:)", String(reflecting: erasedError)),
    ("Any String(describing:)", String(describing: anyValue)),
    ("Any String(reflecting:)", String(reflecting: anyValue)),
    ("localizedDescription", erasedError.localizedDescription),
    ("NSError description", nsError.description),
    ("NSError debugDescription", nsError.debugDescription),
    ("NSError domain", nsError.domain),
    ("NSError code", String(nsError.code)),
    ("NSError localizedDescription", nsError.localizedDescription),
    (
      "NSError userInfo String(describing:)",
      String(describing: nsError.userInfo)
    ),
    (
      "NSError userInfo String(reflecting:)",
      String(reflecting: nsError.userInfo)
    ),
  ]

  surfaces.appendIfPresent(
    label: "CustomStringConvertible description",
    value: customStringConvertible.description
  )
  surfaces.appendIfPresent(
    label: "CustomDebugStringConvertible debugDescription",
    value: customDebugStringConvertible.debugDescription
  )
  surfaces.appendIfPresent(
    label: "LocalizedError errorDescription",
    value: localizedError?.errorDescription
  )
  surfaces.appendIfPresent(
    label: "LocalizedError failureReason",
    value: localizedError?.failureReason
  )
  surfaces.appendIfPresent(
    label: "LocalizedError recoverySuggestion",
    value: localizedError?.recoverySuggestion
  )
  surfaces.appendIfPresent(
    label: "LocalizedError helpAnchor",
    value: localizedError?.helpAnchor
  )
  surfaces.appendIfPresent(
    label: "NSError localizedFailureReason",
    value: nsError.localizedFailureReason
  )
  surfaces.appendIfPresent(
    label: "NSError localizedRecoverySuggestion",
    value: nsError.localizedRecoverySuggestion
  )
  surfaces.appendIfPresent(
    label: "NSError helpAnchor",
    value: nsError.helpAnchor
  )
  for option in nsError.localizedRecoveryOptions ?? [] {
    surfaces.append(("NSError recovery option", option))
  }
  for (index, entry) in nsError.userInfo.enumerated() {
    surfaces.append(contentsOf: [
      (
        "NSError userInfo key \(index) String(describing:)",
        String(describing: entry.key)
      ),
      (
        "NSError userInfo key \(index) String(reflecting:)",
        String(reflecting: entry.key)
      ),
    ])
    surfaces.append(
      (
        "NSError userInfo value \(index) String(describing:)",
        String(describing: entry.value)
      )
    )
    surfaces.append(
      (
        "NSError userInfo value \(index) String(reflecting:)",
        String(reflecting: entry.value)
      )
    )
  }

  return surfaces
}

extension Array where Element == (label: String, value: String) {
  fileprivate mutating func appendIfPresent(
    label: String,
    value: String?
  ) {
    guard let value else {
      return
    }
    append((label: label, value: value))
  }
}
