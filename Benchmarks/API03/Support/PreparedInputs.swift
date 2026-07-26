import Foundation
import HDXLURITemplate

package struct PreparedInputs: Sendable {
  package let workload: Workload
  package let semanticJSON: Data
  package let semanticBinaryPropertyList: Data
  package let prototypeCache: Data

  private let fallbackCaches: [BenchmarkOperation: Data]

  package var availableOperations: [BenchmarkOperation] {
    BenchmarkOperation.allCases.filter { operation in
      switch operation {
      case .directParse,
        .semanticJSON,
        .semanticBinaryPropertyList,
        .prototypeCache:
        true
      default:
        fallbackCaches[operation] != nil
      }
    }
  }

  package init(workload: Workload) throws {
    let templates = try workload.sources.map {
      try URITemplate(parsing: $0)
    }
    let parsedSources = templates.map(\.templateRepresentation)
    guard parsedSources == workload.sources else {
      throw PreparedInputsError.semanticSourceMismatch(
        workloadID: workload.id
      )
    }

    let jsonEncoder = JSONEncoder()
    jsonEncoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
    let semanticJSON = try jsonEncoder.encode(templates)

    let propertyListEncoder = PropertyListEncoder()
    propertyListEncoder.outputFormat = .binary
    let semanticBinaryPropertyList = try propertyListEncoder.encode(templates)

    let prototypeCache = try CompiledCachePrototype.encode(
      authoritativeSources: workload.sources
    )
    let fallbackCaches = try Self.makeFallbackCaches(
      validCache: prototypeCache
    )

    self.init(
      workload: workload,
      semanticJSON: semanticJSON,
      semanticBinaryPropertyList: semanticBinaryPropertyList,
      prototypeCache: prototypeCache,
      fallbackCaches: fallbackCaches
    )
  }

  package static func prepare(
    workload: Workload,
    in rootDirectory: URL
  ) throws -> PreparedInputs {
    let prepared = try PreparedInputs(workload: workload)
    try prepared.write(to: rootDirectory)
    return prepared
  }

  /// Loads one prepared workload from `rootDirectory/<workload.id>/`.
  ///
  /// This is load-once setup for warmed measurements. Fresh-process
  /// measurements use `PreparedInputs.executeFresh(_:descriptor:from:)` so
  /// they read only the selected lane's persisted artifacts.
  package static func load(
    workload: Workload,
    from rootDirectory: URL
  ) throws -> PreparedInputs {
    let directory = try workloadDirectory(
      rootDirectory: rootDirectory,
      workloadID: workload.id
    )
    let persistedWorkloadData = try Data(
      contentsOf: directory.appendingPathComponent(workloadFileName)
    )
    let persistedWorkload = try JSONDecoder().decode(
      Workload.self,
      from: persistedWorkloadData
    )
    guard persistedWorkload == workload else {
      throw PreparedInputsError.persistedWorkloadMismatch(
        expectedID: workload.id,
        actualID: persistedWorkload.id
      )
    }
    let persistedDescriptor = try loadWorkloadDescriptor(
      workloadID: workload.id,
      from: rootDirectory
    )
    guard persistedDescriptor == workload.descriptor else {
      throw PreparedInputsError.persistedDescriptorMismatch(
        workloadID: workload.id
      )
    }

    let semanticJSON = try Data(
      contentsOf: directory.appendingPathComponent(semanticJSONFileName)
    )
    let semanticBinaryPropertyList = try Data(
      contentsOf: directory.appendingPathComponent(
        semanticBinaryPropertyListFileName
      )
    )
    let prototypeCache = try Data(
      contentsOf: directory.appendingPathComponent(prototypeCacheFileName)
    )

    var fallbackCaches: [BenchmarkOperation: Data] = [:]
    for operation in BenchmarkOperation.fallbackCases {
      let fileURL = directory.appendingPathComponent(
        operation.preparedFileName
      )
      if FileManager.default.fileExists(atPath: fileURL.path) {
        fallbackCaches[operation] = try Data(contentsOf: fileURL)
      }
    }

    return PreparedInputs(
      workload: persistedWorkload,
      semanticJSON: semanticJSON,
      semanticBinaryPropertyList: semanticBinaryPropertyList,
      prototypeCache: prototypeCache,
      fallbackCaches: fallbackCaches
    )
  }

  /// Loads and structurally validates the small persisted descriptor without
  /// generating or retaining the workload's authoritative source strings.
  package static func loadWorkloadDescriptor(
    workloadID: String,
    from rootDirectory: URL
  ) throws -> WorkloadDescriptor {
    let directory = try workloadDirectory(
      rootDirectory: rootDirectory,
      workloadID: workloadID
    )
    let descriptorData = try Data(
      contentsOf: directory.appendingPathComponent(
        workloadDescriptorFileName
      )
    )
    let descriptor = try JSONDecoder().decode(
      WorkloadDescriptor.self,
      from: descriptorData
    )
    try descriptor.verify(expectedID: workloadID)
    return descriptor
  }

  package static func preparedWorkloadIDs(
    in rootDirectory: URL
  ) throws -> [String] {
    let fileManager = FileManager.default
    guard fileManager.fileExists(atPath: rootDirectory.path) else {
      return []
    }

    let children = try fileManager.contentsOfDirectory(
      at: rootDirectory,
      includingPropertiesForKeys: [.isDirectoryKey],
      options: [.skipsHiddenFiles]
    )
    return try children.compactMap { child -> String? in
      let values = try child.resourceValues(forKeys: [.isDirectoryKey])
      guard values.isDirectory == true else {
        return nil
      }
      let descriptorURL = child.appendingPathComponent(
        workloadDescriptorFileName
      )
      guard fileManager.fileExists(atPath: descriptorURL.path) else {
        return nil
      }
      return child.lastPathComponent
    }.sorted()
  }

  package func write(
    to rootDirectory: URL
  ) throws {
    let directory = try Self.workloadDirectory(
      rootDirectory: rootDirectory,
      workloadID: workload.id
    )
    try FileManager.default.createDirectory(
      at: directory,
      withIntermediateDirectories: true
    )

    let workloadEncoder = JSONEncoder()
    workloadEncoder.outputFormatting = [
      .prettyPrinted,
      .sortedKeys,
      .withoutEscapingSlashes,
    ]
    try workloadEncoder.encode(workload).write(
      to: directory.appendingPathComponent(Self.workloadFileName),
      options: .atomic
    )
    try workloadEncoder.encode(workload.descriptor).write(
      to: directory.appendingPathComponent(
        Self.workloadDescriptorFileName
      ),
      options: .atomic
    )
    try semanticJSON.write(
      to: directory.appendingPathComponent(Self.semanticJSONFileName),
      options: .atomic
    )
    try semanticBinaryPropertyList.write(
      to: directory.appendingPathComponent(
        Self.semanticBinaryPropertyListFileName
      ),
      options: .atomic
    )
    try prototypeCache.write(
      to: directory.appendingPathComponent(Self.prototypeCacheFileName),
      options: .atomic
    )

    for (operation, cache) in fallbackCaches {
      try cache.write(
        to: directory.appendingPathComponent(operation.preparedFileName),
        options: .atomic
      )
    }
    for operation in BenchmarkOperation.fallbackCases
    where fallbackCaches[operation] == nil {
      let staleFile = directory.appendingPathComponent(
        operation.preparedFileName
      )
      if FileManager.default.fileExists(atPath: staleFile.path) {
        try FileManager.default.removeItem(at: staleFile)
      }
    }
  }

  package func encodedByteCount(
    for operation: BenchmarkOperation
  ) throws -> Int {
    switch operation {
    case .directParse:
      semanticJSON.count
    case .semanticJSON:
      semanticJSON.count
    case .semanticBinaryPropertyList:
      semanticBinaryPropertyList.count
    case .prototypeCache:
      semanticJSON.count + prototypeCache.count
    default:
      semanticJSON.count + (try fallbackCache(for: operation).count)
    }
  }

  func fallbackCache(
    for operation: BenchmarkOperation
  ) throws -> Data {
    guard let cache = fallbackCaches[operation] else {
      throw PreparedInputsError.unavailableOperation(
        workloadID: workload.id,
        operation: operation
      )
    }
    return cache
  }

  private init(
    workload: Workload,
    semanticJSON: Data,
    semanticBinaryPropertyList: Data,
    prototypeCache: Data,
    fallbackCaches: [BenchmarkOperation: Data]
  ) {
    self.workload = workload
    self.semanticJSON = semanticJSON
    self.semanticBinaryPropertyList = semanticBinaryPropertyList
    self.prototypeCache = prototypeCache
    self.fallbackCaches = fallbackCaches
  }

  private static func makeFallbackCaches(
    validCache: Data
  ) throws -> [BenchmarkOperation: Data] {
    var result: [BenchmarkOperation: Data] = [:]

    for (operation, fault) in requiredFallbackFaults {
      result[operation] = try CompiledCachePrototype.applying(
        fault,
        to: validCache
      )
    }

    for (operation, fault) in expressionFallbackFaults {
      // Literal-only one-entry workloads cannot host expression-structure
      // mutations. Expression faults are advertised only when constructible.
      if let cache = try? CompiledCachePrototype.applying(
        fault,
        to: validCache
      ) {
        result[operation] = cache
      }
    }

    return result
  }

  private static let requiredFallbackFaults: [(BenchmarkOperation, CompiledCacheFault)] = [
    (.prototypeCacheTruncatedFallback, .truncated),
    (.prototypeCacheCorruptFallback, .corruptIntegrity),
    (
      .prototypeCacheWrongVersionFallback,
      .unsupportedVersion(CompiledCachePrototype.currentFormatVersion + 1)
    ),
    (.prototypeCacheStaleFallback, .authoritativeSourceMismatch),
    (.prototypeCacheSourceMismatchFallback, .payloadSourceMismatch),
  ]

  private static let expressionFallbackFaults: [(BenchmarkOperation, CompiledCacheFault)] = [
    (.prototypeCacheUnknownOperatorFallback, .unknownOperator),
    (.prototypeCacheUnknownModifierFallback, .unknownModifier),
    (.prototypeCacheInvalidPrefixFallback, .invalidPrefix(0)),
    (.prototypeCacheEmptyExpressionFallback, .emptyExpression),
  ]

  static let workloadFileName = "workload.json"
  static let workloadDescriptorFileName = "workload-metadata.json"
  static let semanticJSONFileName = "semantic.json"
  static let semanticBinaryPropertyListFileName =
    "semantic.binary.plist"
  static let prototypeCacheFileName = "prototype.cache"

  static func workloadDirectory(
    rootDirectory: URL,
    workloadID: String
  ) throws -> URL {
    guard
      !workloadID.isEmpty,
      workloadID.allSatisfy({
        $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "-")
      })
    else {
      throw PreparedInputsError.invalidWorkloadID(workloadID)
    }
    return rootDirectory.appendingPathComponent(
      workloadID,
      isDirectory: true
    )
  }
}

