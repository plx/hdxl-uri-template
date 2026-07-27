#!/usr/bin/env swift
import Foundation

private struct Arguments {
  let label: String
  let commit: String
  let sampleCount: Int

  static func parse(_ values: [String]) throws -> Self {
    var label: String?
    var commit: String?
    var sampleCount = 5
    var index = 1

    while index < values.count {
      switch values[index] {
      case "--label":
        index += 1
        label = try value(at: index, in: values, for: "--label")
      case "--commit":
        index += 1
        commit = try value(at: index, in: values, for: "--commit")
      case "--samples":
        index += 1
        let value = try value(at: index, in: values, for: "--samples")
        guard let parsed = Int(value) else {
          throw MeasurementError("--samples must be an integer.")
        }
        sampleCount = parsed
      default:
        throw MeasurementError("Unknown argument \(values[index]).")
      }
      index += 1
    }

    guard let label, label.isEmpty == false else {
      throw MeasurementError("--label is required.")
    }
    guard let commit, commit.isEmpty == false else {
      throw MeasurementError("--commit is required.")
    }
    guard sampleCount >= 3, sampleCount.isMultiple(of: 2) == false else {
      throw MeasurementError("--samples must be an odd integer at least 3.")
    }
    return Self(label: label, commit: commit, sampleCount: sampleCount)
  }

  private static func value(
    at index: Int,
    in values: [String],
    for option: String
  ) throws -> String {
    guard values.indices.contains(index) else {
      throw MeasurementError("\(option) requires a value.")
    }
    return values[index]
  }
}

private struct Report: Codable {
  let schemaVersion: Int
  let label: String
  let commit: String
  let sampleCount: Int
  let swiftVersion: String
  let xcodeVersion: String
  let architecture: String
  let logicalCoreCount: Int
  let cleanLibraryBuild: Timing
  let cleanPublicConsumerBuild: Timing
  let artifacts: Artifacts
  let runtime: ARCH02RuntimeReport
}

private struct Timing: Codable {
  let rawNanoseconds: [UInt64]
  let medianNanoseconds: UInt64
  let medianSeconds: Double
}

private struct Artifacts: Codable {
  let swiftModuleBytes: Int
  let swiftSourceInfoBytes: Int
  let textualInterfaceBytes: Int
  let textualInterfaceCounts: AnnotationCounts
  let publicConsumerExecutableBytes: Int
  let benchmarkExecutableBytes: Int
}

private struct AnnotationCounts: Codable {
  let inlinable: Int
  let usableFromInline: Int
  let alwaysInline: Int
  let alwaysEmitIntoClient: Int
}

private struct ARCH02RuntimeReport: Codable {
  let schemaVersion: Int
  let label: String
  let commit: String
  let sampleCount: Int
  let swiftVersion: String
  let architecture: String
  let logicalCoreCount: Int
  let workloads: [RuntimeWorkload]
}

private struct RuntimeWorkload: Codable {
  let id: String
  let iterations: Int
  let rawNanoseconds: [UInt64]
  let medianNanoseconds: UInt64
  let medianNanosecondsPerOperation: Double
  let resultDigest: String
}

private struct MeasurementError: Error, CustomStringConvertible {
  let description: String

  init(_ description: String) {
    self.description = description
  }
}

private func run(
  _ arguments: [String],
  in directory: URL,
  captureOutput: Bool = false
) throws -> Data {
  let process = Process()
  process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
  process.arguments = arguments
  process.currentDirectoryURL = directory
  let output = Pipe()
  if captureOutput {
    process.standardOutput = output
  } else {
    process.standardOutput = FileHandle.nullDevice
  }
  process.standardError = FileHandle.nullDevice
  try process.run()
  let data =
    captureOutput
    ? output.fileHandleForReading.readDataToEndOfFile()
    : Data()
  process.waitUntilExit()
  guard process.terminationReason == .exit, process.terminationStatus == 0 else {
    throw MeasurementError(
      "Command failed with status \(process.terminationStatus): "
        + arguments.joined(separator: " ")
    )
  }
  return data
}

private func capturedString(
  _ arguments: [String],
  in directory: URL
) throws -> String {
  let data = try run(arguments, in: directory, captureOutput: true)
  guard let value = String(data: data, encoding: .utf8) else {
    throw MeasurementError(
      "Command emitted non-UTF-8 output: \(arguments.joined(separator: " "))"
    )
  }
  return value.trimmingCharacters(in: .whitespacesAndNewlines)
}

private func measure(
  sampleCount: Int,
  operation: (Int) throws -> Void
) throws -> Timing {
  var rawNanoseconds: [UInt64] = []
  for sample in 0..<sampleCount {
    let start = ContinuousClock.now
    try operation(sample)
    rawNanoseconds.append(
      max(1, start.duration(to: .now).nanoseconds)
    )
  }
  let median = rawNanoseconds.sorted()[sampleCount / 2]
  return Timing(
    rawNanoseconds: rawNanoseconds,
    medianNanoseconds: median,
    medianSeconds: Double(median) / 1_000_000_000
  )
}

