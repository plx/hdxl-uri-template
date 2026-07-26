import Darwin
import Foundation
import HDXLURITemplateAPI03BenchmarkSupport

private enum API03CLIError: Error, CustomStringConvertible {
  case duplicateOption(String)
  case integerOutOfRange(option: String, value: String)
  case invalidOperation(String)
  case invalidWorkload(String)
  case missingCommand
  case missingOption(String)
  case unexpectedArgument(String)
  case unexpectedOption(String)
  case unknownCommand(String)

  var description: String {
    switch self {
    case .duplicateOption(let option):
      return "option may be supplied only once: \(option)"
    case .integerOutOfRange(let option, let value):
      return "invalid integer for \(option): \(value)"
    case .invalidOperation(let operation):
      return "unknown benchmark operation: \(operation)"
    case .invalidWorkload(let workload):
      return "unknown workload: \(workload)"
    case .missingCommand:
      return "missing command"
    case .missingOption(let option):
      return "missing required option: \(option)"
    case .unexpectedArgument(let argument):
      return "unexpected argument: \(argument)"
    case .unexpectedOption(let option):
      return "unexpected option: \(option)"
    case .unknownCommand(let command):
      return "unknown command: \(command)"
    }
  }
}

private struct API03Arguments {
  let command: String
  private(set) var flags: Set<String> = []
  private(set) var values: [String: [String]] = [:]

  init(_ arguments: [String]) throws {
    guard let command = arguments.first else {
      throw API03CLIError.missingCommand
    }
    self.command = command

    var index = 1
    while index < arguments.count {
      let argument = arguments[index]
      guard argument.hasPrefix("--") else {
        throw API03CLIError.unexpectedArgument(argument)
      }

      if argument == "--quick"
        || argument == "--with-rejections"
        || argument == "--help"
      {
        flags.insert(argument)
        index += 1
        continue
      }

      let valueIndex = index + 1
      guard valueIndex < arguments.count else {
        throw API03CLIError.missingOption(argument)
      }
      let value = arguments[valueIndex]
      guard !value.hasPrefix("--") else {
        throw API03CLIError.missingOption(argument)
      }
      values[argument, default: []].append(value)
      index += 2
    }
  }

  func validate(
    flags allowedFlags: Set<String> = [],
    values allowedValues: Set<String> = []
  ) throws {
    if let unexpectedFlag = flags.subtracting(allowedFlags).sorted().first {
      throw API03CLIError.unexpectedOption(unexpectedFlag)
    }
    if let unexpectedValue = Set(values.keys)
      .subtracting(allowedValues).sorted().first
    {
      throw API03CLIError.unexpectedOption(unexpectedValue)
    }
  }

  func requiredValue(_ option: String) throws -> String {
    guard let optionValues = values[option], let value = optionValues.first else {
      throw API03CLIError.missingOption(option)
    }
    guard optionValues.count == 1 else {
      throw API03CLIError.duplicateOption(option)
    }
    return value
  }

  func optionalValue(_ option: String) throws -> String? {
    guard let optionValues = values[option] else {
      return nil
    }
    guard optionValues.count == 1 else {
      throw API03CLIError.duplicateOption(option)
    }
    return optionValues[0]
  }

  func repeatedValues(_ option: String) -> [String] {
    values[option] ?? []
  }

  func nonnegativeInteger(
    _ option: String,
    default defaultValue: Int? = nil
  ) throws -> Int {
    guard let rawValue = try optionalValue(option) else {
      if let defaultValue {
        return defaultValue
      }
      throw API03CLIError.missingOption(option)
    }
    guard let value = Int(rawValue), value >= 0 else {
      throw API03CLIError.integerOutOfRange(
        option: option,
        value: rawValue
      )
    }
    return value
  }

  func positiveInteger(
    _ option: String,
    default defaultValue: Int? = nil
  ) throws -> Int {
    let value = try nonnegativeInteger(option, default: defaultValue)
    guard value > 0 else {
      throw API03CLIError.integerOutOfRange(
        option: option,
        value: String(value)
      )
    }
    return value
  }
}

private struct API03CorpusManifest: Encodable {
  let workload: Workload

  private enum CodingKeys: String, CodingKey {
    case authoritativeUTF8Bytes
    case categoryCounts
    case corpusDigest
    case corpusKind
    case id
    case seed
    case templateCount
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(
      workload.authoritativeUTF8ByteCount,
      forKey: .authoritativeUTF8Bytes
    )
    try container.encode(workload.categoryCounts, forKey: .categoryCounts)
    try container.encode(workload.corpusDigest, forKey: .corpusDigest)
    try container.encode(workload.kind, forKey: .corpusKind)
    try container.encode(workload.id, forKey: .id)
    try container.encode(
      String(format: "0x%016llX", workload.seed),
      forKey: .seed
    )
    try container.encode(workload.size, forKey: .templateCount)
  }
}

