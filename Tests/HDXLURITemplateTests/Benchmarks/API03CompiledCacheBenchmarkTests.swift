import Foundation
import HDXLURITemplateAPI03BenchmarkSupport
import Testing

@testable import HDXLURITemplate

@Test("API-03 generated workloads match the pinned corpus contract")
private func api03GeneratedWorkloadsMatchPinnedContract() throws {
  try Workloads.verifyGenerated()
  #expect(api03PositiveReferenceExamples.count == 234)

  #expect(Workloads.full.map(\.id) == api03PinnedWorkloads.map(\.id))
  #expect(
    Workloads.quick.map(\.id) == [
      "balanced-1",
      "balanced-10",
      "balanced-100",
    ]
  )

  for (workload, pinned) in zip(
    Workloads.full,
    api03PinnedWorkloads
  ) {
    #expect(workload.seed == api03WorkloadSeed)
    #expect(workload.size == pinned.templateCount)
    #expect(
      workload.authoritativeUTF8ByteCount
        == pinned.authoritativeUTF8ByteCount
    )
    #expect(workload.corpusDigest == pinned.corpusDigest)
    #expect(workload.categoryCounts.templateCount == workload.size)
    #expect(
      workload.categoryCounts.uniqueSources
        == pinned.uniqueSourceCount
    )
    #expect(
      workload.categoryCounts.repeatedOccurrences
        == pinned.repeatedOccurrenceCount
    )

    if workload.size >= 10 {
      let countPerArchetype = workload.size / 10
      #expect(
        api03ArchetypeCounts(workload.categoryCounts)
          == Array(repeating: countPerArchetype, count: 10)
      )
      #expect(
        workload.categoryCounts.shortVariableLists
          == countPerArchetype * 3
      )
      #expect(
        workload.categoryCounts.longVariableLists
          == countPerArchetype * 5
      )
      #expect(
        workload.categoryCounts.explodeModifiers
          == countPerArchetype * 3
      )
      #expect(
        workload.categoryCounts.prefixModifiers
          == countPerArchetype * 3
      )
    }
  }
}

@Test(
  "API-03 prototype matches every positive pinned example",
  arguments: api03PositiveReferenceExamples
)
private func api03PrototypeMatchesEveryPositivePinnedExample(
  example: CaptionedTestCase
) throws {
  let source = example.testCase.template
  let parsed = try URITemplate(parsing: source)
  let compiled = try CompiledCacheTemplateDTO(compiling: source)
  let projected = api03Project(parsed)

  #expect(compiled.isStructurallyValid)
  #expect(
    compiled.exactRenderedSource?.utf8.elementsEqual(source.utf8)
      == true
  )
  #expect(
    compiled.sortedVariableNames
      == parsed.variableNames.sorted()
  )
  #expect(compiled == projected)

  let publicExpansion = try parsed.evaluateAsString(
    parameters: example.parameters
  )
  let prototypeExpansion = try api03Evaluate(
    compiled,
    parameters: example.parameters
  )
  #expect(prototypeExpansion == publicExpansion)

  switch example.testCase.expectation {
  case .evaluationFailure:
    Issue.record(
      "An evaluation-failure case entered the API-03 positive partition."
    )
  case .exactMatch(let expected):
    #expect(prototypeExpansion == expected)
  case .multiplePossibleMatches(let expected):
    #expect(expected.contains(prototypeExpansion))
  }
}

@Test("API-03 cache hit skips fallback and retains exact projections")
private func api03CacheHitSkipsFallbackAndRetainsExactProjections() throws {
  let sources = api03CacheTestSources
  let templates = try sources.map {
    try URITemplate(parsing: $0)
  }
  let expected = CompiledCachePrototype.summarize(templates)
  let cache = try CompiledCachePrototype.encode(
    authoritativeSources: sources
  )
  var fallbackInvocationCount = 0

  let result = try CompiledCachePrototype.load(
    cache,
    authoritativeSources: sources
  ) { fallbackSources in
    fallbackInvocationCount += 1
    return try fallbackSources.map {
      try URITemplate(parsing: $0)
    }
  }

  #expect(fallbackInvocationCount == 0)
  #expect(result.outcome == .hit)
  #expect(result.sources == sources)
  #expect(result.sortedVariableNames == expected.sortedVariableNames)
  #expect(result.stableResultDigest == expected.stableResultDigest)
}