package enum PreparedInputsError: Error, Equatable, CustomStringConvertible, Sendable {
  case invalidWorkloadID(String)
  case persistedWorkloadMismatch(expectedID: String, actualID: String)
  case persistedDescriptorMismatch(workloadID: String)
  case resultTemplateCountMismatch(
    workloadID: String,
    expected: Int,
    actual: Int
  )
  case semanticSourceMismatch(workloadID: String)
  case unavailableOperation(
    workloadID: String,
    operation: BenchmarkOperation
  )

  package var description: String {
    switch self {
    case .invalidWorkloadID(let workloadID):
      "Invalid prepared-workload identifier: \(workloadID)"
    case .persistedWorkloadMismatch(let expectedID, let actualID):
      """
      Prepared workload does not match \(expectedID); found \(actualID).
      """
    case .persistedDescriptorMismatch(let workloadID):
      """
      Prepared workload descriptor does not match workload \(workloadID).
      """
    case .resultTemplateCountMismatch(
      let workloadID,
      let expected,
      let actual
    ):
      """
      Fresh operation for \(workloadID) returned \(actual) templates; \
      expected \(expected).
      """
    case .semanticSourceMismatch(let workloadID):
      "Parsed semantic sources differ for workload \(workloadID)."
    case .unavailableOperation(let workloadID, let operation):
      """
      Operation \(operation.rawValue) is unavailable for workload \(workloadID).
      """
    }
  }
}
