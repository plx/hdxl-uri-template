import Foundation

package let api03MinimumBatchNanoseconds: UInt64 = 200_000_000
package let api03WarmupBatchCount = 5
package let api03BootstrapResampleCount = 10_000
package let api03UnavailableLaunchNanoseconds = UInt64.max

package enum API03MeasurementMode: String, Codable, Sendable {
  case warm
  case freshProcess = "fresh-process"
}

package struct API03MeasurementRecord: Codable, Sendable {
  package let schemaVersion: Int
  package let benchmarkCommit: String
  package let mode: API03MeasurementMode
  package let operation: String
  package let workloadID: String
  package let corpusKind: String
  package let collectionSize: Int
  package let processIndex: Int
  package let sampleIndex: Int
  package let repetitions: Int
  package let elapsedNanoseconds: UInt64
  /// The runner emits the unavailable sentinel. For fresh-process records,
  /// the shell driver replaces that sentinel with launch-to-exit time exactly
  /// once before retaining the JSON line.
  package let launchElapsedNanoseconds: UInt64
  package let templateOperations: Int
  package let encodedBytes: Int
  package let corpusDigest: String
  package let resultDigest: String
  package let outcome: String

  package init(
    schemaVersion: Int = 1,
    benchmarkCommit: String,
    mode: API03MeasurementMode,
    operation: String,
    workloadID: String,
    corpusKind: String,
    collectionSize: Int,
    processIndex: Int,
    sampleIndex: Int,
    repetitions: Int,
    elapsedNanoseconds: UInt64,
    launchElapsedNanoseconds: UInt64 = api03UnavailableLaunchNanoseconds,
    templateOperations: Int,
    encodedBytes: Int,
    corpusDigest: String,
    resultDigest: String,
    outcome: String
  ) {
    self.schemaVersion = schemaVersion
    self.benchmarkCommit = benchmarkCommit
    self.mode = mode
    self.operation = operation
    self.workloadID = workloadID
    self.corpusKind = corpusKind
    self.collectionSize = collectionSize
    self.processIndex = processIndex
    self.sampleIndex = sampleIndex
    self.repetitions = repetitions
    self.elapsedNanoseconds = elapsedNanoseconds
    self.launchElapsedNanoseconds = launchElapsedNanoseconds
    self.templateOperations = templateOperations
    self.encodedBytes = encodedBytes
    self.corpusDigest = corpusDigest
    self.resultDigest = resultDigest
    self.outcome = outcome
  }
}

package struct API03TimedBatch<Result> {
  package let elapsedNanoseconds: UInt64
  package let lastResult: Result
}

package struct API03Calibration<Result> {
  package let repetitions: Int
  package let elapsedNanoseconds: UInt64
  package let lastResult: Result
}

package enum API03MeasurementError: Error, CustomStringConvertible {
  case emptyInput(URL)
  case emptyBootstrapPopulation(String)
  case elapsedDurationOutOfRange
  case invalidRepetitionCount(Int)
  case malformedJSONLine(url: URL, line: Int, underlying: Error)
  case mismatchedProcessIndices(direct: [Int], comparison: [Int])
  case repetitionLimitReached(Int)
  case unsupportedSchemaVersion(Int)

  package var description: String {
    switch self {
    case .emptyInput(let url):
      return "measurement input is empty: \(url.path)"
    case .emptyBootstrapPopulation(let context):
      return "cannot bootstrap an empty measurement population: \(context)"
    case .elapsedDurationOutOfRange:
      return "measured duration cannot be represented as whole nanoseconds"
    case .invalidRepetitionCount(let count):
      return "repetition count must be positive, got \(count)"
    case .malformedJSONLine(let url, let line, let underlying):
      return "invalid JSON measurement at \(url.path):\(line): \(underlying)"
    case .mismatchedProcessIndices(let direct, let comparison):
      return """
        warm direct-parse speedup confidence intervals require matching \
        processIndex sets; direct=\(direct), comparison=\(comparison)
        """
    case .repetitionLimitReached(let count):
      return "calibration reached the safe repetition limit at \(count)"
    case .unsupportedSchemaVersion(let version):
      return "unsupported measurement schema version \(version)"
    }
  }
}

