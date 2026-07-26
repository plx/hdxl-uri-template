import Foundation
import Testing

@testable import HDXLURITemplate

@Test(
  "Association construction rejects the first duplicate deterministically",
  arguments: duplicateAssociationProbes
)
private func associationConstructionRejectsDuplicateKeys(
  probe: DuplicateAssociationProbe
) {
  expectDuplicateAssociationFailure(
    pairs: probe.pairs,
    firstIndex: probe.firstIndex,
    duplicateIndex: probe.duplicateIndex
  )
}

@Test("Association construction preserves valid insertion order")
private func associationConstructionPreservesValidOrder() throws {
  let empty = try URIVariableValue.association(
    [] as [(String, String)]
  )
  let singleton = URIVariableValue.association(
    key: "",
    value: ""
  )
  let caseDistinct = try URIVariableValue.association([
    ("Key", "upper"),
    ("key", "lower")
  ])
  let dictionary = URIVariableValue.association([
    "b": "2",
    "a": "1"
  ])

  #expect(associationPairs(in: empty) == [])
  #expect(
    associationPairs(in: singleton)
      == associationPairSnapshots([("", "")])
  )
  #expect(
    associationPairs(in: caseDistinct)
      == associationPairSnapshots([
        ("Key", "upper"),
        ("key", "lower")
      ])
  )
  #expect(
    associationPairs(in: dictionary)
      == associationPairSnapshots([
        ("a", "1"),
        ("b", "2")
      ])
  )
}

@Test("Association construction consumes arbitrary sequences once")
private func associationConstructionConsumesSequenceOnce() throws {
  let pairs = [
    ("a", "1"),
    ("b", "2"),
    ("c", "3")
  ]
  var iteratorCreationCount = 0
  let sequence = AnySequence<(String, String)> {
    iteratorCreationCount += 1
    var iterator = pairs.makeIterator()
    return AnyIterator {
      iterator.next()
    }
  }

  let value = try URIVariableValue.association(sequence)

  #expect(iteratorCreationCount == 1)
  #expect(
    associationPairs(in: value)
      == associationPairSnapshots(pairs)
  )
}

@Test("Association errors bridge without exposing keys or values")
private func associationErrorsAreStructuredAndPrivate() {
  let secretKey = "private-key-sentinel"
  let secretValue = "private-value-sentinel"

  do {
    _ = try URIVariableValue.association([
      (secretKey, secretValue),
      (secretKey, secretValue)
    ])
    Issue.record("Expected duplicate association keys to throw.")
  } catch let error as URIVariableValue.AssociationError {
    #expect(
      error == .duplicateKey(
        firstIndex: 0,
        duplicateIndex: 1
      )
    )
    let bridgedError = error as NSError
    #expect(
      bridgedError.domain
        == URIVariableValue.AssociationError.errorDomain
    )
    #expect(bridgedError.code == 1)
    #expect(
      bridgedError.userInfo[
        "HDXLURITemplateFirstAssociationKeyIndex"
      ] as? Int == 0
    )
    #expect(
      bridgedError.userInfo[
        "HDXLURITemplateDuplicateAssociationKeyIndex"
      ] as? Int == 1
    )

    let diagnostic = String(reflecting: error)
      + bridgedError.description
      + bridgedError.userInfo.description
    #expect(!diagnostic.contains(secretKey))
    #expect(!diagnostic.contains(secretValue))
  } catch {
    Issue.record("Unexpected association error: \(error)")
  }
}

@Test("Association Codable retains its established ordered wire shape")
private func associationCodablePreservesWireShapeAndOrder() throws {
  let value = try URIVariableValue.association([
    ("b", "2"),
    ("a", "1")
  ])

  let jsonEncoder = JSONEncoder()
  jsonEncoder.outputFormatting = .sortedKeys
  let json = try jsonEncoder.encode(value)
  let jsonString = try #require(
    String(bytes: json, encoding: .utf8)
  )
  #expect(
    jsonString
      ==
      """
      {"data":{"storage":[{"key":"b","value":"2"},{"key":"a","value":"1"}]},"type":8}
      """
  )
  let jsonRoundTrip = try JSONDecoder().decode(
    URIVariableValue.self,
    from: json
  )
  #expect(jsonRoundTrip == value)
  #expect(
    associationPairs(in: jsonRoundTrip)
      == associationPairSnapshots([
        ("b", "2"),
        ("a", "1")
      ])
  )

  let propertyListEncoder = PropertyListEncoder()
  propertyListEncoder.outputFormat = .xml
  let propertyList = try propertyListEncoder.encode(value)
  let propertyListRoundTrip = try PropertyListDecoder().decode(
    URIVariableValue.self,
    from: propertyList
  )
  #expect(propertyListRoundTrip == value)
  #expect(
    associationPairs(in: propertyListRoundTrip)
      == associationPairSnapshots([
        ("b", "2"),
        ("a", "1")
      ])
  )
}