@Test("API-03 rejected caches fall back exactly once")
private func api03RejectedCachesFallBackExactlyOnce() throws {
  let sources = api03CacheTestSources
  let templates = try sources.map {
    try URITemplate(parsing: $0)
  }
  let expected = CompiledCachePrototype.summarize(templates)
  let validCache = try CompiledCachePrototype.encode(
    authoritativeSources: sources
  )

  for testCase in api03FallbackTestCases {
    let rejectedCache = try CompiledCachePrototype.applying(
      testCase.fault,
      to: validCache
    )
    var fallbackInvocationCount = 0
    let result = try CompiledCachePrototype.load(
      rejectedCache,
      authoritativeSources: sources
    ) { fallbackSources in
      fallbackInvocationCount += 1
      return try fallbackSources.map {
        try URITemplate(parsing: $0)
      }
    }

    #expect(
      fallbackInvocationCount == 1,
      "Fault \(String(describing: testCase.fault)) did not fall back once."
    )
    #expect(
      result.outcome == .fallback(testCase.reason),
      "Fault \(String(describing: testCase.fault)) had the wrong outcome."
    )
    #expect(result.sources == expected.sources)
    #expect(result.sortedVariableNames == expected.sortedVariableNames)
    #expect(result.stableResultDigest == expected.stableResultDigest)
  }
}

@Test("API-03 invalid authoritative fallback source fails controllably")
private func api03InvalidAuthoritativeFallbackSourceFailsControllably() {
  var fallbackInvocationCount = 0

  do {
    _ = try CompiledCachePrototype.load(
      Data([0x00]),
      authoritativeSources: ["{"]
    ) { sources in
      fallbackInvocationCount += 1
      return try sources.map {
        try URITemplate(parsing: $0)
      }
    }
    Issue.record(
      "An invalid authoritative source unexpectedly completed fallback."
    )
  } catch is URITemplate.ParseError {
    #expect(fallbackInvocationCount == 1)
  } catch {
    Issue.record(
      "Expected URITemplate.ParseError; observed \(String(reflecting: error))."
    )
  }
}

@Test("API-03 primary and fallback lanes retain one stable result")
private func api03PrimaryAndFallbackLanesRetainOneStableResult() throws {
  for workload in Workloads.full {
    let prepared = try PreparedInputs(workload: workload)
    #expect(
      prepared.availableOperations == Array(BenchmarkOperation.allCases)
    )

    var operations = BenchmarkOperation.primaryCases
    if workload.id == "balanced-1000"
      || workload.id == "balanced-10000"
    {
      operations.append(contentsOf: BenchmarkOperation.fallbackCases)
    }
    let results = try operations.map { operation in
      (operation, try prepared.execute(operation))
    }
    let directResult = try #require(
      results.first(where: { $0.0 == .directParse })?.1
    )

    for (operation, result) in results {
      #expect(
        result.digest == directResult.digest,
        """
        Operation \(operation.rawValue) changed the stable result for \
        \(workload.id).
        """
      )
      #expect(result.templateCount == workload.size)
      #expect(result.encodedBytes > 0)

      if operation == .prototypeCache {
        #expect(result.cacheOutcome == .hit)
      } else if operation.isPrimary {
        #expect(result.cacheOutcome == .notApplicable)
      } else {
        #expect(result.cacheOutcome != .hit)
        #expect(result.cacheOutcome != .notApplicable)
      }
    }
  }
}

@Test("API-03 literal-only workload still constructs every rejection lane")
private func api03LiteralOnlyWorkloadConstructsEveryRejectionLane() throws {
  let workload = try Workloads.workload(
    kind: .balanced,
    size: 1
  )
  let prepared = try PreparedInputs(workload: workload)

  #expect(
    prepared.availableOperations == Array(BenchmarkOperation.allCases)
  )
  for operation in BenchmarkOperation.fallbackCases {
    let result = try prepared.execute(operation)
    #expect(result.cacheOutcome != .hit)
    #expect(result.cacheOutcome != .notApplicable)
    #expect(result.templateCount == 1)
  }
}