@inline(never)
package func api03MeasureBatch<Result>(
  repetitions: Int,
  operation: () throws -> Result
) throws -> API03TimedBatch<Result> {
  guard repetitions > 0 else {
    throw API03MeasurementError.invalidRepetitionCount(repetitions)
  }

  let clock = ContinuousClock()
  let start = clock.now
  var lastResult = try operation()
  if repetitions > 1 {
    for _ in 1..<repetitions {
      lastResult = try operation()
    }
  }
  let elapsed = start.duration(to: clock.now)

  return API03TimedBatch(
    elapsedNanoseconds: try api03WholeNanoseconds(elapsed),
    lastResult: lastResult
  )
}

package func api03Calibrate<Result>(
  minimumNanoseconds: UInt64 = api03MinimumBatchNanoseconds,
  operation: () throws -> Result
) throws -> API03Calibration<Result> {
  var repetitions = 1

  while true {
    let batch = try api03MeasureBatch(
      repetitions: repetitions,
      operation: operation
    )
    if batch.elapsedNanoseconds >= minimumNanoseconds {
      return API03Calibration(
        repetitions: repetitions,
        elapsedNanoseconds: batch.elapsedNanoseconds,
        lastResult: batch.lastResult
      )
    }

    guard repetitions <= Int.max / 2 else {
      throw API03MeasurementError.repetitionLimitReached(repetitions)
    }
    repetitions *= 2
  }
}

package func api03EncodeJSONLine<Value: Encodable>(
  _ value: Value
) throws -> Data {
  let encoder = JSONEncoder()
  encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
  var data = try encoder.encode(value)
  data.append(0x0A)
  return data
}

package func api03DecodeMeasurementRecords(
  at url: URL
) throws -> [API03MeasurementRecord] {
  let data = try Data(contentsOf: url)
  guard !data.isEmpty else {
    throw API03MeasurementError.emptyInput(url)
  }

  var records: [API03MeasurementRecord] = []
  let decoder = JSONDecoder()

  for (zeroBasedLine, rawLine) in data.split(
    separator: 0x0A,
    omittingEmptySubsequences: false
  ).enumerated() {
    if rawLine.allSatisfy({ $0 == 0x20 || $0 == 0x09 || $0 == 0x0D }) {
      continue
    }

    do {
      let record = try decoder.decode(
        API03MeasurementRecord.self,
        from: Data(rawLine)
      )
      guard record.schemaVersion == 1 else {
        throw API03MeasurementError.unsupportedSchemaVersion(
          record.schemaVersion
        )
      }
      records.append(record)
    } catch {
      throw API03MeasurementError.malformedJSONLine(
        url: url,
        line: zeroBasedLine + 1,
        underlying: error
      )
    }
  }

  guard !records.isEmpty else {
    throw API03MeasurementError.emptyInput(url)
  }
  return records
}