private struct API03CorpusManifestDocument: Encodable {
  let schemaVersion = 1
  let status = "verified"
  let profile: String
  let workloads: [API03CorpusManifest]
}

private struct API03Configuration {
  let workload: Workload
  let operation: BenchmarkOperation
}

private struct API03DeterministicGenerator {
  private var state: UInt64

  init(seed: UInt64) {
    self.state = seed
  }

  mutating func next() -> UInt64 {
    state &+= 0x9E37_79B9_7F4A_7C15
    var value = state
    value = (value ^ (value >> 30)) &* 0xBF58_476D_1CE4_E5B9
    value = (value ^ (value >> 27)) &* 0x94D0_49BB_1331_11EB
    return value ^ (value >> 31)
  }
}

private func api03Run(_ arguments: API03Arguments) throws {
  switch arguments.command {
  case "verify-generated":
    try arguments.validate()
    try Workloads.verifyGenerated()
    try api03WriteManifest(workloads: Workloads.full, profile: "full")

  case "prepare":
    try arguments.validate(
      flags: ["--quick"],
      values: ["--directory"]
    )
    let directory = api03FileURL(
      try arguments.requiredValue("--directory"),
      isDirectory: true
    )
    let workloads =
      arguments.flags.contains("--quick")
      ? Workloads.quick
      : Workloads.full
    try Workloads.verifyGenerated()
    try FileManager.default.createDirectory(
      at: directory,
      withIntermediateDirectories: true
    )
    for workload in workloads {
      _ = try PreparedInputs.prepare(
        workload: workload,
        in: directory
      )
    }
    let preparedIDs = Set(
      try PreparedInputs.preparedWorkloadIDs(in: directory)
    )
    guard preparedIDs.isSuperset(of: workloads.map(\.id)) else {
      let missing = Set(workloads.map(\.id))
        .subtracting(preparedIDs).sorted().joined(separator: ", ")
      throw API03CLIError.invalidWorkload(
        "prepared-input verification is missing \(missing)"
      )
    }
    try api03WriteManifest(
      workloads: workloads,
      profile: arguments.flags.contains("--quick") ? "quick" : "full"
    )

  case "single-shot":
    try arguments.validate(
      values: [
        "--commit",
        "--directory",
        "--operation",
        "--process-index",
        "--sample-index",
        "--workload",
      ]
    )
    let workloadID = try arguments.requiredValue("--workload")
    let operation = try api03Operations(
      selectedNames: [try arguments.requiredValue("--operation")]
    )[0]
    let directory = api03FileURL(
      try arguments.requiredValue("--directory"),
      isDirectory: true
    )
    let descriptor = try PreparedInputs.loadWorkloadDescriptor(
      workloadID: workloadID,
      from: directory
    )
    let benchmarkCommit = try arguments.requiredValue("--commit")
    let processIndex = try arguments.nonnegativeInteger("--process-index")
    let sampleIndex = try arguments.nonnegativeInteger("--sample-index")

    let timed = try api03MeasureBatch(repetitions: 1) {
      try PreparedInputs.executeFresh(
        operation,
        descriptor: descriptor,
        from: directory
      )
    }
    let record = try api03Record(
      benchmarkCommit: benchmarkCommit,
      mode: .freshProcess,
      descriptor: descriptor,
      operation: operation,
      processIndex: processIndex,
      sampleIndex: sampleIndex,
      repetitions: 1,
      elapsedNanoseconds: timed.elapsedNanoseconds,
      result: timed.lastResult
    )
    try api03WriteJSONLine(record)

  case "benchmark-warm":
    try arguments.validate(
      flags: ["--quick", "--with-rejections"],
      values: [
        "--commit",
        "--directory",
        "--operation",
        "--process-index",
        "--samples",
        "--workload",
      ]
    )
    let quick = arguments.flags.contains("--quick")
    let withRejections = arguments.flags.contains("--with-rejections")
    let workloads = try api03Workloads(
      selectedIDs: arguments.repeatedValues("--workload"),
      quick: quick
    )
    let selectedOperationNames = arguments.repeatedValues("--operation")
    if withRejections && !selectedOperationNames.isEmpty {
      throw API03CLIError.unexpectedOption(
        "--operation cannot be combined with --with-rejections"
      )
    }
    let operations = try api03Operations(
      selectedNames: selectedOperationNames
    )
    let directory = api03FileURL(
      try arguments.requiredValue("--directory"),
      isDirectory: true
    )
    let benchmarkCommit = try arguments.requiredValue("--commit")
    let processIndex = try arguments.nonnegativeInteger("--process-index")
    let sampleCount = try arguments.positiveInteger(
      "--samples",
      default: 6
    )

    var configurations = workloads.flatMap { workload in
      operations.map {
        API03Configuration(workload: workload, operation: $0)
      }
    }
    if withRejections {
      let rejectionWorkloadIDs =
        quick
        ? ["balanced-100"]
        : ["balanced-1000", "balanced-10000"]
      let workloadsByID = Dictionary(
        uniqueKeysWithValues: workloads.map { ($0.id, $0) }
      )
      for workloadID in rejectionWorkloadIDs {
        guard let workload = workloadsByID[workloadID] else {
          throw API03CLIError.invalidWorkload(
            "--with-rejections requires \(workloadID)"
          )
        }
        configurations.append(
          contentsOf: BenchmarkOperation.fallbackCases.map {
            API03Configuration(workload: workload, operation: $0)
          }
        )
      }
    }
    var generator = API03DeterministicGenerator(
      seed: api03WorkloadSeed ^ UInt64(processIndex)
    )
    api03Shuffle(&configurations, using: &generator)

    for configuration in configurations {
      let prepared = try PreparedInputs.load(
        workload: configuration.workload,
        from: directory
      )
      let descriptor = configuration.workload.descriptor
      guard prepared.availableOperations.contains(configuration.operation) else {
        continue
      }
      for _ in 0..<api03WarmupBatchCount {
        _ = try prepared.execute(configuration.operation)
      }
      let calibration = try api03Calibrate {
        try prepared.execute(configuration.operation)
      }
      var repetitions = calibration.repetitions

      for _ in 0..<api03WarmupBatchCount {
        _ = try api03MeasureBatch(
          repetitions: repetitions
        ) {
          try prepared.execute(configuration.operation)
        }
      }

      var retainedBatches: [API03TimedBatch<OperationResult>] = []
      while retainedBatches.count < sampleCount {
        let timed = try api03MeasureBatch(
          repetitions: repetitions
        ) {
          try prepared.execute(configuration.operation)
        }
        guard timed.elapsedNanoseconds >= api03MinimumBatchNanoseconds else {
          guard repetitions <= Int.max / 2 else {
            throw API03MeasurementError.repetitionLimitReached(
              repetitions
            )
          }
          repetitions *= 2
          retainedBatches.removeAll(keepingCapacity: true)
          for _ in 0..<api03WarmupBatchCount {
            _ = try api03MeasureBatch(repetitions: repetitions) {
              try prepared.execute(configuration.operation)
            }
          }
          continue
        }
        retainedBatches.append(timed)
      }

      for (sampleIndex, timed) in retainedBatches.enumerated() {
        let record = try api03Record(
          benchmarkCommit: benchmarkCommit,
          mode: .warm,
          descriptor: descriptor,
          operation: configuration.operation,
          processIndex: processIndex,
          sampleIndex: sampleIndex,
          repetitions: repetitions,
          elapsedNanoseconds: timed.elapsedNanoseconds,
          result: timed.lastResult
        )
        try api03WriteJSONLine(record)
      }
    }

  case "summarize":
    try arguments.validate(values: ["--input", "--output"])
    let inputPaths = arguments.repeatedValues("--input")
    guard !inputPaths.isEmpty else {
      throw API03CLIError.missingOption("--input")
    }
    let records = try inputPaths.flatMap {
      try api03DecodeMeasurementRecords(
        at: api03FileURL($0, isDirectory: false)
      )
    }
    let csv = api03SummaryCSV(records: records)
    if let outputPath = try arguments.optionalValue("--output") {
      try Data(csv.utf8).write(
        to: api03FileURL(outputPath, isDirectory: false),
        options: .atomic
      )
    } else {
      FileHandle.standardOutput.write(Data(csv.utf8))
    }

  default:
    throw API03CLIError.unknownCommand(arguments.command)
  }
}