@Test("API-03 fresh lanes read no unrelated persisted inputs")
private func api03FreshLanesReadNoUnrelatedPersistedInputs() throws {
  let workload = try Workloads.workload(
    kind: .balanced,
    size: 10
  )
  let expected = CompiledCachePrototype.summarize(
    try workload.sources.map {
      try URITemplate(parsing: $0)
    }
  )
  let rootDirectory = FileManager.default.temporaryDirectory
    .appendingPathComponent(
      "HDXLURITemplate-API03-\(UUID().uuidString)",
      isDirectory: true
    )
  defer {
    try? FileManager.default.removeItem(at: rootDirectory)
  }

  for operation in BenchmarkOperation.allCases {
    let operationRoot = rootDirectory.appendingPathComponent(
      operation.rawValue,
      isDirectory: true
    )
    _ = try PreparedInputs.prepare(
      workload: workload,
      in: operationRoot
    )
    let workloadDirectory = operationRoot.appendingPathComponent(
      workload.id,
      isDirectory: true
    )
    let requiredFileNames = api03RequiredFreshFileNames(
      for: operation
    )
    for fileURL in try FileManager.default.contentsOfDirectory(
      at: workloadDirectory,
      includingPropertiesForKeys: nil
    ) where !requiredFileNames.contains(fileURL.lastPathComponent) {
      try FileManager.default.removeItem(at: fileURL)
    }

    let result = try PreparedInputs.executeFresh(
      operation,
      workload: workload,
      from: operationRoot
    )
    #expect(
      result.digest == expected.stableResultDigest,
      "Fresh operation \(operation.rawValue) read the wrong result."
    )
    #expect(result.templateCount == workload.size)
    #expect(result.encodedBytes > 0)
  }
}

@Test("API-03 summaries retain deterministic latency and speedup statistics")
private func api03SummariesRetainDeterministicStatistics() throws {
  let directElapsed: [UInt64] = [90, 95, 100, 105, 110, 120]
  let cacheElapsed: [UInt64] = [45, 48, 50, 52, 55, 60]
  let directLaunch: [UInt64] = [900, 950, 1_000, 1_050, 1_100, 1_200]
  let cacheLaunch: [UInt64] = [700, 750, 800, 800, 850, 900]
  var records: [API03MeasurementRecord] = []

  for sampleIndex in directElapsed.indices {
    records.append(
      api03SyntheticMeasurement(
        operation: BenchmarkOperation.directParse.rawValue,
        sampleIndex: sampleIndex,
        elapsedNanoseconds: directElapsed[sampleIndex],
        launchElapsedNanoseconds: directLaunch[sampleIndex],
        encodedBytes: 100,
        outcome: BenchmarkCacheOutcome.notApplicable.rawValue
      )
    )
    records.append(
      api03SyntheticMeasurement(
        operation: BenchmarkOperation.prototypeCache.rawValue,
        sampleIndex: sampleIndex,
        elapsedNanoseconds: cacheElapsed[sampleIndex],
        launchElapsedNanoseconds: cacheLaunch[sampleIndex],
        encodedBytes: 300,
        outcome: BenchmarkCacheOutcome.hit.rawValue
      )
    )
  }

  let firstSummary = try api03SummaryCSV(records: records)
  let secondSummary = try api03SummaryCSV(records: records)
  #expect(firstSummary == secondSummary)

  let table = try api03ParseSimpleCSV(firstSummary)
  #expect(table.rows.count == 2)
  let cacheRow = try #require(
    table.rows.first {
      $0[table.column("operation")] == BenchmarkOperation.prototypeCache.rawValue
    }
  )
  #expect(cacheRow[table.column("sample_count")] == "6")
  #expect(cacheRow[table.column("launch_sample_count")] == "6")
  #expect(cacheRow[table.column("direct_parse_speedup")] == "2.010")
  #expect(cacheRow[table.column("direct_parse_launch_speedup")] == "1.281")
  #expect(cacheRow[table.column("bootstrap_resamples")] == "10000")
  #expect(
    !cacheRow[
      table.column("direct_parse_speedup_ci95_lower")
    ].isEmpty
  )
  #expect(
    !cacheRow[
      table.column("direct_parse_launch_speedup_ci95_lower")
    ].isEmpty
  )
}