package func api03SummaryCSV(
  records: [API03MeasurementRecord]
) throws -> String {
  let header = [
    "benchmark_commit",
    "mode",
    "operation",
    "workload_id",
    "corpus_kind",
    "collection_size",
    "sample_count",
    "independent_process_count",
    "minimum_batches_per_process",
    "maximum_batches_per_process",
    "median_nanoseconds",
    "median_ci95_lower_nanoseconds",
    "median_ci95_upper_nanoseconds",
    "p95_nanoseconds",
    "minimum_nanoseconds",
    "maximum_nanoseconds",
    "interquartile_range_nanoseconds",
    "median_absolute_deviation_nanoseconds",
    "relative_mad",
    "launch_sample_count",
    "median_launch_to_exit_nanoseconds",
    "p95_launch_to_exit_nanoseconds",
    "templates_per_second",
    "nanoseconds_per_template",
    "direct_parse_speedup",
    "direct_parse_speedup_ci95_lower",
    "direct_parse_speedup_ci95_upper",
    "direct_parse_launch_speedup",
    "direct_parse_launch_speedup_ci95_lower",
    "direct_parse_launch_speedup_ci95_upper",
    "bootstrap_resamples",
    "encoded_bytes",
    "bytes_per_template",
    "corpus_digest",
    "result_digest",
    "outcome",
  ].joined(separator: ",")

  let groups = Dictionary(grouping: records, by: API03SummaryKey.init)
  let sortedKeys = groups.keys.sorted()
  let statistics = Dictionary(
    uniqueKeysWithValues: sortedKeys.compactMap { key in
      groups[key].map { (key, API03SummaryStatistics(samples: $0)) }
    }
  )
  let lines = try groups.keys.sorted().compactMap { key -> String? in
    guard
      let samples = groups[key],
      let summary = statistics[key],
      !samples.isEmpty
    else {
      return nil
    }

    let medianConfidenceInterval: (lower: Double, upper: Double)
    switch key.mode {
    case .warm:
      medianConfidenceInterval =
        try api03BootstrapClusteredMedianConfidenceInterval(
          summary.processClusters,
          seed: api03BootstrapSeed(for: key, purpose: "median")
        )
    case .freshProcess:
      medianConfidenceInterval = try api03BootstrapMedianConfidenceInterval(
        summary.normalizedNanoseconds,
        seed: api03BootstrapSeed(for: key, purpose: "median")
      )
    }
    let directKey = sortedKeys.first {
      $0.isDirectParseComparison(for: key)
    }
    let directSummary = directKey.flatMap { statistics[$0] }
    let speedup = directSummary.map {
      summary.median == 0 ? 0 : $0.median / summary.median
    }
    let speedupConfidenceInterval: (lower: Double, upper: Double)?
    if key.operation == "direct-parse" {
      speedupConfidenceInterval = (1, 1)
    } else if let directSummary {
      switch key.mode {
      case .warm:
        speedupConfidenceInterval =
          try api03BootstrapPairedClusterSpeedupConfidenceInterval(
            direct: directSummary.processClusters,
            comparison: summary.processClusters,
            seed: api03BootstrapSeed(for: key, purpose: "speedup")
          )
      case .freshProcess:
        speedupConfidenceInterval =
          try api03BootstrapSpeedupConfidenceInterval(
            direct: directSummary.normalizedNanoseconds,
            comparison: summary.normalizedNanoseconds,
            seed: api03BootstrapSeed(for: key, purpose: "speedup")
          )
      }
    } else {
      speedupConfidenceInterval = nil
    }
    let launchSpeedup: Double?
    let launchSpeedupConfidenceInterval: (lower: Double, upper: Double)?
    if let directSummary,
      !directSummary.launchNanoseconds.isEmpty,
      !summary.launchNanoseconds.isEmpty,
      let directLaunchMedian = directSummary.launchMedian,
      let launchMedian = summary.launchMedian
    {
      launchSpeedup =
        launchMedian == 0 ? 0 : directLaunchMedian / launchMedian
      if key.mode != .freshProcess {
        launchSpeedupConfidenceInterval = nil
      } else if key.operation == "direct-parse" {
        launchSpeedupConfidenceInterval = (1, 1)
      } else {
        launchSpeedupConfidenceInterval =
          try api03BootstrapSpeedupConfidenceInterval(
            direct: directSummary.launchNanoseconds,
            comparison: summary.launchNanoseconds,
            seed: api03BootstrapSeed(
              for: key,
              purpose: "launch-speedup"
            )
          )
      }
    } else {
      launchSpeedup = nil
      launchSpeedupConfidenceInterval = nil
    }

    let templatesPerOperation = Double(key.collectionSize)
    let templatesPerSecond =
      summary.median == 0
      ? 0
      : templatesPerOperation * 1_000_000_000 / summary.median
    let nanosecondsPerTemplate =
      templatesPerOperation == 0
      ? 0
      : summary.median / templatesPerOperation
    let encodedBytes = key.encodedBytes
    let bytesPerTemplate =
      templatesPerOperation == 0
      ? 0
      : Double(encodedBytes) / templatesPerOperation

    let launchMedian = summary.launchMedian.map { api03Decimal($0) } ?? ""
    let launchP95 = summary.launchP95.map { api03Decimal($0) } ?? ""
    let speedupValue = speedup.map { api03Decimal($0) } ?? ""
    let speedupLower =
      speedupConfidenceInterval.map {
        api03Decimal($0.lower)
      } ?? ""
    let speedupUpper =
      speedupConfidenceInterval.map {
        api03Decimal($0.upper)
      } ?? ""
    let launchSpeedupValue =
      launchSpeedup.map {
        api03Decimal($0)
      } ?? ""
    let launchSpeedupLower =
      launchSpeedupConfidenceInterval.map {
        api03Decimal($0.lower)
      } ?? ""
    let launchSpeedupUpper =
      launchSpeedupConfidenceInterval.map {
        api03Decimal($0.upper)
      } ?? ""
    let fields: [String] = [
      key.benchmarkCommit,
      key.mode.rawValue,
      key.operation,
      key.workloadID,
      key.corpusKind,
      String(key.collectionSize),
      String(samples.count),
      String(summary.independentProcessCount),
      String(summary.minimumBatchesPerProcess),
      String(summary.maximumBatchesPerProcess),
      api03Decimal(summary.median),
      api03Decimal(medianConfidenceInterval.lower),
      api03Decimal(medianConfidenceInterval.upper),
      api03Decimal(summary.p95),
      api03Decimal(summary.minimum),
      api03Decimal(summary.maximum),
      api03Decimal(summary.interquartileRange),
      api03Decimal(summary.medianAbsoluteDeviation),
      api03Decimal(summary.relativeMAD, places: 6),
      String(summary.launchNanoseconds.count),
      launchMedian,
      launchP95,
      api03Decimal(templatesPerSecond),
      api03Decimal(nanosecondsPerTemplate),
      speedupValue,
      speedupLower,
      speedupUpper,
      launchSpeedupValue,
      launchSpeedupLower,
      launchSpeedupUpper,
      String(api03BootstrapResampleCount),
      String(encodedBytes),
      api03Decimal(bytesPerTemplate),
      key.corpusDigest,
      key.resultDigest,
      key.outcome,
    ]
    return fields.map(api03CSVEscape).joined(separator: ",")
  }

  return ([header] + lines).joined(separator: "\n") + "\n"
}

