import Foundation
import Testing

@testable import HDXLURITemplate

struct DuplicateAssociationProbe:
  CustomTestStringConvertible,
  Sendable
{

  let label: String
  let pairs: [(String, String)]
  let firstIndex: Int
  let duplicateIndex: Int

  var testDescription: String {
    label
  }
}

let duplicateAssociationProbes = [
  DuplicateAssociationProbe(
    label: "adjacent",
    pairs: [("a", "1"), ("a", "2")],
    firstIndex: 0,
    duplicateIndex: 1
  ),
  DuplicateAssociationProbe(
    label: "nonadjacent",
    pairs: [("a", "1"), ("b", "2"), ("a", "3")],
    firstIndex: 0,
    duplicateIndex: 2
  ),
  DuplicateAssociationProbe(
    label: "first repeated group wins",
    pairs: [
      ("a", "1"),
      ("b", "2"),
      ("c", "3"),
      ("b", "4"),
      ("a", "5"),
    ],
    firstIndex: 1,
    duplicateIndex: 3
  ),
  DuplicateAssociationProbe(
    label: "empty key",
    pairs: [("", "1"), ("", "2")],
    firstIndex: 0,
    duplicateIndex: 1
  ),
  DuplicateAssociationProbe(
    label: "canonical Unicode equivalence",
    pairs: [("\u{00E9}", "1"), ("e\u{0301}", "2")],
    firstIndex: 0,
    duplicateIndex: 1
  ),
]

func malformedAssociationPropertyList() -> [String: Any] {
  [
    "type": 8,
    "data": [
      "storage": [
        ["key": "private-key", "value": "private-first"],
        ["key": "private-key", "value": "private-second"],
      ]
    ],
  ]
}

struct MalformedAssociationValuePayload: Encodable {
  let type = 8
  let data = MalformedAssociationPayload()
}

struct MalformedAssociationPayload: Encodable {
  let storage = [
    MalformedAssociationPair(
      key: "private-key",
      value: "private-first"
    ),
    MalformedAssociationPair(
      key: "private-key",
      value: "private-second"
    ),
  ]
}

struct MalformedAssociationPair: Encodable {
  let key: String
  let value: String
}

struct AssociationProbeGenerator {
  var state: UInt64

  mutating func next() -> UInt64 {
    state = state &* 6_364_136_223_846_793_005 &+ 1
    return state
  }
}

struct AssociationPairSnapshot: Equatable {
  let key: String
  let value: String
}

func associationPairs(
  in value: URIVariableValue
) -> [AssociationPairSnapshot] {
  guard case .association(let association) = value.storage else {
    Issue.record("Expected an association value.")
    return []
  }
  return association.storage.map {
    AssociationPairSnapshot(
      key: $0.key.rawValue,
      value: $0.value.rawValue
    )
  }
}

func associationPairSnapshots(
  _ pairs: [(String, String)]
) -> [AssociationPairSnapshot] {
  pairs.map {
    AssociationPairSnapshot(
      key: $0.0,
      value: $0.1
    )
  }
}

func expectDuplicateAssociationFailure(
  pairs: [(String, String)],
  firstIndex: Int,
  duplicateIndex: Int
) {
  do {
    _ = try URIVariableValue.association(pairs)
    Issue.record("Expected duplicate association keys to throw.")
  } catch let error as URIVariableValue.AssociationError {
    #expect(
      error
        == .duplicateKey(
          firstIndex: firstIndex,
          duplicateIndex: duplicateIndex
        )
    )
  } catch {
    Issue.record("Unexpected association error: \(error)")
  }
}

func expectDuplicateDecodeFailure(
  _ operation: () throws -> URIVariableValue
) {
  do {
    _ = try operation()
    Issue.record("Expected duplicate association decoding to throw.")
  } catch let error as URIVariableValue.AssociationError {
    #expect(
      error
        == .duplicateKey(
          firstIndex: 0,
          duplicateIndex: 1
        )
    )
    let bridgedError = error as NSError
    let diagnostic =
      String(reflecting: error)
      + bridgedError.description
      + bridgedError.userInfo.description
    #expect(!diagnostic.contains("private"))
  } catch {
    Issue.record("Unexpected association decode error: \(error)")
  }
}

func firstDuplicateIndices(
  in pairs: [(String, String)]
) -> (first: Int, duplicate: Int)? {
  var firstIndices: [String: Int] = [:]
  for (index, pair) in pairs.enumerated() {
    if let first = firstIndices[pair.0] {
      return (first, index)
    }
    firstIndices[pair.0] = index
  }
  return nil
}
