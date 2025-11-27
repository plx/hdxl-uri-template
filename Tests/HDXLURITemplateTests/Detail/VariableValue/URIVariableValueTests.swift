import Testing
@testable import HDXLURITemplate

extension Tag {
  @Tag
  static var uriVariableValue: Self
}

@Suite(.tags(.uriVariableValue))
struct URIVariableValueTests {

  @Test
  private func `fixtures are sensible`() {
    verifyOrderedAscending(texts)
    verifyOrderedAscending(lists)
    verifyOrderedAscending(associations)
    verifyOrderedAscending(keys)
    verifyOrderedAscending(values)
    verifyOrderedAscending(pairs)
    verifyOrderedAscending(probes)
    
    verifyAllSatisfy(
      probes,
      explanation: "Expect all probes to be valid.",
      predicate: \.isValid
    )
    
    verifyPairwiseDistinct(probes)
  }
  
  @Test
  private func `ordering logic`() {
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
  
  @Test
  private func `unique descriptions`() {
    verifyUniqueStringification(
      probes,
      using: \.description
    )
  }
  
  @Test
  private func `unique debugDescriptions`() {
    verifyUniqueStringification(
      probes,
      using: \.debugDescription
    )
  }
  
  @Test(arguments: probes)
  private func `characterization API`(probe: URIVariableValue) {
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

}

// MARK: - Fixtures

private let undefined: [URIVariableValue] = [.undefined]

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
  .sorted()

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

private let associations: [URIVariableValue] = pairs
  .smallPowerSet
  .filter { subset in
    Set(subset.lazy.map(\.key)).count == subset.count
  }
  .map {
    URIVariableValue(storage: .association(URIVariableAssociationValue(values: $0)))
  }
  .sorted()

private let probes: [URIVariableValue] = {
  var result : [URIVariableValue] = [.undefined]
  result.append(contentsOf: texts)
  result.append(contentsOf: lists)
  result.append(contentsOf: associations)
  return result.sorted()
}()
