import Foundation
import HDXLURITemplate

package enum BenchmarkOperation:
  String,
  CaseIterable,
  Codable,
  Hashable,
  Sendable
{
  case directParse = "direct-parse"
  case semanticJSON = "semantic-json"
  case semanticBinaryPropertyList = "semantic-binary-property-list"
  case prototypeCache = "prototype-cache"

  case prototypeCacheTruncatedFallback =
    "prototype-cache-truncated-fallback"
  case prototypeCacheCorruptFallback =
    "prototype-cache-corrupt-fallback"
  case prototypeCacheWrongVersionFallback =
    "prototype-cache-wrong-version-fallback"
  case prototypeCacheStaleFallback =
    "prototype-cache-stale-fallback"
  case prototypeCacheSourceMismatchFallback =
    "prototype-cache-source-mismatch-fallback"
  case prototypeCacheUnknownOperatorFallback =
    "prototype-cache-unknown-operator-fallback"
  case prototypeCacheUnknownModifierFallback =
    "prototype-cache-unknown-modifier-fallback"
  case prototypeCacheInvalidPrefixFallback =
    "prototype-cache-invalid-prefix-fallback"
  case prototypeCacheEmptyExpressionFallback =
    "prototype-cache-empty-expression-fallback"

  package static let primaryCases: [BenchmarkOperation] = [
    .directParse,
    .semanticJSON,
    .semanticBinaryPropertyList,
    .prototypeCache,
  ]

  package static let fallbackCases: [BenchmarkOperation] = allCases.filter {
    !primaryCases.contains($0)
  }

  package var isPrimary: Bool {
    Self.primaryCases.contains(self)
  }

  package var isFallback: Bool {
    !isPrimary
  }

  package var preparedFileName: String {
    switch self {
    case .directParse:
      "workload.json"
    case .semanticJSON:
      "semantic.json"
    case .semanticBinaryPropertyList:
      "semantic.binary.plist"
    case .prototypeCache:
      "prototype.cache"
    case .prototypeCacheTruncatedFallback:
      "prototype.truncated.cache"
    case .prototypeCacheCorruptFallback:
      "prototype.corrupt.cache"
    case .prototypeCacheWrongVersionFallback:
      "prototype.wrong-version.cache"
    case .prototypeCacheStaleFallback:
      "prototype.stale.cache"
    case .prototypeCacheSourceMismatchFallback:
      "prototype.source-mismatch.cache"
    case .prototypeCacheUnknownOperatorFallback:
      "prototype.unknown-operator.cache"
    case .prototypeCacheUnknownModifierFallback:
      "prototype.unknown-modifier.cache"
    case .prototypeCacheInvalidPrefixFallback:
      "prototype.invalid-prefix.cache"
    case .prototypeCacheEmptyExpressionFallback:
      "prototype.empty-expression.cache"
    }
  }
}

package enum BenchmarkCacheOutcome:
  String,
  Codable,
  Equatable,
  Hashable,
  CustomStringConvertible,
  Sendable
{
  case notApplicable = "not-applicable"
  case hit
  case fallbackDecodeOrTruncated = "fallback-decode-or-truncated"
  case fallbackUnsupportedVersion = "fallback-unsupported-version"
  case fallbackIntegrityMismatch = "fallback-integrity-mismatch"
  case fallbackAuthoritativeSourceMismatch =
    "fallback-authoritative-source-mismatch"
  case fallbackPayloadSourceMismatch = "fallback-payload-source-mismatch"
  case fallbackStructuralValidation = "fallback-structural-validation"

  package var description: String {
    rawValue
  }

  fileprivate init(_ outcome: CompiledCacheOutcome) {
    switch outcome {
    case .hit:
      self = .hit
    case .fallback(.decodeOrTruncated):
      self = .fallbackDecodeOrTruncated
    case .fallback(.unsupportedVersion):
      self = .fallbackUnsupportedVersion
    case .fallback(.integrityMismatch):
      self = .fallbackIntegrityMismatch
    case .fallback(.authoritativeSourceMismatch):
      self = .fallbackAuthoritativeSourceMismatch
    case .fallback(.payloadSourceMismatch):
      self = .fallbackPayloadSourceMismatch
    case .fallback(.structuralValidation):
      self = .fallbackStructuralValidation
    }
  }
}

package struct OperationResult:
  Codable,
  Equatable,
  Hashable,
  Sendable
{
  package let digest: String
  package let templateCount: Int
  package let cacheOutcome: BenchmarkCacheOutcome
  package let encodedBytes: Int

  package init(
    digest: String,
    templateCount: Int,
    cacheOutcome: BenchmarkCacheOutcome,
    encodedBytes: Int
  ) {
    self.digest = digest
    self.templateCount = templateCount
    self.cacheOutcome = cacheOutcome
    self.encodedBytes = encodedBytes
  }
}

