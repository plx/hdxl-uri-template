import Foundation
import HDXLURITemplate

package let api03WorkloadSeed: UInt64 = 0x4844_584C_4150_4903

package enum WorkloadCorpusKind: String, CaseIterable, Codable, Hashable, Sendable {
  case balanced
  case allRepeated = "all-repeated"
  case allUnique = "all-unique"
}

package struct WorkloadCategoryCounts: Codable, Equatable, Hashable, Sendable {
  package let literalOnlyASCII: Int
  package let literalOnlyUnicode: Int
  package let simpleOperator: Int
  package let reservedOperator: Int
  package let fragmentOperator: Int
  package let labelOperator: Int
  package let pathSegmentOperator: Int
  package let pathParameterOperator: Int
  package let queryOperator: Int
  package let queryContinuationOperator: Int
  package let shortVariableLists: Int
  package let longVariableLists: Int
  package let explodeModifiers: Int
  package let prefixModifiers: Int
  package let uniqueSources: Int
  package let repeatedOccurrences: Int

  package var templateCount: Int {
    literalOnlyASCII
      + literalOnlyUnicode
      + simpleOperator
      + reservedOperator
      + fragmentOperator
      + labelOperator
      + pathSegmentOperator
      + pathParameterOperator
      + queryOperator
      + queryContinuationOperator
  }

  package var expressionTemplateCount: Int {
    simpleOperator
      + reservedOperator
      + fragmentOperator
      + labelOperator
      + pathSegmentOperator
      + pathParameterOperator
      + queryOperator
      + queryContinuationOperator
  }
}

package struct WorkloadDescriptor:
  Codable,
  Equatable,
  Hashable,
  Sendable
{
  package let id: String
  package let size: Int
  package let kind: WorkloadCorpusKind
  package let seed: UInt64
  package let categoryCounts: WorkloadCategoryCounts
  package let authoritativeUTF8ByteCount: Int
  package let corpusDigest: String

  package init(workload: Workload) {
    self.id = workload.id
    self.size = workload.size
    self.kind = workload.kind
    self.seed = workload.seed
    self.categoryCounts = workload.categoryCounts
    self.authoritativeUTF8ByteCount = workload.authoritativeUTF8ByteCount
    self.corpusDigest = workload.corpusDigest
  }

  package func verify(expectedID: String) throws {
    try Workloads.verify(
      descriptor: self,
      expectedID: expectedID
    )
  }
}

package struct Workload: Codable, Equatable, Hashable, Sendable {
  package let id: String
  package let size: Int
  package let kind: WorkloadCorpusKind
  package let seed: UInt64
  package let sources: [String]
  package let categoryCounts: WorkloadCategoryCounts
  package let corpusDigest: String

  package var authoritativeUTF8ByteCount: Int {
    sources.reduce(into: 0) { byteCount, source in
      byteCount += source.utf8.count
    }
  }

  package var descriptor: WorkloadDescriptor {
    WorkloadDescriptor(workload: self)
  }

  package func verify() throws {
    guard size == sources.count else {
      throw WorkloadVerificationError.incorrectSize(
        id: id,
        declared: size,
        actual: sources.count
      )
    }

    let expected = Workloads.make(kind: kind, size: size)
    guard self == expected else {
      throw WorkloadVerificationError.generationMismatch(id: id)
    }

    let uniqueSourceCount = Set(sources).count
    guard categoryCounts.uniqueSources == uniqueSourceCount,
      categoryCounts.repeatedOccurrences == size - uniqueSourceCount
    else {
      throw WorkloadVerificationError.incorrectRepetitionCounts(
        id: id,
        declaredUnique: categoryCounts.uniqueSources,
        actualUnique: uniqueSourceCount,
        declaredRepeated: categoryCounts.repeatedOccurrences,
        actualRepeated: size - uniqueSourceCount
      )
    }

    let digest = Workloads.digest(sources: sources)
    guard corpusDigest == digest else {
      throw WorkloadVerificationError.incorrectDigest(
        id: id,
        declared: corpusDigest,
        actual: digest
      )
    }

    for (index, source) in sources.enumerated() {
      do {
        _ = try URITemplate(parsing: source)
      } catch {
        throw WorkloadVerificationError.invalidTemplate(
          id: id,
          index: index,
          source: source
        )
      }
    }
  }
}

