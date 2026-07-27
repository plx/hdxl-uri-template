import Foundation
import Testing

@testable import HDXLURITemplate

@Test("Every composite-prefix combination fails at both public entry points")
private func everyCompositePrefixCombinationFailsPublicly() throws {
  let probes = [
    CompositeValueProbe(
      label: "nonempty list",
      value: .list([compositeContentSentinel]),
      valueType: .list
    ),
    CompositeValueProbe(
      label: "empty list",
      value: .emptyList,
      valueType: .list
    ),
    CompositeValueProbe(
      label: "nonempty association",
      value: .association(
        key: "COMPOSITE-KEY-SENTINEL",
        value: compositeContentSentinel
      ),
      valueType: .association
    ),
    CompositeValueProbe(
      label: "empty association",
      value: .emptyAssociation,
      valueType: .association
    ),
  ]

  for expansionOperator in expansionOperators {
    let templateSource =
      "https://example.com/base{\(expansionOperator.token)x:1}"
    let template = try URITemplate(parsing: templateSource)

    for probe in probes {
      for entryPoint in PublicEvaluationEntryPoint.allCases {
        try verifyCompositePrefixFailure(
          entryPoint: entryPoint,
          template: template,
          probe: probe,
          context: "\(expansionOperator.label), \(probe.label), \(entryPoint)"
        )
      }
    }
  }
}

@Test("Text prefixes and undefined variables retain their semantics")
private func textPrefixesAndUndefinedVariablesRemainValid() throws {
  let minimumPrefix = try URITemplate(parsing: "{x:1}")
  #expect(
    try minimumPrefix.evaluateAsString(
      parameters: ["x": .text("value")]
    ) == "v"
  )

  let maximumPrefix = try URITemplate(parsing: "{x:9999}")
  #expect(
    try maximumPrefix.evaluateAsString(
      parameters: ["x": .text("value")]
    ) == "value"
  )

  for expansionOperator in expansionOperators {
    let template = try URITemplate(
      parsing: "before{\(expansionOperator.token)x:1}after"
    )

    #expect(
      try template.evaluateAsString(parameters: [:]) == "beforeafter"
    )
    #expect(
      try template.evaluateAsString(
        parameters: ["x": .undefined]
      ) == "beforeafter"
    )

    for emptyComposite in [
      URIVariableValue.emptyList,
      .emptyAssociation,
    ] {
      for modifier in ["", "*"] {
        let emptyCompositeTemplate = try URITemplate(
          parsing:
            """
            before{\(expansionOperator.token)x\(modifier)}after
            """
        )
        #expect(
          try emptyCompositeTemplate.evaluateAsString(
            parameters: ["x": emptyComposite]
          ) == "beforeafter"
        )
      }
    }
  }
}

@Test("Resolved pinned composite-prefix cases are ordinary passes")
private func resolvedPinnedCompositePrefixCasesAreOrdinaryPasses() throws {
  for templateSource in ["{keys:1}", "{+keys:1}"] {
    let caseIdentity = ReferenceExampleCaseIdentity(
      source: "negative-tests",
      caption: "Failure Tests",
      template: templateSource,
      expectation: .evaluationFailure
    )
    let example = try #require(
      allReferenceExamples().first(where: caseIdentity.matches)
    )

    try verifyReferenceExampleBehavior(example)
  }
}

private struct CompositeValueProbe {
  let label: String
  let value: URIVariableValue
  let valueType: URIVariableValueType
}

private let compositeContentSentinel = "COMPOSITE-CONTENT-SENTINEL"

private let expansionOperators = [
  (label: "simple", token: ""),
  (label: "reserved", token: "+"),
  (label: "fragment", token: "#"),
  (label: "label", token: "."),
  (label: "path", token: "/"),
  (label: "matrix", token: ";"),
  (label: "query", token: "?"),
  (label: "continuation", token: "&"),
]

private enum PublicEvaluationEntryPoint: CaseIterable {
  case string
  case url

  func evaluate(
    template: URITemplate,
    parameters: [String: URIVariableValue]
  ) throws {
    switch self {
    case .string:
      _ = try template.evaluateAsString(parameters: parameters)
    case .url:
      _ = try template.evaluate(parameters: parameters)
    }
  }
}

private func verifyCompositePrefixFailure(
  entryPoint: PublicEvaluationEntryPoint,
  template: URITemplate,
  probe: CompositeValueProbe,
  context: String
) throws {
  let parameters = ["x": probe.value]
  let error = try capturedEvaluationError(
    entryPoint: entryPoint,
    template: template,
    parameters: parameters,
    context: context
  )

  #expect(error.template == template)
  #expect(error.parameters == parameters)

  let underlyingError = try #require(
    error.underlyingError as? URIVariableValue.ExpansionError
  )
  guard
    case .prefixModifierNotApplicable(
      let variableName,
      let expansionType,
      let prefixModifierCodePointCount,
      let valueType
    ) = underlyingError
  else {
    Issue.record(
      "Unexpected underlying error: \(underlyingError)"
    )
    return
  }

  #expect(variableName == "x")
  #expect(prefixModifierCodePointCount == 1)
  #expect(valueType == probe.valueType)
  #expect(error.kind == .prefixModifierNotApplicable)
  #expect(error.failingVariableName == "x")
  #expect(error.expressionOperatorToken == expansionType.formatString)
  #expect(error.prefixModifierCodePointCount == 1)
  #expect(error.failingValueType == probe.valueType)
  #expect(error.failureReason?.contains(":1") == true)
  #expect(error.failureReason?.contains(expansionType.description) == true)
  #expect(
    error.failureReason?.contains(probe.valueType.description) == true
  )

  let defaultDescription = underlyingError.localizedDescription
  #expect(defaultDescription.contains("Prefix modifier"))
  #expect(defaultDescription.contains(":1"))
  #expect(defaultDescription.contains(expansionType.description))
  #expect(defaultDescription.contains(probe.valueType.description))
  #expect(!defaultDescription.contains("`x`"))
  #expect(!defaultDescription.contains(compositeContentSentinel))
  #expect(!defaultDescription.contains("COMPOSITE-KEY-SENTINEL"))
  #expect(!String(reflecting: underlyingError).contains("`x`"))
  #expect(
    !String(reflecting: underlyingError).contains(compositeContentSentinel)
  )
}

private func capturedEvaluationError(
  entryPoint: PublicEvaluationEntryPoint,
  template: URITemplate,
  parameters: [String: URIVariableValue],
  context: String
) throws -> URITemplate.EvaluationError {
  var capturedError: URITemplate.EvaluationError?

  do {
    try entryPoint.evaluate(
      template: template,
      parameters: parameters
    )
    Issue.record(
      "Composite prefix unexpectedly evaluated: \(context)"
    )
  } catch let error as URITemplate.EvaluationError {
    capturedError = error
  } catch {
    Issue.record(
      """
      Composite prefix escaped the public evaluation boundary for \(context): \
      \(String(reflecting: error))
      """
    )
  }

  return try #require(capturedError)
}