@Test("Association decoding rejects duplicate JSON and property-list keys")
private func associationDecodingRejectsDuplicateKeys() throws {
  let json = Data(
    """
    {
      "type": 8,
      "data": {
        "storage": [
          { "key": "private-key", "value": "private-first" },
          { "key": "private-key", "value": "private-second" }
        ]
      }
    }
    """.utf8
  )
  expectDuplicateDecodeFailure {
    try JSONDecoder().decode(
      URIVariableValue.self,
      from: json
    )
  }

  let propertyList = try PropertyListSerialization.data(
    fromPropertyList: malformedAssociationPropertyList(),
    format: .xml,
    options: 0
  )
  expectDuplicateDecodeFailure {
    try PropertyListDecoder().decode(
      URIVariableValue.self,
      from: propertyList
    )
  }
}

@Test("Malformed secure archives cannot bypass association validation")
private func malformedSecureArchiveCannotBypassAssociationValidation() throws {
  let archiver = NSKeyedArchiver(requiringSecureCoding: true)
  archiver.setClassName(
    NSStringFromClass(URIVariableValueWrapper.self),
    for: MalformedAssociationArchiveProxy.self
  )
  archiver.encode(
    MalformedAssociationArchiveProxy(),
    forKey: NSKeyedArchiveRootObjectKey
  )
  archiver.finishEncoding()

  let unarchiver = try NSKeyedUnarchiver(
    forReadingFrom: archiver.encodedData
  )
  unarchiver.requiresSecureCoding = true
  let decoded = unarchiver.decodeObject(
    of: URIVariableValueWrapper.self,
    forKey: NSKeyedArchiveRootObjectKey
  )
  unarchiver.finishDecoding()

  #expect(decoded == nil)
  let error = try #require(unarchiver.error) as NSError
  #expect(
    error.domain
      == URIVariableValue.AssociationError.errorDomain
  )
  #expect(error.code == 1)
  let diagnostic = error.description
    + error.userInfo.description
  #expect(
    !diagnostic
      .contains("private")
  )
}

@Test("Large and seeded association inputs preserve the invariant")
private func largeAndSeededAssociationInputsPreserveInvariant() throws {
  let largePairs = (0..<10_000).map {
    ("key-\($0)", "value-\($0)")
  }
  let largeValue = try URIVariableValue.association(largePairs)
  #expect(largeValue.count == largePairs.count)
  #expect(associationPairs(in: largeValue).last?.key == largePairs.last?.0)
  #expect(associationPairs(in: largeValue).last?.value == largePairs.last?.1)

  expectDuplicateAssociationFailure(
    pairs: largePairs + [largePairs[9_999]],
    firstIndex: 9_999,
    duplicateIndex: 10_000
  )

  var generator = AssociationProbeGenerator(state: 0x28_2026_0725)
  for _ in 0..<256 {
    let count = Int(generator.next() % 64)
    let pairs = (0..<count).map { index in
      (
        "key-\(generator.next() % 32)",
        "value-\(index)-\(generator.next())"
      )
    }

    if let duplicate = firstDuplicateIndices(in: pairs) {
      expectDuplicateAssociationFailure(
        pairs: pairs,
        firstIndex: duplicate.first,
        duplicateIndex: duplicate.duplicate
      )
    } else {
      let value = try URIVariableValue.association(pairs)
      #expect(
        associationPairs(in: value)
          == associationPairSnapshots(pairs)
      )
    }
  }
}

@Test("Valid association expansion, equality, and hashing remain ordered")
private func validAssociationSemanticsRemainOrdered() throws {
  let value = try URIVariableValue.association([
    ("b", "2"),
    ("a", "1")
  ])
  let equalValue = try URIVariableValue.association([
    ("b", "2"),
    ("a", "1")
  ])
  let reorderedValue = try URIVariableValue.association([
    ("a", "1"),
    ("b", "2")
  ])
  let template = try URITemplate(parsing: "{?items*}")

  #expect(value == equalValue)
  #expect(value.hashValue == equalValue.hashValue)
  #expect(value != reorderedValue)
  #expect(
    try template.evaluateAsString(
      parameters: ["items": value]
    ) == "?b=2&a=1"
  )
}