package enum WorkloadVerificationError: Error, Equatable, CustomStringConvertible, Sendable {
  case unsupportedSize(kind: WorkloadCorpusKind, size: Int)
  case descriptorIDMismatch(expected: String, actual: String)
  case noncanonicalDescriptorID(
    actual: String,
    kind: WorkloadCorpusKind,
    size: Int
  )
  case descriptorSeedMismatch(id: String, declared: UInt64, expected: UInt64)
  case descriptorCategoryCountsMismatch(id: String)
  case authoritativeUTF8ByteCountMismatch(
    id: String,
    declared: Int,
    expected: Int
  )
  case corpusDigestMismatch(
    id: String,
    declared: String,
    expected: String
  )
  case incorrectSize(id: String, declared: Int, actual: Int)
  case generationMismatch(id: String)
  case incorrectRepetitionCounts(
    id: String,
    declaredUnique: Int,
    actualUnique: Int,
    declaredRepeated: Int,
    actualRepeated: Int
  )
  case incorrectDigest(id: String, declared: String, actual: String)
  case invalidTemplate(id: String, index: Int, source: String)

  package var description: String {
    switch self {
    case .unsupportedSize(let kind, let size):
      "Unsupported API-03 workload size \(size) for \(kind.rawValue)."
    case .descriptorIDMismatch(let expected, let actual):
      "Prepared workload descriptor \(actual) does not match \(expected)."
    case .noncanonicalDescriptorID(let actual, let kind, let size):
      """
      Prepared workload descriptor \(actual) is not the canonical identifier \
      \(kind.rawValue)-\(size).
      """
    case .descriptorSeedMismatch(let id, let declared, let expected):
      """
      Workload descriptor \(id) seed differs: \(declared) != \(expected).
      """
    case .descriptorCategoryCountsMismatch(let id):
      "Workload descriptor \(id) has inconsistent category counts."
    case .authoritativeUTF8ByteCountMismatch(
      let id,
      let declared,
      let expected
    ):
      """
      Workload descriptor \(id) authoritative UTF-8 byte count differs: \
      \(declared) != \(expected).
      """
    case .corpusDigestMismatch(let id, let declared, let expected):
      """
      Workload descriptor \(id) corpus digest differs: \(declared) != \
      \(expected).
      """
    case .incorrectSize(let id, let declared, let actual):
      "Workload \(id) declares \(declared) templates but contains \(actual)."
    case .generationMismatch(let id):
      "Workload \(id) does not match the fixed-seed generated contract."
    case .incorrectRepetitionCounts(
      let id,
      let declaredUnique,
      let actualUnique,
      let declaredRepeated,
      let actualRepeated
    ):
      """
      Workload \(id) repetition counts differ: unique \(declaredUnique)/\
      \(actualUnique), repeated \(declaredRepeated)/\(actualRepeated).
      """
    case .incorrectDigest(let id, let declared, let actual):
      "Workload \(id) digest differs: \(declared) != \(actual)."
    case .invalidTemplate(let id, let index, let source):
      "Workload \(id) contains an invalid template at \(index): \(source)"
    }
  }
}

