import Darwin
import Foundation
import HDXLURITemplateQA03Support

@main
struct HDXLURITemplateQA03 {

  static func main() async {
    let command = CommandLine.arguments.dropFirst().first ?? "help"
    do {
      let arguments = try Arguments(
        Array(CommandLine.arguments.dropFirst(2))
      )
      let commit =
        ProcessInfo.processInfo.environment["QA03_COMMIT"]
        ?? "local-uncommitted"

      switch command {
      case "fuzz":
        let seed = try arguments.seed(named: "--seed")
        let iterations = try arguments.integer(
          named: "--iterations",
          minimum: 1
        )
        let fixtureDirectory = arguments.optionalURL(named: "--fixtures")
        let replayIndex = try arguments.optionalInteger(
          named: "--replay-index",
          minimum: 0
        )
        let injectedFailureIndex = try arguments.optionalInteger(
          named: "--inject-failure-at",
          minimum: 0
        )
        let report = try QA03FuzzRunner.run(
          configuration: QA03FuzzConfiguration(
            seed: seed,
            iterations: iterations,
            fixtureDirectory: fixtureDirectory,
            replayIndex: replayIndex,
            injectedFailureIndex: injectedFailureIndex
          ),
          commit: commit,
          progress: writeProgress
        )
        try writeJSON(report)

      case "concurrency":
        let operations = try arguments.integer(
          named: "--operations",
          minimum: 100_000
        )
        let workers =
          try arguments.optionalInteger(
            named: "--workers",
            minimum: 2
          ) ?? max(2, ProcessInfo.processInfo.activeProcessorCount)
        let report = try await QA03ConcurrencyRunner.run(
          operationsPerPhase: operations,
          parallelWorkerCount: workers,
          commit: commit
        )
        try writeJSON(report)

      case "scaling":
        let baselineURL = try arguments.url(named: "--baseline")
        let sampleCount =
          try arguments.optionalInteger(
            named: "--samples",
            minimum: 3
          ) ?? 5
        let baseline = try QA03ScalingBaseline.load(from: baselineURL)
        let report = try QA03ScalingRunner.run(
          baseline: baseline,
          sampleCount: sampleCount,
          commit: commit
        )
        try writeJSON(report)

      case "verify-scaling-detector":
        let analysis = try QA03ScalingRunner.verifyQuadraticDetector()
        try writeJSON(analysis)

      case "help", "--help", "-h":
        print(usage)

      default:
        throw QA03Error("Unknown QA-03 command \(command).\n\(usage)")
      }
    } catch {
      let failure = FailureReport(
        schemaVersion: 1,
        command: command,
        status: "failed",
        error: String(describing: error)
      )
      try? writeJSON(failure, to: .standardError)
      exit(EXIT_FAILURE)
    }
  }
}

private struct Arguments {
  private var values: [String: String] = [:]

  init(_ rawArguments: [String]) throws {
    guard rawArguments.count.isMultiple(of: 2) else {
      throw QA03Error("Every QA-03 option requires one value.")
    }
    var index = 0
    while index < rawArguments.count {
      let name = rawArguments[index]
      let value = rawArguments[index + 1]
      guard name.hasPrefix("--"), values[name] == nil else {
        throw QA03Error("Invalid or duplicate QA-03 option \(name).")
      }
      values[name] = value
      index += 2
    }
  }

  func seed(named name: String) throws -> UInt64 {
    let rawValue = try required(named: name)
    let digits =
      rawValue.hasPrefix("0x") || rawValue.hasPrefix("0X")
      ? String(rawValue.dropFirst(2))
      : rawValue
    guard let value = UInt64(digits, radix: 16) else {
      throw QA03Error("\(name) must be a hexadecimal UInt64.")
    }
    return value
  }

  func integer(named name: String, minimum: Int) throws -> Int {
    guard
      let value = Int(try required(named: name)),
      value >= minimum
    else {
      throw QA03Error("\(name) must be an integer at least \(minimum).")
    }
    return value
  }

  func optionalInteger(named name: String, minimum: Int) throws -> Int? {
    guard values[name] != nil else {
      return nil
    }
    return try integer(named: name, minimum: minimum)
  }

  func url(named name: String) throws -> URL {
    URL(fileURLWithPath: try required(named: name))
  }

  func optionalURL(named name: String) -> URL? {
    values[name].map(URL.init(fileURLWithPath:))
  }

  private func required(named name: String) throws -> String {
    guard let value = values[name], !value.isEmpty else {
      throw QA03Error("Missing required option \(name).")
    }
    return value
  }
}

private struct FailureReport: Encodable {
  let schemaVersion: Int
  let command: String
  let status: String
  let error: String
}

private func writeJSON<T: Encodable>(
  _ value: T,
  to handle: FileHandle = .standardOutput
) throws {
  let encoder = JSONEncoder()
  encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
  var data = try encoder.encode(value)
  data.append(0x0A)
  try handle.write(contentsOf: data)
}

private func writeProgress(_ message: String) {
  var data = Data(message.utf8)
  data.append(0x0A)
  try? FileHandle.standardError.write(contentsOf: data)
}

private let usage = """
  HDXLURITemplateQA03 fuzz \
    --seed HEX --iterations N [--fixtures PATH] \
    [--replay-index N] [--inject-failure-at N]
  HDXLURITemplateQA03 concurrency --operations N [--workers N]
  HDXLURITemplateQA03 scaling --baseline PATH [--samples ODD_N]
  HDXLURITemplateQA03 verify-scaling-detector
  """