@Test("API-03 warm summaries retain clustered process statistics")
private func api03WarmSummariesRetainClusteredStatistics() throws {
  var records: [API03MeasurementRecord] = []

  for processIndex in 0..<5 {
    for sampleIndex in 0..<6 {
      let offset = UInt64(processIndex * 10 + sampleIndex)
      records.append(
        api03SyntheticWarmMeasurement(
          operation: BenchmarkOperation.directParse.rawValue,
          processIndex: processIndex,
          sampleIndex: sampleIndex,
          elapsedNanoseconds: 200 + offset,
          encodedBytes: 100,
          outcome: BenchmarkCacheOutcome.notApplicable.rawValue
        )
      )
      records.append(
        api03SyntheticWarmMeasurement(
          operation: BenchmarkOperation.prototypeCache.rawValue,
          processIndex: processIndex,
          sampleIndex: sampleIndex,
          elapsedNanoseconds: 100 + offset,
          encodedBytes: 300,
          outcome: BenchmarkCacheOutcome.hit.rawValue
        )
      )
    }
  }

  let firstSummary = try api03SummaryCSV(records: records)
  let secondSummary = try api03SummaryCSV(records: records)
  #expect(firstSummary == secondSummary)

  let table = try api03ParseSimpleCSV(firstSummary)
  #expect(table.rows.count == 2)
  for row in table.rows {
    #expect(row[table.column("sample_count")] == "30")
    #expect(row[table.column("independent_process_count")] == "5")
    #expect(row[table.column("minimum_batches_per_process")] == "6")
    #expect(row[table.column("maximum_batches_per_process")] == "6")
    #expect(row[table.column("launch_sample_count")] == "0")
    #expect(row[table.column("median_launch_to_exit_nanoseconds")].isEmpty)
    #expect(row[table.column("p95_launch_to_exit_nanoseconds")].isEmpty)
    #expect(row[table.column("direct_parse_launch_speedup")].isEmpty)
    #expect(
      row[table.column("direct_parse_launch_speedup_ci95_lower")].isEmpty
    )
    #expect(
      row[table.column("direct_parse_launch_speedup_ci95_upper")].isEmpty
    )
    #expect(!row[table.column("median_ci95_lower_nanoseconds")].isEmpty)
    #expect(!row[table.column("median_ci95_upper_nanoseconds")].isEmpty)
    #expect(!row[table.column("direct_parse_speedup_ci95_lower")].isEmpty)
    #expect(!row[table.column("direct_parse_speedup_ci95_upper")].isEmpty)
  }
}

@Test("API-03 partial warm comparisons fail with a diagnostic")
private func api03PartialWarmComparisonsFailWithDiagnostic() {
  let records = [
    api03SyntheticWarmMeasurement(
      operation: BenchmarkOperation.directParse.rawValue,
      processIndex: 0,
      sampleIndex: 0,
      elapsedNanoseconds: 200,
      encodedBytes: 100,
      outcome: BenchmarkCacheOutcome.notApplicable.rawValue
    ),
    api03SyntheticWarmMeasurement(
      operation: BenchmarkOperation.directParse.rawValue,
      processIndex: 1,
      sampleIndex: 0,
      elapsedNanoseconds: 210,
      encodedBytes: 100,
      outcome: BenchmarkCacheOutcome.notApplicable.rawValue
    ),
    api03SyntheticWarmMeasurement(
      operation: BenchmarkOperation.prototypeCache.rawValue,
      processIndex: 0,
      sampleIndex: 0,
      elapsedNanoseconds: 100,
      encodedBytes: 300,
      outcome: BenchmarkCacheOutcome.hit.rawValue
    ),
  ]

  do {
    _ = try api03SummaryCSV(records: records)
    Issue.record("A partial warm comparison unexpectedly summarized.")
  } catch let error as API03MeasurementError {
    guard
      case .mismatchedProcessIndices(let direct, let comparison) = error
    else {
      Issue.record("Unexpected measurement error: \(error)")
      return
    }
    #expect(direct == [0, 1])
    #expect(comparison == [0])
  } catch {
    Issue.record("Unexpected error: \(String(reflecting: error))")
  }
}