extension PreparedInputs {
  /// Reads and executes exactly one persisted lane.
  ///
  /// This is the fresh-process entry point. It deliberately avoids the
  /// load-once `PreparedInputs.load(workload:from:)` API because that warm
  /// setup API reads every lane's artifact. `descriptor` must have been
  /// validated by `PreparedInputs.loadWorkloadDescriptor(workloadID:from:)`.
  @inline(never)
  package static func executeFresh(
    _ operation: BenchmarkOperation,
    descriptor: WorkloadDescriptor,
    from rootDirectory: URL
  ) throws -> OperationResult {
    let directory = try workloadDirectory(
      rootDirectory: rootDirectory,
      workloadID: descriptor.id
    )

    let operationResult: OperationResult
    switch operation {
    case .directParse:
      let sourceData = try Data(
        contentsOf: directory.appendingPathComponent(semanticJSONFileName)
      )
      let sources = try JSONDecoder().decode(
        [String].self,
        from: sourceData
      )
      operationResult = result(
        summarizing: try sources.map {
          try URITemplate(parsing: $0)
        },
        encodedBytes: sourceData.count
      )

    case .semanticJSON:
      let semanticData = try Data(
        contentsOf: directory.appendingPathComponent(semanticJSONFileName)
      )
      operationResult = result(
        summarizing: try JSONDecoder().decode(
          [URITemplate].self,
          from: semanticData
        ),
        encodedBytes: semanticData.count
      )

    case .semanticBinaryPropertyList:
      let semanticData = try Data(
        contentsOf: directory.appendingPathComponent(
          semanticBinaryPropertyListFileName
        )
      )
      operationResult = result(
        summarizing: try PropertyListDecoder().decode(
          [URITemplate].self,
          from: semanticData
        ),
        encodedBytes: semanticData.count
      )

    case .prototypeCache:
      operationResult = try executeFreshCache(
        at: directory.appendingPathComponent(prototypeCacheFileName),
        authoritativeSourceURL: directory.appendingPathComponent(
          semanticJSONFileName
        )
      )

    default:
      operationResult = try executeFreshCache(
        at: directory.appendingPathComponent(operation.preparedFileName),
        authoritativeSourceURL: directory.appendingPathComponent(
          semanticJSONFileName
        )
      )
    }

    guard operationResult.templateCount == descriptor.size else {
      throw PreparedInputsError.resultTemplateCountMismatch(
        workloadID: descriptor.id,
        expected: descriptor.size,
        actual: operationResult.templateCount
      )
    }
    return operationResult
  }

  /// Source-compatible bridge for callers that already hold a generated
  /// workload. Fresh-process benchmark children use the descriptor overload.
  @inline(never)
  package static func executeFresh(
    _ operation: BenchmarkOperation,
    workload: Workload,
    from rootDirectory: URL
  ) throws -> OperationResult {
    let descriptor = workload.descriptor
    try descriptor.verify(expectedID: workload.id)
    return try executeFresh(
      operation,
      descriptor: descriptor,
      from: rootDirectory
    )
  }

  @inline(never)
  package func execute(
    _ operation: BenchmarkOperation
  ) throws -> OperationResult {
    switch operation {
    case .directParse:
      return try Self.result(
        summarizing: workload.sources.map {
          try URITemplate(parsing: $0)
        },
        encodedBytes: semanticJSON.count
      )

    case .semanticJSON:
      return try Self.result(
        summarizing: JSONDecoder().decode(
          [URITemplate].self,
          from: semanticJSON
        ),
        encodedBytes: semanticJSON.count
      )

    case .semanticBinaryPropertyList:
      return try Self.result(
        summarizing: PropertyListDecoder().decode(
          [URITemplate].self,
          from: semanticBinaryPropertyList
        ),
        encodedBytes: semanticBinaryPropertyList.count
      )

    case .prototypeCache:
      return try Self.result(
        loading: prototypeCache,
        authoritativeSources: workload.sources,
        encodedBytes: semanticJSON.count + prototypeCache.count
      )

    default:
      let cache = try fallbackCache(for: operation)
      return try Self.result(
        loading: cache,
        authoritativeSources: workload.sources,
        encodedBytes: semanticJSON.count + cache.count
      )
    }
  }

  private static func executeFreshCache(
    at cacheURL: URL,
    authoritativeSourceURL: URL
  ) throws -> OperationResult {
    let authoritativeSourceData = try Data(
      contentsOf: authoritativeSourceURL
    )
    let cache = try Data(contentsOf: cacheURL)
    let authoritativeSources = try JSONDecoder().decode(
      [String].self,
      from: authoritativeSourceData
    )
    return try result(
      loading: cache,
      authoritativeSources: authoritativeSources,
      encodedBytes: authoritativeSourceData.count + cache.count
    )
  }

  private static func result(
    summarizing templates: [URITemplate],
    encodedBytes: Int
  ) -> OperationResult {
    let summary = CompiledCachePrototype.summarize(templates)
    return OperationResult(
      digest: summary.stableResultDigest,
      templateCount: summary.sources.count,
      cacheOutcome: .notApplicable,
      encodedBytes: encodedBytes
    )
  }

  private static func result(
    loading cache: Data,
    authoritativeSources: [String],
    encodedBytes: Int
  ) throws -> OperationResult {
    let summary = try CompiledCachePrototype.load(
      cache,
      authoritativeSources: authoritativeSources,
      fallback: { sources in
        try sources.map {
          try URITemplate(parsing: $0)
        }
      }
    )
    return OperationResult(
      digest: summary.stableResultDigest,
      templateCount: summary.sources.count,
      cacheOutcome: BenchmarkCacheOutcome(summary.outcome),
      encodedBytes: encodedBytes
    )
  }
}
