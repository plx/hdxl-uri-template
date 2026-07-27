import Darwin
import Dispatch
import Foundation
import HDXLURITemplate

@main
private enum ARCH01Benchmark {

  static func main() throws {
    let arguments = try Arguments.parse(CommandLine.arguments)
    let report = try run(arguments: arguments)
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
    FileHandle.standardOutput.write(try encoder.encode(report))
    FileHandle.standardOutput.write(Data([0x0A]))
  }

  private static func run(
    arguments: Arguments
  ) throws -> Report {
    let source = "https://example.com/é{/segments*}{?query,lang,query}"
    let template = try URITemplate(parsing: source)
    let equivalentTemplate = try URITemplate(parsing: source)
    let parameters: [String: URIVariableValue] = [
      "segments": .list(["users", "42"]),
      "query": .text("uri templates"),
      "lang": .text("swift"),
    ]
    let expectedExpansion =
      "https://example.com/%C3%A9/users/42?query=uri%20templates"
      + "&lang=swift&query=uri%20templates"

    let workloads = try [
      measure(
        id: "parse",
        iterations: 20_000,
        workerCount: 1,
        sampleCount: arguments.sampleCount
      ) {
        var digest: UInt64 = 0
        for _ in 0..<20_000 {
          let parsed = try URITemplate(parsing: source)
          digest &+= UInt64(parsed.templateRepresentation.utf8.count)
        }
        return digest
      },
      measure(
        id: "copy",
        iterations: 2_000_000,
        workerCount: 1,
        sampleCount: arguments.sampleCount
      ) {
        var ring: [URITemplate] = []
        ring.reserveCapacity(1_024)
        var digest: UInt64 = 0
        for index in 0..<2_000_000 {
          ring.append(template)
          if ring.count == 1_024 {
            digest &+= UInt64(
              ring[index & 1_023].templateRepresentation.utf8.count
            )
            ring.removeAll(keepingCapacity: true)
          }
        }
        digest &+= UInt64(ring.count)
        return digest
      },
      measureMetadata(
        template: template,
        equivalentTemplate: equivalentTemplate,
        operations: 2_000_000,
        workerCount: 1,
        sampleCount: arguments.sampleCount
      ),
      measureMetadata(
        template: template,
        equivalentTemplate: equivalentTemplate,
        operations: 2_000_000,
        workerCount: 2,
        sampleCount: arguments.sampleCount
      ),
      measureMetadata(
        template: template,
        equivalentTemplate: equivalentTemplate,
        operations: 2_000_000,
        workerCount: 4,
        sampleCount: arguments.sampleCount
      ),
      measureMetadata(
        template: template,
        equivalentTemplate: equivalentTemplate,
        operations: 2_000_000,
        workerCount: 8,
        sampleCount: arguments.sampleCount
      ),
      measure(
        id: "expansion",
        iterations: 100_000,
        workerCount: 1,
        sampleCount: arguments.sampleCount
      ) {
        var digest: UInt64 = 0
        for _ in 0..<100_000 {
          let expansion = try template.evaluateAsString(parameters: parameters)
          guard expansion == expectedExpansion else {
            throw BenchmarkError("Expansion result drifted.")
          }
          digest &+= stableDigest(expansion)
        }
        return digest
      },
    ]

    return Report(
      schemaVersion: 1,
      label: arguments.label,
      commit: arguments.commit,
      sampleCount: arguments.sampleCount,
      swiftVersion: swiftVersion(),
      architecture: architecture(),
      logicalCoreCount: ProcessInfo.processInfo.activeProcessorCount,
      templateSizeBytes: MemoryLayout<URITemplate>.size,
      templateStrideBytes: MemoryLayout<URITemplate>.stride,
      workloads: workloads,
      retainedMemory: try retainedMemoryMeasurements()
    )
  }