private struct API03SummaryStatistics {
  let normalizedNanoseconds: [Double]
  let processClusters: [API03ProcessCluster]
  let independentProcessCount: Int
  let minimumBatchesPerProcess: Int
  let maximumBatchesPerProcess: Int
  let median: Double
  let p95: Double
  let minimum: Double
  let maximum: Double
  let interquartileRange: Double
  let medianAbsoluteDeviation: Double
  let relativeMAD: Double
  let launchNanoseconds: [Double]
  let launchMedian: Double?
  let launchP95: Double?

  init(samples: [API03MeasurementRecord]) {
    let normalizedNanoseconds = samples.map {
      Double($0.elapsedNanoseconds) / Double($0.repetitions)
    }.sorted()
    let processClusters = api03ProcessClusters(samples: samples)
    let batchCounts = processClusters.map(\.values.count)
    let median = api03Median(normalizedNanoseconds)
    let lowerQuartile = api03NearestRank(
      normalizedNanoseconds,
      percentile: 0.25
    )
    let upperQuartile = api03NearestRank(
      normalizedNanoseconds,
      percentile: 0.75
    )
    let absoluteDeviations = normalizedNanoseconds.map {
      abs($0 - median)
    }.sorted()
    let medianAbsoluteDeviation = api03Median(absoluteDeviations)
    let launchNanoseconds = samples.compactMap {
      $0.launchElapsedNanoseconds == api03UnavailableLaunchNanoseconds
        ? nil
        : Double($0.launchElapsedNanoseconds)
    }.sorted()

    self.normalizedNanoseconds = normalizedNanoseconds
    self.processClusters = processClusters
    self.independentProcessCount = processClusters.count
    self.minimumBatchesPerProcess = batchCounts.min() ?? 0
    self.maximumBatchesPerProcess = batchCounts.max() ?? 0
    self.median = median
    self.p95 = api03NearestRank(
      normalizedNanoseconds,
      percentile: 0.95
    )
    self.minimum = normalizedNanoseconds[0]
    self.maximum = normalizedNanoseconds[normalizedNanoseconds.count - 1]
    self.interquartileRange = upperQuartile - lowerQuartile
    self.medianAbsoluteDeviation = medianAbsoluteDeviation
    self.relativeMAD =
      median == 0 ? 0 : medianAbsoluteDeviation / median
    self.launchNanoseconds = launchNanoseconds
    self.launchMedian =
      launchNanoseconds.isEmpty ? nil : api03Median(launchNanoseconds)
    self.launchP95 =
      launchNanoseconds.isEmpty
      ? nil
      : api03NearestRank(launchNanoseconds, percentile: 0.95)
  }
}