private func oneFile(
  named filename: String,
  beneath root: URL
) throws -> URL {
  guard
    let enumerator = FileManager.default.enumerator(
      at: root,
      includingPropertiesForKeys: [.isRegularFileKey],
      options: [.skipsHiddenFiles]
    )
  else {
    throw MeasurementError("Unable to enumerate \(root.path).")
  }
  var matches: [URL] = []
  for case let candidate as URL in enumerator
  where candidate.lastPathComponent == filename {
    let values = try candidate.resourceValues(
      forKeys: [.isRegularFileKey]
    )
    if values.isRegularFile == true {
      matches.append(candidate)
    }
  }
  guard matches.count == 1, let match = matches.first else {
    throw MeasurementError(
      "Expected one \(filename) beneath \(root.path), found \(matches.count)."
    )
  }
  return match
}

private func oneExecutable(
  named filename: String,
  beneath root: URL
) throws -> URL {
  guard
    let enumerator = FileManager.default.enumerator(
      at: root,
      includingPropertiesForKeys: [
        .isExecutableKey,
        .isRegularFileKey,
      ],
      options: [.skipsHiddenFiles]
    )
  else {
    throw MeasurementError("Unable to enumerate \(root.path).")
  }
  var matches: [URL] = []
  for case let candidate as URL in enumerator
  where candidate.lastPathComponent == filename {
    let values = try candidate.resourceValues(
      forKeys: [.isExecutableKey, .isRegularFileKey]
    )
    if values.isRegularFile == true, values.isExecutable == true {
      matches.append(candidate)
    }
  }
  guard matches.count == 1, let match = matches.first else {
    throw MeasurementError(
      "Expected one executable \(filename) beneath \(root.path), "
        + "found \(matches.count)."
    )
  }
  return match
}

private func oneReleaseProductExecutable(
  named filename: String,
  beneath root: URL
) throws -> URL {
  let productMarker = "/out/Products/Release/"
  guard
    let enumerator = FileManager.default.enumerator(
      at: root,
      includingPropertiesForKeys: [
        .isExecutableKey,
        .isRegularFileKey,
      ],
      options: [.skipsHiddenFiles]
    )
  else {
    throw MeasurementError("Unable to enumerate \(root.path).")
  }
  var matches: [URL] = []
  for case let candidate as URL in enumerator
  where candidate.lastPathComponent == filename
    && candidate.path.contains(productMarker)
  {
    let values = try candidate.resourceValues(
      forKeys: [.isExecutableKey, .isRegularFileKey]
    )
    if values.isRegularFile == true, values.isExecutable == true {
      matches.append(candidate)
    }
  }
  guard matches.count == 1, let match = matches.first else {
    throw MeasurementError(
      "Expected one Release product \(filename) beneath \(root.path), "
        + "found \(matches.count)."
    )
  }
  return match
}

private func fileSize(_ url: URL) throws -> Int {
  let attributes = try FileManager.default.attributesOfItem(
    atPath: url.path
  )
  guard let size = attributes[.size] as? NSNumber else {
    throw MeasurementError("Unable to read the size of \(url.path).")
  }
  return size.intValue
}

private func occurrences(of needle: String, in value: String) -> Int {
  value.components(separatedBy: needle).count - 1
}