  private static func measureMetadata(
    template: URITemplate,
    equivalentTemplate: URITemplate,
    operations: Int,
    workerCount: Int,
    sampleCount: Int
  ) throws -> Workload {
    try measure(
      id: "warm-metadata-\(workerCount)-worker",
      iterations: operations,
      workerCount: workerCount,
      sampleCount: sampleCount
    ) {
      let accumulator = ParallelAccumulator()
      DispatchQueue.concurrentPerform(iterations: workerCount) { worker in
        var digest: UInt64 = 0
        var index = worker
        while index < operations {
          let names = template.variableNames
          digest &+= UInt64(names.count)
          digest &+= UInt64(template.templateRepresentation.utf8.count)
          digest &+= template == equivalentTemplate ? 1 : 0
          index += workerCount
        }
        accumulator.combine(digest)
      }
      return accumulator.value
    }
  }

  private static func measure(
    id: String,
    iterations: Int,
    workerCount: Int,
    sampleCount: Int,
    operation: () throws -> UInt64
  ) throws -> Workload {
    _ = try operation()
    var rawNanoseconds: [UInt64] = []
    var expectedDigest: UInt64?
    for _ in 0..<sampleCount {
      let start = ContinuousClock.now
      let digest = try operation()
      let elapsed = start.duration(to: .now).nanoseconds
      if let expectedDigest {
        guard digest == expectedDigest else {
          throw BenchmarkError("\(id) produced a nondeterministic digest.")
        }
      } else {
        expectedDigest = digest
      }
      rawNanoseconds.append(max(1, elapsed))
    }
    let medianNanoseconds = rawNanoseconds.sorted()[sampleCount / 2]
    return Workload(
      id: id,
      iterations: iterations,
      workerCount: workerCount,
      rawNanoseconds: rawNanoseconds,
      medianNanoseconds: medianNanoseconds,
      medianNanosecondsPerOperation:
        Double(medianNanoseconds) / Double(iterations),
      resultDigest: hex(expectedDigest ?? 0)
    )
  }

  private static func retainedMemoryMeasurements() throws
    -> [RetainedMemory]
  {
    let copyTemplate = try URITemplate(
      parsing: "https://example.com{/segments*}{?query,lang}"
    )
    let copyBefore = MemorySnapshot.current
    let copies = Array(repeating: copyTemplate, count: 100_000)
    let copyAfter = MemorySnapshot.current
    let copyDigest = copies.reduce(into: UInt64(0)) {
      $0 &+= UInt64($1.templateRepresentation.utf8.count)
    }

    let parseBefore = MemorySnapshot.current
    var parsedTemplates: [URITemplate] = []
    parsedTemplates.reserveCapacity(5_000)
    for index in 0..<5_000 {
      parsedTemplates.append(
        try URITemplate(
          parsing: "https://example.com/users/\(index){/segments*}{?query,lang}"
        )
      )
    }
    let parseAfter = MemorySnapshot.current
    let parseDigest = parsedTemplates.reduce(into: UInt64(0)) {
      $0 &+= UInt64($1.templateRepresentation.utf8.count)
    }

    return [
      RetainedMemory(
        id: "100000-copies",
        itemCount: copies.count,
        blocksInUseDelta: copyAfter.blocksInUse - copyBefore.blocksInUse,
        bytesInUseDelta: copyAfter.bytesInUse - copyBefore.bytesInUse,
        maximumBytesInUseDelta:
          copyAfter.maximumBytesInUse - copyBefore.maximumBytesInUse,
        resultDigest: hex(copyDigest)
      ),
      RetainedMemory(
        id: "5000-unique-parses",
        itemCount: parsedTemplates.count,
        blocksInUseDelta: parseAfter.blocksInUse - parseBefore.blocksInUse,
        bytesInUseDelta: parseAfter.bytesInUse - parseBefore.bytesInUse,
        maximumBytesInUseDelta:
          parseAfter.maximumBytesInUse - parseBefore.maximumBytesInUse,
        resultDigest: hex(parseDigest)
      ),
    ]
  }

  private static func swiftVersion() -> String {
    ProcessInfo.processInfo.environment["ARCH01_SWIFT_VERSION"] ?? "unrecorded"
  }

