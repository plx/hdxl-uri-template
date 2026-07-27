import Foundation

package struct QA03ScalingBaseline: Codable, Sendable {
  package let schemaVersion: Int
  package let maximumAdjacentRatio: Double
  package let maximumFittedExponent: Double
  package let workloads: [Workload]

  package struct Workload: Codable, Sendable {
    package let id: String
    package let sizes: [Int]
    package let repetitions: [Int]
  }

  package static func load(from url: URL) throws -> Self {
    let baseline = try JSONDecoder().decode(
      Self.self,
      from: Data(contentsOf: url)
    )
    guard
      baseline.schemaVersion == 1,
      baseline.maximumAdjacentRatio > 1,
      baseline.maximumFittedExponent > 1,
      !baseline.workloads.isEmpty
    else {
      throw QA03Error("Invalid QA-03 scaling baseline.")
    }
    for workload in baseline.workloads {
      guard
        workload.sizes.count >= 3,
        workload.sizes.count == workload.repetitions.count,
        zip(
          workload.sizes,
          workload.sizes.dropFirst()
        ).allSatisfy({ $0 < $1 }),
        workload.sizes.allSatisfy({ $0 > 0 }),
        workload.repetitions.allSatisfy({ $0 > 0 })
      else {
        throw QA03Error(
          "Invalid sizes or repetitions for \(workload.id)."
        )
      }
    }
    return baseline
  }
}

package struct QA03ScalingAnalysis: Codable, Sendable {
  package let adjacentRatios: [Double]
  package let fittedExponent: Double
  package let maximumAdjacentRatio: Double
  package let maximumFittedExponent: Double
  package let passed: Bool
}

package func qa03AnalyzeScaling(
  sizes: [Int],
  durationsNanoseconds: [UInt64],
  maximumAdjacentRatio: Double,
  maximumFittedExponent: Double
) throws -> QA03ScalingAnalysis {
  guard
    sizes.count >= 3,
    sizes.count == durationsNanoseconds.count,
    zip(sizes, sizes.dropFirst()).allSatisfy({ $0 < $1 }),
    sizes.allSatisfy({ $0 > 0 }),
    durationsNanoseconds.allSatisfy({ $0 > 0 })
  else {
    throw QA03Error("Scaling analysis received invalid measurements.")
  }

  let durations = durationsNanoseconds.map(Double.init)
  let adjacentRatios = zip(
    durations.dropFirst(),
    durations.dropLast()
  ).map { $0 / $1 }
  let logarithmicSizes = sizes.map { log(Double($0)) }
  let logarithmicDurations = durations.map(log)
  let meanSize =
    logarithmicSizes.reduce(0, +) / Double(logarithmicSizes.count)
  let meanDuration =
    logarithmicDurations.reduce(0, +)
    / Double(logarithmicDurations.count)
  let covariance = zip(
    logarithmicSizes,
    logarithmicDurations
  ).reduce(0.0) { partialResult, point in
    partialResult
      + (point.0 - meanSize) * (point.1 - meanDuration)
  }
  let sizeVariance = logarithmicSizes.reduce(0.0) {
    $0 + pow($1 - meanSize, 2)
  }
  let fittedExponent = covariance / sizeVariance
  let passed =
    adjacentRatios.allSatisfy { $0 <= maximumAdjacentRatio }
    && fittedExponent <= maximumFittedExponent

  return QA03ScalingAnalysis(
    adjacentRatios: adjacentRatios,
    fittedExponent: fittedExponent,
    maximumAdjacentRatio: maximumAdjacentRatio,
    maximumFittedExponent: maximumFittedExponent,
    passed: passed
  )
}

package struct QA03ScalingReport: Codable, Sendable {
  package let schemaVersion: Int
  package let command: String
  package let commit: String
  package let sampleCount: Int
  package let workloads: [Workload]

  package struct Workload: Codable, Sendable {
    package let id: String
    package let sizes: [Int]
    package let repetitions: [Int]
    package let rawNanoseconds: [[UInt64]]
    package let medianNanoseconds: [UInt64]
    package let analysis: QA03ScalingAnalysis
  }
}