private struct API03PinnedWorkload {
  let id: String
  let templateCount: Int
  let authoritativeUTF8ByteCount: Int
  let uniqueSourceCount: Int
  let repeatedOccurrenceCount: Int
  let corpusDigest: String
}

private let api03PinnedWorkloads: [API03PinnedWorkload] = [
  API03PinnedWorkload(
    id: "balanced-1",
    templateCount: 1,
    authoritativeUTF8ByteCount: 55,
    uniqueSourceCount: 1,
    repeatedOccurrenceCount: 0,
    corpusDigest:
      "2f37db2ec67d4d0681905cfd419231f9265c81c70dc63a07d19f9905858c2799"
  ),
  API03PinnedWorkload(
    id: "balanced-10",
    templateCount: 10,
    authoritativeUTF8ByteCount: 727,
    uniqueSourceCount: 10,
    repeatedOccurrenceCount: 0,
    corpusDigest:
      "53d0f546f4d8dcc3747e0f9864b55fdc24b0ad29b250a2ec0e34e8ee6f359c5a"
  ),
  API03PinnedWorkload(
    id: "balanced-100",
    templateCount: 100,
    authoritativeUTF8ByteCount: 7_270,
    uniqueSourceCount: 75,
    repeatedOccurrenceCount: 25,
    corpusDigest:
      "230d0f04ce6634c515917cb593e418dd534e29f63350fba64cf24bc4071af10b"
  ),
  API03PinnedWorkload(
    id: "balanced-1000",
    templateCount: 1_000,
    authoritativeUTF8ByteCount: 72_700,
    uniqueSourceCount: 750,
    repeatedOccurrenceCount: 250,
    corpusDigest:
      "8892a5bed2e0c2db945364e319be9d55a367cac34ef2ffaa8faf65cd68c2723b"
  ),
  API03PinnedWorkload(
    id: "balanced-10000",
    templateCount: 10_000,
    authoritativeUTF8ByteCount: 727_000,
    uniqueSourceCount: 7_500,
    repeatedOccurrenceCount: 2_500,
    corpusDigest:
      "78b035cc47584ca769643cecbbbdc19057568f4d84b3d9275f2f9e1ad459e704"
  ),
  API03PinnedWorkload(
    id: "all-repeated-1000",
    templateCount: 1_000,
    authoritativeUTF8ByteCount: 72_700,
    uniqueSourceCount: 10,
    repeatedOccurrenceCount: 990,
    corpusDigest:
      "12504c0f2f3fbecb5ff7cc9cba8ed1fe490f4710b5033c5c781dd3c29093c25b"
  ),
  API03PinnedWorkload(
    id: "all-unique-1000",
    templateCount: 1_000,
    authoritativeUTF8ByteCount: 72_700,
    uniqueSourceCount: 1_000,
    repeatedOccurrenceCount: 0,
    corpusDigest:
      "94373c6840e46676a35621cc8fe0a9baca8a5ecb3df989137298f14f2a59cfeb"
  ),
  API03PinnedWorkload(
    id: "all-repeated-10000",
    templateCount: 10_000,
    authoritativeUTF8ByteCount: 727_000,
    uniqueSourceCount: 10,
    repeatedOccurrenceCount: 9_990,
    corpusDigest:
      "f147a41fe97de58a94cea283fd55d9f28dbfb3598c1929c137894ecb879bdb1f"
  ),
  API03PinnedWorkload(
    id: "all-unique-10000",
    templateCount: 10_000,
    authoritativeUTF8ByteCount: 727_000,
    uniqueSourceCount: 10_000,
    repeatedOccurrenceCount: 0,
    corpusDigest:
      "d51ea8b412e54de834c1dafc592c41172600b919556a96707f4b57750475667a"
  ),
]

private func api03ArchetypeCounts(
  _ counts: WorkloadCategoryCounts
) -> [Int] {
  [
    counts.literalOnlyASCII,
    counts.literalOnlyUnicode,
    counts.simpleOperator,
    counts.reservedOperator,
    counts.fragmentOperator,
    counts.labelOperator,
    counts.pathSegmentOperator,
    counts.pathParameterOperator,
    counts.queryOperator,
    counts.queryContinuationOperator,
  ]
}

