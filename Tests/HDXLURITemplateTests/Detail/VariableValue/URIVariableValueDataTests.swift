import Testing
@testable import HDXLURITemplate

extension Tag {
  @Tag
  static var uriVariableValueData: Self
}

@Test(
  "`URIVariableValueData` fixtures",
  .tags(.uriVariableValueData)
)
private func validateFixtures() {
  verifyOrderedAscending(texts)
  verifyOrderedAscending(lists)
  verifyOrderedAscending(associations)
  verifyOrderedAscending(keys)
  verifyOrderedAscending(values)
  verifyOrderedAscending(pairs)
  verifyOrderedAscending(probes)
  #expect(associations.count == associationPairSubsets.count)
  
  verifyAllSatisfy(
    probes,
    explanation: "Expect all probes to be valid.",
    predicate: \.isValid
  )
  
  verifyPairwiseDistinct(probes)
}

@Test(
  "`URIVariableValueData` ordering logic",
  .tags(.uriVariableValueData)
)
private func validateOrdering() {
  for undefined in undefined {
    for text in texts {
      #expect(undefined < text)
    }
    for text in lists {
      #expect(undefined < text)
    }
    for association in associations {
      #expect(undefined < association)
    }
  }
  
  for text in texts {
    for list in lists {
      #expect(text < list)
    }
    for association in associations {
      #expect(text < association)
    }
  }
  
  for list in lists {
    for association in associations {
      #expect(list < association)
    }
  }
}

@Test(
  "`URIVariableValueData` has unique descriptions",
  .tags(.uriVariableValueData)
)
private func uniqueDescriptions() {
  verifyUniqueStringification(
    probes,
    using: \.description
  )
}

@Test(
  "`URIVariableValueData` has unique debugDescriptions",
  .tags(.uriVariableValueData)
)
private func uniqueDebugDescriptions() {
  verifyUniqueStringification(
    probes,
    using: \.debugDescription
  )
}

@Test(
  "`URIVariableValueData` characterization API",
  .tags(.uriVariableValueData),
  arguments: probes
)
private func characterizationLogic(probe: URIVariableValueData) {
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

private let undefined: [URIVariableValueData] = [.undefined]

private let texts: [URIVariableValueData] = [
  "a",
  "ab",
  "abc",
  "abcde",
  "abcdef"
].map { .text(URIVariableTextValue(rawValue: $0)) }

private let lists: [URIVariableValueData] = [
  "a",
  "ab",
  "abc",
  "abcde",
  "abcdef"
].map { URIVariableTextValue(rawValue: $0) }
  .smallPowerSet
  .map { .list(URIVariableListValue(values: $0)) }
  .sorted()

private let keys: [URIVariableTextValue] = [
  "a",
  "ab",
  "abc"
].map { URIVariableTextValue(rawValue: $0) }

private let values: [URIVariableTextValue] = [
  "m",
  "mn",
  "mno"
].map { URIVariableTextValue(rawValue: $0) }

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

private let associations: [URIVariableValueData] = associationPairSubsets
  .compactMap {
    try? URIVariableAssociationValue(validating: $0)
  }
  .map(URIVariableValueData.association)
  .sorted()

private let probes: [URIVariableValueData] = {
  var result: [URIVariableValueData] = [.undefined]
  result.append(contentsOf: texts)
  result.append(contentsOf: lists)
  result.append(contentsOf: associations)
  
  return result.sorted()
}()