package enum Workloads {
  package static let balancedSizes = [1, 10, 100, 1_000, 10_000]
  package static let sensitivitySizes = [1_000, 10_000]

  package static let full: [Workload] = {
    balancedSizes.map { make(kind: .balanced, size: $0) }
      + sensitivitySizes.flatMap { size in
        [
          make(kind: .allRepeated, size: size),
          make(kind: .allUnique, size: size),
        ]
      }
  }()

  package static let quick: [Workload] =
    balancedSizes
    .filter { $0 <= 100 }
    .map { make(kind: .balanced, size: $0) }

  package static func workload(
    kind: WorkloadCorpusKind,
    size: Int
  ) throws -> Workload {
    let supportedSizes: [Int]
    switch kind {
    case .balanced:
      supportedSizes = balancedSizes
    case .allRepeated, .allUnique:
      supportedSizes = sensitivitySizes
    }
    guard supportedSizes.contains(size) else {
      throw WorkloadVerificationError.unsupportedSize(kind: kind, size: size)
    }
    return make(kind: kind, size: size)
  }

  package static func verifyGenerated() throws {
    guard Set(full.map(\.id)).count == full.count else {
      throw WorkloadVerificationError.generationMismatch(
        id: "duplicate-workload-id"
      )
    }
    for workload in full {
      try workload.verify()
    }
  }

  package static func digest(sources: [String]) -> String {
    StableDigest.hex(
      StableDigest.sha256(
        lengthPrefixed: sources.map { Data($0.utf8) }
      )
    )
  }

  fileprivate static func verify(
    descriptor: WorkloadDescriptor,
    expectedID: String
  ) throws {
    guard descriptor.id == expectedID else {
      throw WorkloadVerificationError.descriptorIDMismatch(
        expected: expectedID,
        actual: descriptor.id
      )
    }

    guard supports(kind: descriptor.kind, size: descriptor.size) else {
      throw WorkloadVerificationError.unsupportedSize(
        kind: descriptor.kind,
        size: descriptor.size
      )
    }

    let canonicalID = "\(descriptor.kind.rawValue)-\(descriptor.size)"
    guard descriptor.id == canonicalID else {
      throw WorkloadVerificationError.noncanonicalDescriptorID(
        actual: descriptor.id,
        kind: descriptor.kind,
        size: descriptor.size
      )
    }

    guard descriptor.seed == api03WorkloadSeed else {
      throw WorkloadVerificationError.descriptorSeedMismatch(
        id: descriptor.id,
        declared: descriptor.seed,
        expected: api03WorkloadSeed
      )
    }

    let uniqueSourceCount = expectedUniqueSourceCount(
      kind: descriptor.kind,
      size: descriptor.size
    )
    guard
      descriptor.categoryCounts
        == categoryCounts(
          size: descriptor.size,
          uniqueSources: uniqueSourceCount
        )
    else {
      throw WorkloadVerificationError.descriptorCategoryCountsMismatch(
        id: descriptor.id
      )
    }

    guard let pin = descriptorPin(id: descriptor.id) else {
      throw WorkloadVerificationError.generationMismatch(id: descriptor.id)
    }

    guard descriptor.authoritativeUTF8ByteCount == pin.authoritativeUTF8ByteCount
    else {
      throw WorkloadVerificationError.authoritativeUTF8ByteCountMismatch(
        id: descriptor.id,
        declared: descriptor.authoritativeUTF8ByteCount,
        expected: pin.authoritativeUTF8ByteCount
      )
    }

    guard descriptor.corpusDigest == pin.corpusDigest else {
      throw WorkloadVerificationError.corpusDigestMismatch(
        id: descriptor.id,
        declared: descriptor.corpusDigest,
        expected: pin.corpusDigest
      )
    }
  }

  private static func supports(
    kind: WorkloadCorpusKind,
    size: Int
  ) -> Bool {
    switch kind {
    case .balanced:
      balancedSizes.contains(size)
    case .allRepeated, .allUnique:
      sensitivitySizes.contains(size)
    }
  }

  private static func expectedUniqueSourceCount(
    kind: WorkloadCorpusKind,
    size: Int
  ) -> Int {
    switch kind {
    case .balanced:
      size < 100 ? size : size - (size / 4)
    case .allRepeated:
      min(size, WorkloadArchetype.allCases.count)
    case .allUnique:
      size
    }
  }

  private struct DescriptorPin {
    let authoritativeUTF8ByteCount: Int
    let corpusDigest: String
  }

  private static func descriptorPin(id: String) -> DescriptorPin? {
    switch id {
    case "balanced-1":
      DescriptorPin(
        authoritativeUTF8ByteCount: 55,
        corpusDigest:
          "2f37db2ec67d4d0681905cfd419231f9265c81c70dc63a07d19f9905858c2799"
      )
    case "balanced-10":
      DescriptorPin(
        authoritativeUTF8ByteCount: 727,
        corpusDigest:
          "53d0f546f4d8dcc3747e0f9864b55fdc24b0ad29b250a2ec0e34e8ee6f359c5a"
      )
    case "balanced-100":
      DescriptorPin(
        authoritativeUTF8ByteCount: 7_270,
        corpusDigest:
          "230d0f04ce6634c515917cb593e418dd534e29f63350fba64cf24bc4071af10b"
      )
    case "balanced-1000":
      DescriptorPin(
        authoritativeUTF8ByteCount: 72_700,
        corpusDigest:
          "8892a5bed2e0c2db945364e319be9d55a367cac34ef2ffaa8faf65cd68c2723b"
      )
    case "balanced-10000":
      DescriptorPin(
        authoritativeUTF8ByteCount: 727_000,
        corpusDigest:
          "78b035cc47584ca769643cecbbbdc19057568f4d84b3d9275f2f9e1ad459e704"
      )
    case "all-repeated-1000":
      DescriptorPin(
        authoritativeUTF8ByteCount: 72_700,
        corpusDigest:
          "12504c0f2f3fbecb5ff7cc9cba8ed1fe490f4710b5033c5c781dd3c29093c25b"
      )
    case "all-unique-1000":
      DescriptorPin(
        authoritativeUTF8ByteCount: 72_700,
        corpusDigest:
          "94373c6840e46676a35621cc8fe0a9baca8a5ecb3df989137298f14f2a59cfeb"
      )
    case "all-repeated-10000":
      DescriptorPin(
        authoritativeUTF8ByteCount: 727_000,
        corpusDigest:
          "f147a41fe97de58a94cea283fd55d9f28dbfb3598c1929c137894ecb879bdb1f"
      )
    case "all-unique-10000":
      DescriptorPin(
        authoritativeUTF8ByteCount: 727_000,
        corpusDigest:
          "d51ea8b412e54de834c1dafc592c41172600b919556a96707f4b57750475667a"
      )
    default:
      nil
    }
  }

  fileprivate static func make(
    kind: WorkloadCorpusKind,
    size: Int
  ) -> Workload {
    precondition(size > 0)

    let repeatedIndices = repeatedIndices(kind: kind, size: size)
    var sources: [String] = []
    sources.reserveCapacity(size)

    for index in 0..<size {
      let archetype = WorkloadArchetype.at(index: index)
      let identityIndex =
        repeatedIndices.contains(index)
        ? archetype.rawValue
        : index
      sources.append(
        archetype.source(identityIndex: identityIndex)
      )
    }

    let uniqueSources = Set(sources).count
    let counts = categoryCounts(
      size: size,
      uniqueSources: uniqueSources
    )
    return Workload(
      id: "\(kind.rawValue)-\(size)",
      size: size,
      kind: kind,
      seed: api03WorkloadSeed,
      sources: sources,
      categoryCounts: counts,
      corpusDigest: digest(sources: sources)
    )
  }

  private static func repeatedIndices(
    kind: WorkloadCorpusKind,
    size: Int
  ) -> Set<Int> {
    switch kind {
    case .allUnique:
      return []

    case .allRepeated:
      return size > 10 ? Set(10..<size) : []

    case .balanced:
      // The 1- and 10-entry correctness corpora stay all-unique so the first
      // complete block can retain all ten mutually-exclusive archetypes.
      guard size >= 100 else {
        return []
      }

      let repeatedOccurrenceCount = size / 4
      let rankedCandidates = (10..<size).sorted { lhs, rhs in
        let lhsRank = repetitionRank(index: lhs)
        let rhsRank = repetitionRank(index: rhs)
        return lhsRank == rhsRank ? lhs < rhs : lhsRank < rhsRank
      }
      return Set(rankedCandidates.prefix(repeatedOccurrenceCount))
    }
  }

  private static func repetitionRank(index: Int) -> UInt64 {
    splitMix64(
      api03WorkloadSeed
        ^ UInt64(index)
        ^ 0xA503_25A7_5EED_0001
    )
  }

  private static func categoryCounts(
    size: Int,
    uniqueSources: Int
  ) -> WorkloadCategoryCounts {
    func count(_ archetypes: Set<WorkloadArchetype>) -> Int {
      let fullBlocks = size / WorkloadArchetype.allCases.count
      let partialBlockCount = size % WorkloadArchetype.allCases.count
      return
        (fullBlocks * archetypes.count)
        + archetypes.reduce(into: 0) { result, archetype in
          if archetype.rawValue < partialBlockCount {
            result += 1
          }
        }
    }

    return WorkloadCategoryCounts(
      literalOnlyASCII: count([.literalASCII]),
      literalOnlyUnicode: count([.literalUnicode]),
      simpleOperator: count([.simple]),
      reservedOperator: count([.reserved]),
      fragmentOperator: count([.fragment]),
      labelOperator: count([.label]),
      pathSegmentOperator: count([.pathSegment]),
      pathParameterOperator: count([.pathParameter]),
      queryOperator: count([.query]),
      queryContinuationOperator: count([.queryContinuation]),
      shortVariableLists: count([.simple, .fragment, .label]),
      longVariableLists: count([
        .reserved,
        .pathSegment,
        .pathParameter,
        .query,
        .queryContinuation,
      ]),
      explodeModifiers: count([.label, .pathSegment, .query]),
      prefixModifiers: count([.reserved, .pathSegment, .query]),
      uniqueSources: uniqueSources,
      repeatedOccurrences: size - uniqueSources
    )
  }
}

