import Testing
@testable import HDXLURITemplate

extension Tag {
  @Tag
  static var uriVariableValue: Self
}

@Test(
  "`URIVariableValue` fixtures",
  .tags(.uriVariableValue)
)
private func validateFixtures() {
  verifyOrderedAscending(keys)
  verifyOrderedAscending(values)
  verifyOrderedAscending(pairs)
  #expect(associations.count == associationPairSubsets.count)
  
  verifyAllSatisfy(
    probes,
    explanation: "Expect all probes to be valid.",
    predicate: \.isValid
  )
  
  verifyPairwiseDistinct(probes)
}

@Test(
  "`URIVariableValue` has unique descriptions",
  .tags(.uriVariableValue)
)
private func uniqueDescriptions() {
  verifyUniqueStringification(
    probes,
    using: \.description
  )
}

@Test(
  "`URIVariableValue` has unique debugDescriptions",
  .tags(.uriVariableValue)
)
private func uniqueDebugDescriptions() {
  verifyUniqueStringification(
    probes,
    using: \.debugDescription
  )
}

@Test(
  "`URIVariableValue` characterization API",
  .tags(.uriVariableValue),
  arguments: probes
)
private func characterizationLogic(probe: URIVariableValue) {
  #expect(probe.isDefined == !probe.isUndefined)
  #expect(probe.isTextValue == texts.contains(probe))
  #expect(probe.isListValue == lists.contains(probe))
  #expect(probe.isAssociationValue == associations.contains(probe))
  #expect(1 == countOfTrue(
    probe.isUndefined,
    probe.isTextValue,
    probe.isListValue,
    probe.isAssociationValue
  ))
}

// MARK: Fixtures

private let texts: [URIVariableValue] = [
  "a",
  "ab",
  "abc",
  "abcde",
  "abcdef"
].map {
  URIVariableValue(
    storage: .text(URIVariableTextValue(rawValue: $0))
  )
}

private let lists: [URIVariableValue] = [
  "a",
  "ab",
  "abc",
  "abcde",
  "abcdef"
].map { URIVariableTextValue(rawValue: $0) }
  .smallPowerSet
  .map {
    URIVariableValue(
      storage: .list(URIVariableListValue(values: $0))
    )
  }

private let keys: [URIVariableTextValue] = [
  "a",
  "ab",
  "abc"
].map {
  URIVariableTextValue(rawValue: $0)
}

private let values: [URIVariableTextValue] = [
  "m",
  "mn",
  "mno"
].map {
  URIVariableTextValue(rawValue: $0)
}

private let pairs: [URIVariablePairValue] = cartesianProduct(keys,values)
  .map {
    URIVariablePairValue(
      key: $0,
      value: $1
    )
  }
  .dropLast()
  .sorted()

private let associationPairSubsets = pairs
  .smallPowerSet
  .filter { subset in
    Set(subset.lazy.map(\.key)).count == subset.count
  }

private let associations: [URIVariableValue] = associationPairSubsets
  .compactMap {
    try? URIVariableAssociationValue(validating: $0)
  }
  .map {
    URIVariableValue(storage: .association($0))
  }

private let probes: [URIVariableValue] = {
  var result : [URIVariableValue] = [.undefined]
  result.append(contentsOf: texts)
  result.append(contentsOf: lists)
  result.append(contentsOf: associations)
  return result
}()