  private static func architecture() -> String {
    #if arch(arm64)
      "arm64"
    #elseif arch(x86_64)
      "x86_64"
    #else
      "unknown"
    #endif
  }
}

private struct Arguments {
  let label: String
  let commit: String
  let sampleCount: Int

  static func parse(_ arguments: [String]) throws -> Self {
    var label: String?
    var commit: String?
    var sampleCount = 7
    var index = 1
    while index < arguments.count {
      switch arguments[index] {
      case "--label":
        index += 1
        label = try value(at: index, in: arguments, for: "--label")
      case "--commit":
        index += 1
        commit = try value(at: index, in: arguments, for: "--commit")
      case "--samples":
        index += 1
        let value = try value(at: index, in: arguments, for: "--samples")
        guard let parsed = Int(value) else {
          throw BenchmarkError("--samples must be an integer.")
        }
        sampleCount = parsed
      default:
        throw BenchmarkError("Unknown argument \(arguments[index]).")
      }
      index += 1
    }
    guard let label, label.isEmpty == false else {
      throw BenchmarkError("--label is required.")
    }
    guard let commit, commit.isEmpty == false else {
      throw BenchmarkError("--commit is required.")
    }
    guard sampleCount >= 3, sampleCount.isMultiple(of: 2) == false else {
      throw BenchmarkError("--samples must be an odd integer at least 3.")
    }
    return Self(label: label, commit: commit, sampleCount: sampleCount)
  }

  private static func value(
    at index: Int,
    in arguments: [String],
    for option: String
  ) throws -> String {
    guard arguments.indices.contains(index) else {
      throw BenchmarkError("\(option) requires a value.")
    }
    return arguments[index]
  }
}

private struct Report: Codable {
  let schemaVersion: Int
  let label: String
  let commit: String
  let sampleCount: Int
  let swiftVersion: String
  let architecture: String
  let logicalCoreCount: Int
  let templateSizeBytes: Int
  let templateStrideBytes: Int
  let workloads: [Workload]
  let retainedMemory: [RetainedMemory]
}

private struct Workload: Codable {
  let id: String
  let iterations: Int
  let workerCount: Int
  let rawNanoseconds: [UInt64]
  let medianNanoseconds: UInt64
  let medianNanosecondsPerOperation: Double
  let resultDigest: String
}

private struct RetainedMemory: Codable {
  let id: String
  let itemCount: Int
  let blocksInUseDelta: Int64
  let bytesInUseDelta: Int64
  let maximumBytesInUseDelta: Int64
  let resultDigest: String
}

private struct MemorySnapshot {
  let blocksInUse: Int64
  let bytesInUse: Int64
  let maximumBytesInUse: Int64

  static var current: Self {
    var statistics = malloc_statistics_t()
    malloc_zone_statistics(malloc_default_zone(), &statistics)
    return Self(
      blocksInUse: Int64(statistics.blocks_in_use),
      bytesInUse: Int64(statistics.size_in_use),
      maximumBytesInUse: Int64(statistics.max_size_in_use)
    )
  }
}

private final class ParallelAccumulator: @unchecked Sendable {
  private let lock = NSLock()
  private var storage: UInt64 = 0

  func combine(_ value: UInt64) {
    lock.withLock {
      storage &+= value
    }
  }

  var value: UInt64 {
    lock.withLock { storage }
  }
}

private struct BenchmarkError: Error, CustomStringConvertible {
  let description: String

  init(_ description: String) {
    self.description = description
  }
}

private func stableDigest(_ value: String) -> UInt64 {
  value.utf8.reduce(into: UInt64(0xCBF2_9CE4_8422_2325)) {
    $0 ^= UInt64($1)
    $0 &*= 0x0000_0100_0000_01B3
  }
}

private func hex(_ value: UInt64) -> String {
  String(format: "%016llx", value)
}

extension Duration {
  fileprivate var nanoseconds: UInt64 {
    let components = self.components
    let seconds = UInt64(max(0, components.seconds))
    let attoseconds = UInt64(max(0, components.attoseconds))
    return seconds &* 1_000_000_000 + attoseconds / 1_000_000_000
  }
}
