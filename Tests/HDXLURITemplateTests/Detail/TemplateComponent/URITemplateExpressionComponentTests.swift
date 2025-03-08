import Testing
@testable import HDXLURITemplate

extension Tag {
  @Tag
  static var uriTemplateExpressionComponent: Self
}

@Test(
  "`URITemplateExpressionComponent` test-fixture validation",
  .tags(.uriTemplateExpressionComponent)
)
private func textFixtureIsOk() {
  #expect(variableNameSubsets.count == 8)
  verifyOrderedAscending(probeStrings)
  verifyOrderedAscending(variableNames)
  verifyOrderedAscending(probes)
  verifyPairwiseDistinct(variableNameSubsets)
  verifyPairwiseDistinct(variableSubsets)

  verifyAllSatisfy(
    probes,
    explanation: "`URITemplateExpressionComponent.isValid` should be true for all test-fixture probes!",
    predicate: \.isValid
  )
  verifyPairwiseDistinct(probes)
}

@Test(
  "`URITemplateExpressionComponent` has unique descriptions",
  .tags(.uriTemplateExpressionComponent)
)
private func uniqueDescriptions() {
  verifyUniqueStringification(
    probes,
    using: \.description
  )
}

@Test(
  "`URITemplateExpressionComponent` has unique debugDescriptions",
  .tags(.uriTemplateExpressionComponent)
)
private func uniqueDebugDescriptions() {
  verifyUniqueStringification(
    probes,
    using: \.debugDescription
  )
}

// MARK: Fixtures

private let probeStrings: [String] = [
  "a",
  "ab",
  "abc"
]

private let variableNames: [URITemplateVariableName] = probeStrings
  .map {
    URITemplateVariableName(storage: $0)
  }

private let variableNameSubsets: [[URITemplateVariableName]] = {
  var result: [[URITemplateVariableName]] = []
  for mask in 0...7 {
    // used to use a cartesian-product and small-power-set utility,
    // but don't want to drag in a dependency just for this use case
    var subset: [URITemplateVariableName] = []
    if 0 != (1 & mask) {
      subset.append(variableNames[0])
    }
    if 0 != (2 & mask) {
      subset.append(variableNames[1])
    }
    if 0 != (4 & mask) {
      subset.append(variableNames[2])
    }
    subset.sort()
    result.append(subset)
  }
  
  return result.sorted { $0.lexicographicallyPrecedes($1) }
}()

private let variableSubsets: [[URITemplateVariable]] = {
  var result: [[URITemplateVariable]] = []
  for expansionModifier in URIValueExpansionModifier.allCases[0..<5] {
    for variableNameSubset in variableNameSubsets {
      result.append(
        variableNameSubset.map { variableName in
          URITemplateVariable(
            variableName: variableName,
            expansionModifier: expansionModifier
          )
        }
      )
    }
  }
  
  return result.sorted { $0.lexicographicallyPrecedes($1) }
}()

private let probes: [URITemplateExpressionComponent] = {
  var result: [URITemplateExpressionComponent] = []
  for expansionType in URIValueExpansionType.allCases.sorted() {
    for variableSubset in variableSubsets where !variableSubset.isEmpty {
      result.append(
        URITemplateExpressionComponent(
          expansionType: expansionType,
          variables: variableSubset
        )
      )
    }
  }
  
  return result.sorted()
}()

