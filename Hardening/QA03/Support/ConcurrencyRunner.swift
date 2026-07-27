import Dispatch
import Foundation
import HDXLURITemplate

package struct QA03ConcurrencyReport: Codable, Sendable {
  package let schemaVersion: Int
  package let command: String
  package let commit: String
  package let requestedOperationsPerPhase: Int
  package let parallelWorkerCount: Int
  package let phases: [Phase]

  package struct Phase: Codable, Sendable {
    package let name: String
    package let workerCount: Int
    package let completedOperations: Int
    package let elapsedNanoseconds: UInt64
    package let resultDigest: String
  }
}

package enum QA03ConcurrencyRunner {

  package static func run(
    operationsPerPhase: Int,
    parallelWorkerCount: Int,
    commit: String
  ) async throws -> QA03ConcurrencyReport {
    guard operationsPerPhase >= 100_000 else {
      throw QA03Error(
        "Concurrency stress requires at least 100,000 operations per phase."
      )
    }
    guard parallelWorkerCount >= 2 else {
      throw QA03Error("Parallel concurrency stress requires at least 2 workers.")
    }

    let context = try Context()
    let taskSingle = try await runTaskPhase(
      name: "swift-task-single-worker",
      context: context,
      operationCount: operationsPerPhase,
      workerCount: 1
    )
    let taskParallel = try await runTaskPhase(
      name: "swift-task-parallel",
      context: context,
      operationCount: operationsPerPhase,
      workerCount: parallelWorkerCount
    )
    let nativeParallel = try runDispatchPhase(
      name: "native-thread-parallel",
      context: context,
      operationCount: operationsPerPhase,
      workerCount: parallelWorkerCount
    )

    guard
      taskSingle.resultDigest == taskParallel.resultDigest,
      taskSingle.resultDigest == nativeParallel.resultDigest
    else {
      throw QA03Error(
        "Concurrency phases produced different result digests."
      )
    }

    return QA03ConcurrencyReport(
      schemaVersion: 1,
      command: "concurrency",
      commit: commit,
      requestedOperationsPerPhase: operationsPerPhase,
      parallelWorkerCount: parallelWorkerCount,
      phases: [taskSingle, taskParallel, nativeParallel]
    )
  }

  private static func runTaskPhase(
    name: String,
    context: Context,
    operationCount: Int,
    workerCount: Int
  ) async throws -> QA03ConcurrencyReport.Phase {
    let clock = ContinuousClock()
    let start = clock.now
    let combined = try await withThrowingTaskGroup(
      of: PartialResult.self
    ) { group in
      for worker in 0..<workerCount {
        group.addTask {
          try partialResult(
            context: context,
            operationCount: operationCount,
            worker: worker,
            workerCount: workerCount
          )
        }
      }

      var combined = PartialResult()
      for try await partial in group {
        combined.combine(partial)
      }
      return combined
    }
    let elapsed = start.duration(to: clock.now)
    guard combined.completedOperations == operationCount else {
      throw QA03Error(
        "\(name) completed \(combined.completedOperations) "
          + "of \(operationCount) operations."
      )
    }

    return QA03ConcurrencyReport.Phase(
      name: name,
      workerCount: workerCount,
      completedOperations: combined.completedOperations,
      elapsedNanoseconds: elapsed.qa03Nanoseconds,
      resultDigest: qa03Hex(combined.digest)
    )
  }

  private static func runDispatchPhase(
    name: String,
    context: Context,
    operationCount: Int,
    workerCount: Int
  ) throws -> QA03ConcurrencyReport.Phase {
    let results = LockedResults()
    let elapsed = ContinuousClock().measure {
      DispatchQueue.concurrentPerform(iterations: workerCount) { worker in
        do {
          let partial = try partialResult(
            context: context,
            operationCount: operationCount,
            worker: worker,
            workerCount: workerCount
          )
          results.append(partial)
        } catch {
          results.append(error)
        }
      }
    }
    if let error = results.firstError {
      throw error
    }
    let combined = results.combined
    guard combined.completedOperations == operationCount else {
      throw QA03Error(
        "\(name) completed \(combined.completedOperations) "
          + "of \(operationCount) operations."
      )
    }

    return QA03ConcurrencyReport.Phase(
      name: name,
      workerCount: workerCount,
      completedOperations: combined.completedOperations,
      elapsedNanoseconds: elapsed.qa03Nanoseconds,
      resultDigest: qa03Hex(combined.digest)
    )
  }

  private static func partialResult(
    context: Context,
    operationCount: Int,
    worker: Int,
    workerCount: Int
  ) throws -> PartialResult {
    var result = PartialResult()
    var index = worker
    while index < operationCount {
      let operationDigest = try context.perform(operationAt: index)
      result.completedOperations += 1
      result.digest &+=
        operationDigest
        &+ UInt64(index) &* 0x9E37_79B9_7F4A_7C15
      index += workerCount
    }
    return result
  }
}