private enum WorkloadArchetype: Int, CaseIterable, Hashable {
  case literalASCII
  case literalUnicode
  case simple
  case reserved
  case fragment
  case label
  case pathSegment
  case pathParameter
  case query
  case queryContinuation

  static func at(index: Int) -> WorkloadArchetype {
    allCases[index % allCases.count]
  }

  func source(identityIndex: Int) -> String {
    let token = stableToken(identityIndex: identityIndex)
    switch self {
    case .literalASCII:
      return "https://api.example.test/static/health/\(token)"
    case .literalUnicode:
      return "https://例え.example/資料/café/東京/\(token)"
    case .simple:
      return "https://api.example.test/items/{id}/\(token)"
    case .reserved:
      return """
        https://api.example.test/resolve/{+resource_path:12,tail,mode,locale}/\
        \(token)
        """
    case .fragment:
      return "https://api.example.test/document/\(token){#section}"
    case .label:
      return "https://api.example.test/releases{.segments*}/\(token)"
    case .pathSegment:
      return """
        https://api.example.test/accounts{/account_id,resource_name:8,items*,\
        locale}/\(token)
        """
    case .pathParameter:
      return """
        https://api.example.test/search/\(token){;language,encoding,empty,mode}
        """
    case .query:
      return """
        https://api.example.test/catalog/\(token)\
        {?search_query:16,limit,filters*,locale}
        """
    case .queryContinuation:
      return """
        https://api.example.test/catalog/\(token)\
        ?fixed=true{&page,page_size,sort_by,locale}
        """
    }
  }

  private func stableToken(identityIndex: Int) -> String {
    let mixed = splitMix64(
      api03WorkloadSeed
        ^ UInt64(identityIndex)
        ^ (UInt64(rawValue) &* 0xD6E8_FEB8_6659_FD93)
    )
    let unpadded = String(mixed, radix: 16, uppercase: false)
    return String(repeating: "0", count: 16 - unpadded.count) + unpadded
  }
}

private func splitMix64(_ input: UInt64) -> UInt64 {
  var value = input &+ 0x9E37_79B9_7F4A_7C15
  value = (value ^ (value >> 30)) &* 0xBF58_476D_1CE4_E5B9
  value = (value ^ (value >> 27)) &* 0x94D0_49BB_1331_11EB
  return value ^ (value >> 31)
}