private func api03RequiredFreshFileNames(
  for operation: BenchmarkOperation
) -> Set<String> {
  switch operation {
  case .directParse, .semanticJSON:
    ["semantic.json"]
  case .semanticBinaryPropertyList:
    ["semantic.binary.plist"]
  case .prototypeCache:
    ["semantic.json", "prototype.cache"]
  default:
    ["semantic.json", operation.preparedFileName]
  }
}

private func api03SyntheticMeasurement(
  operation: String,
  sampleIndex: Int,
  elapsedNanoseconds: UInt64,
  launchElapsedNanoseconds: UInt64,
  encodedBytes: Int,
  outcome: String
) -> API03MeasurementRecord {
  API03MeasurementRecord(
    benchmarkCommit:
      "0123456789abcdef0123456789abcdef01234567",
    mode: .freshProcess,
    operation: operation,
    workloadID: "balanced-100",
    corpusKind: WorkloadCorpusKind.balanced.rawValue,
    collectionSize: 100,
    processIndex: sampleIndex,
    sampleIndex: 0,
    repetitions: 1,
    elapsedNanoseconds: elapsedNanoseconds,
    launchElapsedNanoseconds: launchElapsedNanoseconds,
    templateOperations: 100,
    encodedBytes: encodedBytes,
    corpusDigest:
      "230d0f04ce6634c515917cb593e418dd534e29f63350fba64cf24bc4071af10b",
    resultDigest:
      "141e2cd515858fa8a38c5dbd0150c1d8540c32adc8dbe4115446046195008994",
    outcome: outcome
  )
}

private func api03SyntheticWarmMeasurement(
  operation: String,
  processIndex: Int,
  sampleIndex: Int,
  elapsedNanoseconds: UInt64,
  encodedBytes: Int,
  outcome: String
) -> API03MeasurementRecord {
  API03MeasurementRecord(
    benchmarkCommit:
      "0123456789abcdef0123456789abcdef01234567",
    mode: .warm,
    operation: operation,
    workloadID: "balanced-100",
    corpusKind: WorkloadCorpusKind.balanced.rawValue,
    collectionSize: 100,
    processIndex: processIndex,
    sampleIndex: sampleIndex,
    repetitions: 1,
    elapsedNanoseconds: elapsedNanoseconds,
    templateOperations: 100,
    encodedBytes: encodedBytes,
    corpusDigest:
      "230d0f04ce6634c515917cb593e418dd534e29f63350fba64cf24bc4071af10b",
    resultDigest:
      "141e2cd515858fa8a38c5dbd0150c1d8540c32adc8dbe4115446046195008994",
    outcome: outcome
  )
}

private struct API03SimpleCSVTable {
  let header: [String]
  let rows: [[String]]

  func column(_ name: String) -> Int {
    guard let index = header.firstIndex(of: name) else {
      preconditionFailure("Missing synthetic CSV column \(name).")
    }
    return index
  }
}

private func api03ParseSimpleCSV(
  _ csv: String
) throws -> API03SimpleCSVTable {
  let lines = csv.split(separator: "\n").map(String.init)
  guard let headerLine = lines.first else {
    throw API03PrototypeEvaluationError.invalidComponent
  }
  let header = headerLine.split(
    separator: ",",
    omittingEmptySubsequences: false
  ).map(String.init)
  let rows = lines.dropFirst().map { line in
    line.split(
      separator: ",",
      omittingEmptySubsequences: false
    ).map(String.init)
  }
  guard rows.allSatisfy({ $0.count == header.count }) else {
    throw API03PrototypeEvaluationError.invalidComponent
  }
  return API03SimpleCSVTable(
    header: header,
    rows: rows
  )
}

private let api03PositiveReferenceExamples =
  allReferenceExamples().filter {
    switch $0.testCase.expectation {
    case .exactMatch, .multiplePossibleMatches:
      true
    case .evaluationFailure:
      false
    }
  }

private let api03CacheTestSources = [
  "https://api.example.test/items/{id}{?query,list*}",
  "https://例え.example/資料/{+resource_path:9}",
]

private struct API03FallbackTestCase {
  let fault: CompiledCacheFault
  let reason: CompiledCacheFallbackReason
}