private struct PartialResult: Sendable {
  var completedOperations = 0
  var digest: UInt64 = 0

  mutating func combine(_ other: Self) {
    completedOperations += other.completedOperations
    digest &+= other.digest
  }
}

private final class LockedResults: @unchecked Sendable {
  private let lock = NSLock()
  private var results: [PartialResult] = []
  private var errors: [Error] = []

  func append(_ result: PartialResult) {
    lock.withLock {
      results.append(result)
    }
  }

  func append(_ error: Error) {
    lock.withLock {
      errors.append(error)
    }
  }

  var firstError: Error? {
    lock.withLock { errors.first }
  }

  var combined: PartialResult {
    lock.withLock {
      results.reduce(into: PartialResult()) {
        $0.combine($1)
      }
    }
  }
}

private struct Context: Sendable {
  let template: URITemplate
  let equivalentTemplate: URITemplate
  let parameters: [String: URIVariableValue]
  let expectedExpansion: String
  let expectedVariableNames: Set<String>
  let prefixFailureTemplate: URITemplate
  let prefixFailureParameters: [String: URIVariableValue]
  let invalidURLTemplate: URITemplate
  let value: URIVariableValue

  init() throws {
    template = try URITemplate(
      parsing: "https://example.com{/segments*}{?query}"
    )
    equivalentTemplate = try URITemplate(
      parsing: "https://example.com{/segments*}{?query}"
    )
    parameters = [
      "segments": .list(["users", "42"]),
      "query": .text("uri templates"),
    ]
    expectedExpansion =
      "https://example.com/users/42?query=uri%20templates"
    expectedVariableNames = ["segments", "query"]
    prefixFailureTemplate = try URITemplate(parsing: "{items:1}")
    prefixFailureParameters = [
      "items": .list(["alpha", "beta"])
    ]
    invalidURLTemplate = try URITemplate(parsing: "https://[")
    value = try .association([
      ("sort", "updated"),
      ("limit", "20"),
    ])
  }

  func perform(operationAt index: Int) throws -> UInt64 {
    switch index % 10 {
    case 0:
      let output = try template.evaluateAsString(parameters: parameters)
      guard output == expectedExpansion else {
        throw QA03Error("Concurrent expansion mismatch.")
      }
      return qa03StableDigest(output)

    case 1:
      guard template.variableNames == expectedVariableNames else {
        throw QA03Error("Concurrent variable-name mismatch.")
      }
      return UInt64(template.variableNames.count)

    case 2:
      guard
        template.templateRepresentation
          == equivalentTemplate.templateRepresentation
      else {
        throw QA03Error("Concurrent source-representation mismatch.")
      }
      return qa03StableDigest(template.templateRepresentation)

    case 3:
      guard
        template == equivalentTemplate,
        template.hashValue == equivalentTemplate.hashValue
      else {
        throw QA03Error("Concurrent equality/hash law failure.")
      }
      return 0xE0A1

    case 4:
      let data = try JSONEncoder().encode(template)
      let decoded = try JSONDecoder().decode(
        URITemplate.self,
        from: data
      )
      guard decoded == template else {
        throw QA03Error("Concurrent template Codable mismatch.")
      }
      return UInt64(data.count)

    case 5:
      do {
        _ = try prefixFailureTemplate.evaluateAsString(
          parameters: prefixFailureParameters
        )
        throw QA03Error("Composite prefix unexpectedly expanded.")
      } catch let error as URITemplate.EvaluationError {
        guard error.kind == .prefixModifierNotApplicable else {
          throw QA03Error("Unexpected composite-prefix error kind.")
        }
        return 0xC0DE
      }

    case 6:
      let parsed = try URITemplate(
        parsing: "https://example.com/items/\(index){?value}"
      )
      guard parsed.variableNames == ["value"] else {
        throw QA03Error("Concurrent independent parse mismatch.")
      }
      return qa03StableDigest(parsed.templateRepresentation)

    case 7:
      do {
        _ = try invalidURLTemplate.evaluate(parameters: [:])
        throw QA03Error("Invalid URL unexpectedly converted.")
      } catch let error as URITemplate.EvaluationError {
        guard error.kind == .invalidURL else {
          throw QA03Error("Unexpected URL-conversion error kind.")
        }
        return 0xBAD0
      }

    case 8:
      let copiedValue = value
      guard
        copiedValue == value,
        copiedValue.hashValue == value.hashValue,
        copiedValue.valueType == .association,
        copiedValue.isAssociationValue,
        copiedValue.count == 2
      else {
        throw QA03Error("Concurrent variable-value semantic mismatch.")
      }
      return UInt64(copiedValue.count)

    default:
      let url = try template.evaluate(parameters: parameters)
      guard url.absoluteString == expectedExpansion else {
        throw QA03Error("Concurrent URL expansion mismatch.")
      }
      return qa03StableDigest(url.absoluteString)
    }
  }
}