private func api03Workloads(
  selectedIDs: [String],
  quick: Bool
) throws -> [Workload] {
  if selectedIDs.isEmpty {
    return quick ? Workloads.quick : Workloads.full
  }

  // Generate only explicitly selected warm corpora. Consulting Workloads.full
  // would generate every large corpus even when the caller requests one.
  return try selectedIDs.map { selectedID in
    for kind in WorkloadCorpusKind.allCases {
      let prefix = "\(kind.rawValue)-"
      guard
        selectedID.hasPrefix(prefix),
        let size = Int(selectedID.dropFirst(prefix.count))
      else {
        continue
      }
      do {
        return try Workloads.workload(kind: kind, size: size)
      } catch {
        throw API03CLIError.invalidWorkload(selectedID)
      }
    }
    throw API03CLIError.invalidWorkload(selectedID)
  }
}

private func api03Operations(
  selectedNames: [String]
) throws -> [BenchmarkOperation] {
  let available = Array(BenchmarkOperation.allCases)
  if selectedNames.isEmpty {
    return BenchmarkOperation.primaryCases
  }
  return try selectedNames.map { selectedName in
    guard
      let operation = available.first(where: {
        $0.rawValue == selectedName
      })
    else {
      throw API03CLIError.invalidOperation(selectedName)
    }
    return operation
  }
}

