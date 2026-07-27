import Darwin
import Foundation
import HDXLURITemplateQA03Support

@main
struct HDXLURITemplateQA03 {

  static func main() async {
    let command = CommandLine.arguments.dropFirst().first ?? "help"
    do {
      var arguments = try QA03Arguments(
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
      try arguments.requireNoUnusedOptions()
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