private struct API03ProcessCluster {
  let processIndex: Int
  let values: [Double]
}

private func api03ProcessClusters(
  samples: [API03MeasurementRecord]
) -> [API03ProcessCluster] {
  let samplesByProcess = Dictionary(
    grouping: samples,
    by: \.processIndex
  )
  return samplesByProcess.keys.sorted().map { processIndex in
    API03ProcessCluster(
      processIndex: processIndex,
      values: samplesByProcess[processIndex, default: []].map {
        Double($0.elapsedNanoseconds) / Double($0.repetitions)
      }.sorted()
    )
  }
}

private struct API03SummaryKey: Hashable, Comparable {
  let benchmarkCommit: String
  let mode: API03MeasurementMode
  let operation: String
  let workloadID: String
  let corpusKind: String
  let collectionSize: Int
  let encodedBytes: Int
  let corpusDigest: String
  let resultDigest: String
  let outcome: String

  init(_ record: API03MeasurementRecord) {
    self.benchmarkCommit = record.benchmarkCommit
    self.mode = record.mode
    self.operation = record.operation
    self.workloadID = record.workloadID
    self.corpusKind = record.corpusKind
    self.collectionSize = record.collectionSize
    self.encodedBytes = record.encodedBytes
    self.corpusDigest = record.corpusDigest
    self.resultDigest = record.resultDigest
    self.outcome = record.outcome
  }

  func isDirectParseComparison(for other: Self) -> Bool {
    operation == "direct-parse"
      && benchmarkCommit == other.benchmarkCommit
      && mode == other.mode
      && workloadID == other.workloadID
      && corpusKind == other.corpusKind
      && collectionSize == other.collectionSize
      && corpusDigest == other.corpusDigest
      && resultDigest == other.resultDigest
  }

  static func < (lhs: Self, rhs: Self) -> Bool {
    if lhs.benchmarkCommit != rhs.benchmarkCommit {
      return lhs.benchmarkCommit < rhs.benchmarkCommit
    }
    if lhs.mode != rhs.mode {
      return lhs.mode.rawValue < rhs.mode.rawValue
    }
    if lhs.operation != rhs.operation {
      return lhs.operation < rhs.operation
    }
    if lhs.workloadID != rhs.workloadID {
      return lhs.workloadID < rhs.workloadID
    }
    if lhs.corpusKind != rhs.corpusKind {
      return lhs.corpusKind < rhs.corpusKind
    }
    if lhs.collectionSize != rhs.collectionSize {
      return lhs.collectionSize < rhs.collectionSize
    }
    if lhs.encodedBytes != rhs.encodedBytes {
      return lhs.encodedBytes < rhs.encodedBytes
    }
    if lhs.corpusDigest != rhs.corpusDigest {
      return lhs.corpusDigest < rhs.corpusDigest
    }
    if lhs.resultDigest != rhs.resultDigest {
      return lhs.resultDigest < rhs.resultDigest
    }
    return lhs.outcome < rhs.outcome
  }
}

