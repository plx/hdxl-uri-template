import Foundation
import HDXLURITemplate

package enum QA03ScalingRunner {

  package static func run(
    baseline: QA03ScalingBaseline,
    sampleCount: Int,
    commit: String
  ) throws -> QA03ScalingReport {
    guard sampleCount >= 3, sampleCount.isMultiple(of: 2) == false else {
      throw QA03Error("Scaling sample count must be an odd integer at least 3.")
    }

    let reports = try baseline.workloads.map { workload in
      try measure(
        workload: workload,
        sampleCount: sampleCount,
        maximumAdjacentRatio: baseline.maximumAdjacentRatio,
        maximumFittedExponent: baseline.maximumFittedExponent
      )
    }

    let failed = reports.filter { !$0.analysis.passed }
    guard failed.isEmpty else {
      let details = failed.map {
        "\($0.id)(ratios=\($0.analysis.adjacentRatios), "
          + "exponent=\($0.analysis.fittedExponent))"
      }.joined(separator: ", ")
      throw QA03Error(
        "Scaling gate rejected workload(s): \(details)."
      )
    }

    return QA03ScalingReport(
      schemaVersion: 1,
      command: "scaling",
      commit: commit,
      sampleCount: sampleCount,
      workloads: reports
    )
  }

  package static func verifyQuadraticDetector() throws
    -> QA03ScalingAnalysis
  {
    let analysis = try qa03AnalyzeScaling(
      sizes: [1_000, 2_000, 4_000, 8_000],
      durationsNanoseconds: [1_000, 4_000, 16_000, 64_000],
      maximumAdjacentRatio: 3.0,
      maximumFittedExponent: 1.25
    )
    guard !analysis.passed else {
      throw QA03Error(
        "The scaling analyzer accepted the isolated O(n²) equivalent."
      )
    }
    return analysis
  }

  private static func measure(
    workload: QA03ScalingBaseline.Workload,
    sampleCount: Int,
    maximumAdjacentRatio: Double,
    maximumFittedExponent: Double
  ) throws -> QA03ScalingReport.Workload {
    let configurations = try zip(
      workload.sizes,
      workload.repetitions
    ).map { size, repetitions in
      (
        repetitions: repetitions,
        operation: try operation(
          identifier: workload.id,
          size: size
        )
      )
    }
    var rawMeasurements = Array(
      repeating: [UInt64](),
      count: configurations.count
    )
    for index in configurations.indices {
      rawMeasurements[index].reserveCapacity(sampleCount)
      try configurations[index].operation()
    }

    // Rotate warmed sizes across rounds, and count only process CPU consumed
    // by each batch so shared-runner suspension cannot become workload time.
    for sampleIndex in 0..<sampleCount {
      for offset in configurations.indices {
        let index = (sampleIndex + offset) % configurations.count
        let configuration = configurations[index]
        let elapsed = try qa03MeasureProcessCPUTime {
          for _ in 0..<configuration.repetitions {
            try configuration.operation()
          }
        }
        rawMeasurements[index].append(
          max(
            1,
            elapsed / UInt64(configuration.repetitions)
          )
        )
      }
    }
    let medians = rawMeasurements.map {
      $0.sorted()[$0.count / 2]
    }
    let analysis = try qa03AnalyzeScaling(
      sizes: workload.sizes,
      durationsNanoseconds: medians,
      maximumAdjacentRatio: maximumAdjacentRatio,
      maximumFittedExponent: maximumFittedExponent
    )

    return QA03ScalingReport.Workload(
      id: workload.id,
      sizes: workload.sizes,
      repetitions: workload.repetitions,
      rawNanoseconds: rawMeasurements,
      medianNanoseconds: medians,
      analysis: analysis
    )
  }

  private static func operation(
    identifier: String,
    size: Int
  ) throws -> () throws -> Void {
    switch identifier {
    case "dense-valid-percent":
      let template = try URITemplate(parsing: "{+value}")
      let input = String(repeating: "%20", count: size)
      let parameters: [String: URIVariableValue] = [
        "value": .text(input)
      ]
      return {
        let output = try template.evaluateAsString(parameters: parameters)
        guard output.utf8.elementsEqual(input.utf8) else {
          throw QA03Error("Dense valid-percent expansion drifted.")
        }
      }

    case "dense-malformed-percent":
      let template = try URITemplate(parsing: "{+value}")
      let input = String(repeating: "%G", count: size)
      let expected = String(repeating: "%25G", count: size)
      let parameters: [String: URIVariableValue] = [
        "value": .text(input)
      ]
      return {
        let output = try template.evaluateAsString(parameters: parameters)
        guard output.utf8.elementsEqual(expected.utf8) else {
          throw QA03Error("Dense malformed-percent expansion drifted.")
        }
      }

    case "long-prefix":
      let template = try URITemplate(parsing: "{value:\(size)}")
      let input = String(repeating: "é", count: size + 1)
      let expected = String(repeating: "%C3%A9", count: size)
      let parameters: [String: URIVariableValue] = [
        "value": .text(input)
      ]
      return {
        let output = try template.evaluateAsString(parameters: parameters)
        guard output.utf8.elementsEqual(expected.utf8) else {
          throw QA03Error("Long-prefix expansion drifted.")
        }
      }

    case "regex-near-miss":
      let input = String(repeating: "a", count: size) + "{name%G}"
      return {
        do {
          _ = try URITemplate(parsing: input)
          throw QA03Error("Regex near-miss unexpectedly parsed.")
        } catch is URITemplate.ParseError {
          return
        }
      }

    case "large-list":
      let template = try URITemplate(parsing: "{/items*}")
      let values = (0..<size).map { "v\($0)" }
      let parameters: [String: URIVariableValue] = [
        "items": .list(values)
      ]
      return {
        let output = try template.evaluateAsString(parameters: parameters)
        guard output.hasPrefix("/v0/v1/") else {
          throw QA03Error("Large-list expansion drifted.")
        }
      }

    case "large-association":
      let template = try URITemplate(parsing: "{?pairs*}")
      let pairs = (0..<size).map { ("k\($0)", "v\($0)") }
      let parameters: [String: URIVariableValue] = [
        "pairs": try .association(pairs)
      ]
      return {
        let output = try template.evaluateAsString(parameters: parameters)
        guard output.hasPrefix("?k0=v0&k1=v1") else {
          throw QA03Error("Large-association expansion drifted.")
        }
      }

    default:
      throw QA03Error("Unknown scaling workload \(identifier).")
    }
  }
}

package func qa03MeasureProcessCPUTime(
  _ operation: () throws -> Void
) throws -> UInt64 {
  let start = try qa03ProcessCPUTime()
  try operation()
  let end = try qa03ProcessCPUTime()
  guard end >= start else {
    throw QA03Error("Process CPU clock moved backwards.")
  }
  return end - start
}

private func qa03ProcessCPUTime() throws -> UInt64 {
  var time = timespec()
  guard
    clock_gettime(CLOCK_PROCESS_CPUTIME_ID, &time) == 0,
    time.tv_sec >= 0,
    time.tv_nsec >= 0
  else {
    throw QA03Error("Process CPU clock was unavailable.")
  }
  return UInt64(time.tv_sec) * 1_000_000_000
    + UInt64(time.tv_nsec)
}