private func main() throws {
  let arguments = try Arguments.parse(CommandLine.arguments)
  let repositoryRoot = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()
    .deletingLastPathComponent()
    .standardizedFileURL
  let actualCommit = try capturedString(
    ["git", "rev-parse", "HEAD"],
    in: repositoryRoot
  )
  guard actualCommit == arguments.commit else {
    throw MeasurementError(
      "Expected commit \(arguments.commit), found \(actualCommit)."
    )
  }
  let trackedStatus = try capturedString(
    ["git", "status", "--porcelain", "--untracked-files=no"],
    in: repositoryRoot
  )
  guard trackedStatus.isEmpty else {
    throw MeasurementError(
      "ARCH-02 measurements require no tracked worktree changes."
    )
  }

  let scratchRoot = FileManager.default.temporaryDirectory
    .appendingPathComponent(
      "hdxl-arch02-\(UUID().uuidString)",
      isDirectory: true
    )
  try FileManager.default.createDirectory(
    at: scratchRoot,
    withIntermediateDirectories: true
  )
  defer {
    try? FileManager.default.removeItem(at: scratchRoot)
  }

  let libraryTiming = try measure(sampleCount: arguments.sampleCount) {
    sample in
    _ = try run(
      [
        "xcrun", "swift", "build",
        "-c", "release",
        "--target", "HDXLURITemplate",
        "--scratch-path",
        scratchRoot.appendingPathComponent("library-\(sample)").path,
      ],
      in: repositoryRoot
    )
  }

  let consumerRoot =
    repositoryRoot
    .appendingPathComponent("Tests")
    .appendingPathComponent("PublicAPIConsumer")
  var finalConsumerScratch: URL?
  let consumerTiming = try measure(sampleCount: arguments.sampleCount) {
    sample in
    let scratch =
      scratchRoot
      .appendingPathComponent("consumer-\(sample)")
    finalConsumerScratch = scratch
    _ = try run(
      [
        "xcrun", "swift", "build",
        "--package-path", consumerRoot.path,
        "-c", "release",
        "--scratch-path", scratch.path,
        "--build-system", "swiftbuild",
      ],
      in: consumerRoot
    )
  }
  guard let finalConsumerScratch else {
    throw MeasurementError("No public-consumer build was measured.")
  }

  let interfaceScratch = scratchRoot.appendingPathComponent("interface")
  _ = try run(
    [
      "xcrun", "swift", "build",
      "-c", "release",
      "--target", "HDXLURITemplate",
      "--scratch-path", interfaceScratch.path,
      "-Xswiftc", "-emit-module-interface",
    ],
    in: repositoryRoot
  )
  let swiftModule = try oneFile(
    named: "HDXLURITemplate.swiftmodule",
    beneath: interfaceScratch
  )
  let swiftSourceInfo = try oneFile(
    named: "HDXLURITemplate.swiftsourceinfo",
    beneath: interfaceScratch
  )
  let textualInterface = try oneFile(
    named: "HDXLURITemplate.swiftinterface",
    beneath: interfaceScratch
  )
  let textualInterfaceSource = try String(
    contentsOf: textualInterface,
    encoding: .utf8
  )

  let benchmarkScratch = scratchRoot.appendingPathComponent("benchmark")
  _ = try run(
    [
      "xcrun", "swift", "build",
      "-c", "release",
      "--product", "HDXLURITemplateARCH02Benchmark",
      "--scratch-path", benchmarkScratch.path,
    ],
    in: repositoryRoot
  )
  let benchmarkExecutable = try oneExecutable(
    named: "HDXLURITemplateARCH02Benchmark",
    beneath: benchmarkScratch
  )
  let runtimeData = try run(
    [
      benchmarkExecutable.path,
      "--label", arguments.label,
      "--commit", arguments.commit,
      "--samples", String(arguments.sampleCount),
    ],
    in: repositoryRoot,
    captureOutput: true
  )
  let runtime = try JSONDecoder().decode(
    ARCH02RuntimeReport.self,
    from: runtimeData
  )
  let consumerExecutable = try oneReleaseProductExecutable(
    named: "HDXLURITemplatePublicAPIConsumer",
    beneath: finalConsumerScratch
  )

  let swiftVersion =
    try capturedString(
      ["xcrun", "swift", "--version"],
      in: repositoryRoot
    ).split(separator: "\n").first.map(String.init) ?? "unknown"
  let xcodeVersion = try capturedString(
    ["xcodebuild", "-version"],
    in: repositoryRoot
  ).replacingOccurrences(of: "\n", with: "; ")
  let report = Report(
    schemaVersion: 1,
    label: arguments.label,
    commit: arguments.commit,
    sampleCount: arguments.sampleCount,
    swiftVersion: swiftVersion,
    xcodeVersion: xcodeVersion,
    architecture: runtime.architecture,
    logicalCoreCount: runtime.logicalCoreCount,
    cleanLibraryBuild: libraryTiming,
    cleanPublicConsumerBuild: consumerTiming,
    artifacts: Artifacts(
      swiftModuleBytes: try fileSize(swiftModule),
      swiftSourceInfoBytes: try fileSize(swiftSourceInfo),
      textualInterfaceBytes: try fileSize(textualInterface),
      textualInterfaceCounts: AnnotationCounts(
        inlinable: occurrences(
          of: "@inlinable",
          in: textualInterfaceSource
        ),
        usableFromInline: occurrences(
          of: "@usableFromInline",
          in: textualInterfaceSource
        ),
        alwaysInline: occurrences(
          of: "@inline(__always)",
          in: textualInterfaceSource
        ),
        alwaysEmitIntoClient: occurrences(
          of: "@_alwaysEmitIntoClient",
          in: textualInterfaceSource
        )
      ),
      publicConsumerExecutableBytes: try fileSize(consumerExecutable),
      benchmarkExecutableBytes: try fileSize(benchmarkExecutable)
    ),
    runtime: runtime
  )
  let encoder = JSONEncoder()
  encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
  FileHandle.standardOutput.write(try encoder.encode(report))
  FileHandle.standardOutput.write(Data([0x0A]))
}

extension Duration {
  fileprivate var nanoseconds: UInt64 {
    let components = self.components
    let seconds = UInt64(max(0, components.seconds))
    let attoseconds = UInt64(max(0, components.attoseconds))
    return seconds &* 1_000_000_000 + attoseconds / 1_000_000_000
  }
}

do {
  try main()
} catch {
  FileHandle.standardError.write(Data("ARCH-02 measurement failed: \(error)\n".utf8))
  exit(EXIT_FAILURE)
}