private struct API03BootstrapGenerator {
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

private func api03BootstrapMedianConfidenceInterval(
  _ values: [Double],
  seed: UInt64
) throws -> (lower: Double, upper: Double) {
  var generator = API03BootstrapGenerator(seed: seed)
  var estimates: [Double] = []
  estimates.reserveCapacity(api03BootstrapResampleCount)

  for _ in 0..<api03BootstrapResampleCount {
    estimates.append(
      api03Median(
        try api03BootstrapSample(values, using: &generator)
      )
    )
  }
  estimates.sort()
  return (
    lower: api03NearestRank(estimates, percentile: 0.025),
    upper: api03NearestRank(estimates, percentile: 0.975)
  )
}

private func api03BootstrapClusteredMedianConfidenceInterval(
  _ clusters: [API03ProcessCluster],
  seed: UInt64
) throws -> (lower: Double, upper: Double) {
  guard !clusters.isEmpty else {
    throw API03MeasurementError.emptyBootstrapPopulation(
      "clustered median"
    )
  }

  // Warm batches share process-level state. Resample workers first, then
  // resample batches independently within every selected worker.
  var generator = API03BootstrapGenerator(seed: seed)
  var estimates: [Double] = []
  estimates.reserveCapacity(api03BootstrapResampleCount)

  for _ in 0..<api03BootstrapResampleCount {
    estimates.append(
      api03Median(
        try api03HierarchicalBootstrapSample(
          clusters,
          using: &generator
        )
      )
    )
  }
  estimates.sort()
  return (
    lower: api03NearestRank(estimates, percentile: 0.025),
    upper: api03NearestRank(estimates, percentile: 0.975)
  )
}

private func api03BootstrapSpeedupConfidenceInterval(
  direct: [Double],
  comparison: [Double],
  seed: UInt64
) throws -> (lower: Double, upper: Double) {
  var generator = API03BootstrapGenerator(seed: seed)
  var estimates: [Double] = []
  estimates.reserveCapacity(api03BootstrapResampleCount)

  for _ in 0..<api03BootstrapResampleCount {
    let directMedian = api03Median(
      try api03BootstrapSample(direct, using: &generator)
    )
    let comparisonMedian = api03Median(
      try api03BootstrapSample(comparison, using: &generator)
    )
    estimates.append(
      comparisonMedian == 0 ? 0 : directMedian / comparisonMedian
    )
  }
  estimates.sort()
  return (
    lower: api03NearestRank(estimates, percentile: 0.025),
    upper: api03NearestRank(estimates, percentile: 0.975)
  )
}

private func api03BootstrapPairedClusterSpeedupConfidenceInterval(
  direct: [API03ProcessCluster],
  comparison: [API03ProcessCluster],
  seed: UInt64
) throws -> (lower: Double, upper: Double) {
  let directProcessIndices = direct.map(\.processIndex)
  let comparisonProcessIndices = comparison.map(\.processIndex)
  guard directProcessIndices == comparisonProcessIndices else {
    throw API03MeasurementError.mismatchedProcessIndices(
      direct: directProcessIndices,
      comparison: comparisonProcessIndices
    )
  }
  guard !direct.isEmpty else {
    throw API03MeasurementError.emptyBootstrapPopulation(
      "paired clustered speedup"
    )
  }

  // Pair the worker draw to preserve process-level covariance between lanes;
  // batch draws remain independent within the selected worker.
  var generator = API03BootstrapGenerator(seed: seed)
  var estimates: [Double] = []
  estimates.reserveCapacity(api03BootstrapResampleCount)

  for _ in 0..<api03BootstrapResampleCount {
    var directSample: [Double] = []
    var comparisonSample: [Double] = []

    for _ in direct.indices {
      let clusterIndex = Int(
        generator.next() % UInt64(direct.count)
      )
      directSample.append(
        contentsOf: try api03BootstrapSample(
          direct[clusterIndex].values,
          using: &generator
        )
      )
      comparisonSample.append(
        contentsOf: try api03BootstrapSample(
          comparison[clusterIndex].values,
          using: &generator
        )
      )
    }
    directSample.sort()
    comparisonSample.sort()

    let directMedian = api03Median(directSample)
    let comparisonMedian = api03Median(comparisonSample)
    estimates.append(
      comparisonMedian == 0 ? 0 : directMedian / comparisonMedian
    )
  }
  estimates.sort()
  return (
    lower: api03NearestRank(estimates, percentile: 0.025),
    upper: api03NearestRank(estimates, percentile: 0.975)
  )
}

private func api03HierarchicalBootstrapSample(
  _ clusters: [API03ProcessCluster],
  using generator: inout API03BootstrapGenerator
) throws -> [Double] {
  guard !clusters.isEmpty else {
    throw API03MeasurementError.emptyBootstrapPopulation(
      "hierarchical bootstrap"
    )
  }
  var sample: [Double] = []
  sample.reserveCapacity(
    clusters.reduce(into: 0) { $0 += $1.values.count }
  )

  for _ in clusters.indices {
    let clusterIndex = Int(
      generator.next() % UInt64(clusters.count)
    )
    sample.append(
      contentsOf: try api03BootstrapSample(
        clusters[clusterIndex].values,
        using: &generator
      )
    )
  }
  sample.sort()
  return sample
}

private func api03BootstrapSample(
  _ values: [Double],
  using generator: inout API03BootstrapGenerator
) throws -> [Double] {
  guard !values.isEmpty else {
    throw API03MeasurementError.emptyBootstrapPopulation(
      "scalar bootstrap"
    )
  }
  var sample: [Double] = []
  sample.reserveCapacity(values.count)
  for _ in values.indices {
    sample.append(
      values[Int(generator.next() % UInt64(values.count))]
    )
  }
  sample.sort()
  return sample
}

private func api03BootstrapSeed(
  for key: API03SummaryKey,
  purpose: String
) -> UInt64 {
  let fields = [
    key.benchmarkCommit,
    key.mode.rawValue,
    key.operation,
    key.workloadID,
    key.corpusKind,
    String(key.collectionSize),
    String(key.encodedBytes),
    key.corpusDigest,
    key.resultDigest,
    key.outcome,
    purpose,
  ]
  var seed: UInt64 = 0xCBF2_9CE4_8422_2325
  for byte in fields.joined(separator: "\u{1F}").utf8 {
    seed ^= UInt64(byte)
    seed &*= 0x0000_0100_0000_01B3
  }
  return seed ^ 0x4844_584C_4150_4903
}

private func api03WholeNanoseconds(_ duration: Duration) throws -> UInt64 {
  let components = duration.components
  guard components.seconds >= 0, components.attoseconds >= 0 else {
    throw API03MeasurementError.elapsedDurationOutOfRange
  }

  let seconds = UInt64(components.seconds)
  let subsecondNanoseconds = UInt64(components.attoseconds) / 1_000_000_000
  let (wholeNanoseconds, multipliedOverflow) = seconds.multipliedReportingOverflow(
    by: 1_000_000_000
  )
  guard !multipliedOverflow else {
    throw API03MeasurementError.elapsedDurationOutOfRange
  }
  let (result, additionOverflow) = wholeNanoseconds.addingReportingOverflow(
    subsecondNanoseconds
  )
  guard !additionOverflow else {
    throw API03MeasurementError.elapsedDurationOutOfRange
  }
  return result
}

private func api03Median(_ sortedValues: [Double]) -> Double {
  let middle = sortedValues.count / 2
  if sortedValues.count.isMultiple(of: 2) {
    return (sortedValues[middle - 1] + sortedValues[middle]) / 2
  }
  return sortedValues[middle]
}

private func api03NearestRank(
  _ sortedValues: [Double],
  percentile: Double
) -> Double {
  let rank = Int(ceil(percentile * Double(sortedValues.count)))
  let index = max(0, min(sortedValues.count - 1, rank - 1))
  return sortedValues[index]
}

private func api03Decimal(_ value: Double, places: Int = 3) -> String {
  String(
    format: "%.\(places)f",
    locale: Locale(identifier: "en_US_POSIX"),
    value
  )
}

private func api03CSVEscape(_ value: String) -> String {
  guard
    value.contains(",") || value.contains("\"") || value.contains("\n")
      || value.contains("\r")
  else {
    return value
  }
  return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
}
