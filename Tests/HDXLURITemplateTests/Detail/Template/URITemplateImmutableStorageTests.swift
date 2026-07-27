import Foundation
import Testing

@testable import HDXLURITemplate

@Test(
  "Immutable storage preserves value contracts",
  arguments: immutableStorageCases
)
private func immutableStoragePreservesValueContracts(
  testCase: ImmutableStorageCase
) throws {
  let original = try URITemplate(parsing: testCase.source)
  let equivalent = try URITemplate(parsing: testCase.source)
  let copy = original
  let decoded = try JSONDecoder().decode(
    URITemplate.self,
    from: JSONEncoder().encode(original)
  )

  #expect(original.templateRepresentation == testCase.source)
  #expect(original.variableNames == testCase.variableNames)
  #expect(copy.templateRepresentation == testCase.source)
  #expect(copy.variableNames == testCase.variableNames)
  #expect(original == equivalent)
  #expect(original == copy)
  #expect(original == decoded)
  #expect(original.hashValue == equivalent.hashValue)
  #expect(original.hashValue == copy.hashValue)
  #expect(original.hashValue == decoded.hashValue)
  #expect(Set([original, equivalent, copy, decoded]).count == 1)

  let originalExpansion = try original.evaluateAsString(
    parameters: immutableStorageParameters
  )
  let copiedExpansion = try copy.evaluateAsString(
    parameters: immutableStorageParameters
  )
  #expect(copiedExpansion == originalExpansion)
}

@Test("Template storage is compiler-checked Sendable")
private func templateStorageIsCompilerCheckedSendable() throws {
  requireSendable(try URITemplateStorage(parsing: "{value}"))
}

@Test("Shared immutable template supports concurrent composite reads")
private func sharedImmutableTemplateSupportsConcurrentCompositeReads() async throws {
  let source = "https://example.com/é{/segments*}{?query,lang,query}"
  let template = try URITemplate(parsing: source)
  let equivalent = try URITemplate(parsing: source)
  let parameters: [String: URIVariableValue] = [
    "segments": .list(["users", "42"]),
    "query": .text("uri templates"),
    "lang": .text("swift"),
  ]
  let expectedNames: Set<String> = ["segments", "query", "lang"]
  let expectedExpansion =
    "https://example.com/%C3%A9/users/42?query=uri%20templates"
    + "&lang=swift&query=uri%20templates"
  let workerCount = 8
  let operationsPerWorker = 2_500

  let completedOperations = try await withThrowingTaskGroup(
    of: Int.self,
    returning: Int.self
  ) { group in
    for _ in 0..<workerCount {
      group.addTask {
        var completed = 0
        for _ in 0..<operationsPerWorker {
          guard
            template.templateRepresentation == source,
            template.variableNames == expectedNames,
            template == equivalent,
            template.hashValue == equivalent.hashValue,
            try template.evaluateAsString(parameters: parameters)
              == expectedExpansion
          else {
            throw ImmutableStorageTestError.concurrentReadDrift
          }
          completed += 1
        }
        return completed
      }
    }

    var completed = 0
    for try await workerOperations in group {
      completed += workerOperations
    }
    return completed
  }

  #expect(completedOperations == workerCount * operationsPerWorker)
}

private struct ImmutableStorageCase: Sendable, CustomTestStringConvertible {
  let name: String
  let source: String
  let variableNames: Set<String>

  var testDescription: String {
    name
  }
}

private enum ImmutableStorageTestError: Error {
  case concurrentReadDrift
}

private func requireSendable<Value: Sendable>(_ value: Value) {
  _ = value
}

private let immutableStorageCases = [
  ImmutableStorageCase(
    name: "empty",
    source: "",
    variableNames: []
  ),
  ImmutableStorageCase(
    name: "literal-only",
    source: "literal",
    variableNames: []
  ),
  ImmutableStorageCase(
    name: "expression-only",
    source: "{x}",
    variableNames: ["x"]
  ),
  ImmutableStorageCase(
    name: "mixed",
    source: "prefix{/id}{?query}suffix",
    variableNames: ["id", "query"]
  ),
  ImmutableStorageCase(
    name: "repeated-variable",
    source: "{x}mid{?x,y}post",
    variableNames: ["x", "y"]
  ),
  ImmutableStorageCase(
    name: "unicode",
    source: "é/𝄞{?x,y}",
    variableNames: ["x", "y"]
  ),
]

private let immutableStorageParameters: [String: URIVariableValue] = [
  "x": .text("value"),
  "y": .text("second"),
  "id": .text("42"),
  "query": .text("uri templates"),
]