private func api03Record(
  benchmarkCommit: String,
  mode: API03MeasurementMode,
  descriptor: WorkloadDescriptor,
  operation: BenchmarkOperation,
  processIndex: Int,
  sampleIndex: Int,
  repetitions: Int,
  elapsedNanoseconds: UInt64,
  result: OperationResult
) throws -> API03MeasurementRecord {
  let (templateOperations, overflow) = result.templateCount
    .multipliedReportingOverflow(by: repetitions)
  guard !overflow else {
    throw API03CLIError.integerOutOfRange(
      option: "template-operations",
      value: "\(result.templateCount) * \(repetitions)"
    )
  }

  return API03MeasurementRecord(
    benchmarkCommit: benchmarkCommit,
    mode: mode,
    operation: operation.rawValue,
    workloadID: descriptor.id,
    corpusKind: descriptor.kind.rawValue,
    collectionSize: descriptor.size,
    processIndex: processIndex,
    sampleIndex: sampleIndex,
    repetitions: repetitions,
    elapsedNanoseconds: elapsedNanoseconds,
    templateOperations: templateOperations,
    encodedBytes: result.encodedBytes,
    corpusDigest: descriptor.corpusDigest,
    resultDigest: result.digest,
    outcome: result.cacheOutcome.rawValue
  )
}

private func api03Shuffle(
  _ configurations: inout [API03Configuration],
  using generator: inout API03DeterministicGenerator
) {
  guard configurations.count > 1 else {
    return
  }
  for upperBound in stride(
    from: configurations.count - 1,
    through: 1,
    by: -1
  ) {
    let selected = Int(generator.next() % UInt64(upperBound + 1))
    configurations.swapAt(upperBound, selected)
  }
}

private func api03WriteManifest(
  workloads: [Workload],
  profile: String
) throws {
  try api03WriteJSONLine(
    API03CorpusManifestDocument(
      profile: profile,
      workloads: workloads.map(API03CorpusManifest.init)
    )
  )
}

private func api03WriteJSONLine<Value: Encodable>(
  _ value: Value
) throws {
  FileHandle.standardOutput.write(try api03EncodeJSONLine(value))
}

private func api03FileURL(
  _ path: String,
  isDirectory: Bool
) -> URL {
  URL(
    fileURLWithPath: path,
    isDirectory: isDirectory,
    relativeTo: URL(
      fileURLWithPath: FileManager.default.currentDirectoryPath,
      isDirectory: true
    )
  ).standardizedFileURL
}

private let api03Usage = """
  Usage:
    HDXLURITemplateAPI03Benchmark verify-generated
    HDXLURITemplateAPI03Benchmark prepare --directory PATH [--quick]
    HDXLURITemplateAPI03Benchmark single-shot --directory PATH \
  --workload ID --operation NAME --commit SHA --process-index N --sample-index N
    HDXLURITemplateAPI03Benchmark benchmark-warm --directory PATH --commit SHA \
  --process-index N [--samples N] [--quick] [--workload ID]... \
  [--operation NAME]... [--with-rejections]
    HDXLURITemplateAPI03Benchmark summarize --input JSONL [--input JSONL]... \
  [--output CSV]
  """

do {
  let arguments = try API03Arguments(
    Array(CommandLine.arguments.dropFirst())
  )
  if arguments.flags.contains("--help") {
    FileHandle.standardOutput.write(Data(api03Usage.utf8))
  } else {
    try api03Run(arguments)
  }
} catch {
  let message = "error: \(error)\n\n\(api03Usage)"
  FileHandle.standardError.write(Data(message.utf8))
  exit(error is API03CLIError ? EX_USAGE : EXIT_FAILURE)
}