private let api03FallbackTestCases = [
  API03FallbackTestCase(
    fault: .truncated,
    reason: .decodeOrTruncated
  ),
  API03FallbackTestCase(
    fault: .corruptIntegrity,
    reason: .integrityMismatch
  ),
  API03FallbackTestCase(
    fault: .unsupportedVersion(
      CompiledCachePrototype.currentFormatVersion + 1
    ),
    reason: .unsupportedVersion
  ),
  API03FallbackTestCase(
    fault: .authoritativeSourceMismatch,
    reason: .authoritativeSourceMismatch
  ),
  API03FallbackTestCase(
    fault: .payloadSourceMismatch,
    reason: .payloadSourceMismatch
  ),
  API03FallbackTestCase(
    fault: .unknownOperator,
    reason: .structuralValidation
  ),
  API03FallbackTestCase(
    fault: .unknownModifier,
    reason: .structuralValidation
  ),
  API03FallbackTestCase(
    fault: .invalidPrefix(0),
    reason: .structuralValidation
  ),
  API03FallbackTestCase(
    fault: .invalidPrefix(10_000),
    reason: .structuralValidation
  ),
  API03FallbackTestCase(
    fault: .emptyExpression,
    reason: .structuralValidation
  ),
]

private func api03Project(
  _ template: URITemplate
) -> CompiledCacheTemplateDTO {
  CompiledCacheTemplateDTO(
    components: template.storage.components.map { component in
      switch component {
      case .literal(let literal):
        CompiledCacheComponentDTO(
          literal: CompiledCacheLiteralDTO(
            text: literal.rawValue
          )
        )

      case .expression(let expression):
        CompiledCacheComponentDTO(
          expression: CompiledCacheExpressionDTO(
            expansionOperator: CompiledCacheOperatorDTO(
              code: expression.expansionType.formatString
            ),
            variables: expression.variables.map { variable in
              CompiledCacheVariableDTO(
                name: variable.variableName.rawValue,
                modifier: api03Project(
                  variable.expansionModifier
                )
              )
            }
          )
        )
      }
    }
  )
}

private func api03Project(
  _ modifier: URIValueExpansionModifier
) -> CompiledCacheModifierDTO {
  switch modifier {
  case .unmodified:
    .unmodified
  case .explode:
    .explode
  case .prefix(let length):
    .prefix(length)
  }
}

private enum API03PrototypeEvaluationError: Error {
  case invalidComponent
  case invalidExpansionOperator(String)
  case invalidModifier(CompiledCacheModifierDTO)
}

private func api03Evaluate(
  _ template: CompiledCacheTemplateDTO,
  parameters: [String: URIVariableValue]
) throws -> String {
  guard template.isStructurallyValid else {
    throw API03PrototypeEvaluationError.invalidComponent
  }

  var result = ""
  for component in template.components {
    switch (component.literal, component.expression) {
    case (.some(let literal), .none):
      result.append(
        contentsOf: URITemplateLiteralComponent(
          rawValue: literal.text
        ).expansionRepresentation
      )

    case (.none, .some(let expression)):
      guard
        let expansionType = URIValueExpansionType(
          formatString: expression.expansionOperator.code
        )
      else {
        throw API03PrototypeEvaluationError.invalidExpansionOperator(
          expression.expansionOperator.code
        )
      }
      let variables = try expression.variables.map { variable in
        URITemplateVariable(
          variableName: URITemplateVariableName(
            rawValue: variable.name
          ),
          expansionModifier: try api03Reconstruct(
            variable.modifier
          )
        )
      }
      result.append(
        contentsOf: try URITemplateExpressionComponent(
          expansionType: expansionType,
          variables: variables
        ).evaluate(parameters: parameters)
      )

    case (.none, .none), (.some, .some):
      throw API03PrototypeEvaluationError.invalidComponent
    }
  }
  return result
}

private func api03Reconstruct(
  _ modifier: CompiledCacheModifierDTO
) throws -> URIValueExpansionModifier {
  switch (modifier.code, modifier.prefixLength) {
  case ("unmodified", .none):
    .unmodified
  case ("explode", .none):
    .explode
  case ("prefix", .some(let length))
  where URIValueExpansionModifier
    .rangeOfValidPrefixCodePointCounts
    .contains(length):
    .prefix(length)
  default:
    throw API03PrototypeEvaluationError.invalidModifier(modifier)
  }
}
