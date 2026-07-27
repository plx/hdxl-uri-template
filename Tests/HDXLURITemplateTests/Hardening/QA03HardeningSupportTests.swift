import Foundation
import HDXLURITemplateQA03Support
import Testing

@Test("QA-03 deterministic generator reproduces streams and case seeds")
func qa03DeterministicGeneratorReproducesStreams() {
  var first = QA03DeterministicGenerator(seed: 0x4844_584C_5141_3033)
  var second = QA03DeterministicGenerator(seed: 0x4844_584C_5141_3033)

  #expect((0..<32).map { _ in first.next() } == (0..<32).map { _ in second.next() })
  #expect(
    QA03DeterministicGenerator.caseSeed(
      rootSeed: 0x4844_584C_5141_3033,
      index: 37
    )
      == QA03DeterministicGenerator.caseSeed(
        rootSeed: 0x4844_584C_5141_3033,
        index: 37
      )
  )
}

@Test("QA-03 scaling analyzer accepts linear growth")
func qa03ScalingAnalyzerAcceptsLinearGrowth() throws {
  let analysis = try qa03AnalyzeScaling(
    sizes: [1_000, 2_000, 4_000, 8_000],
    durationsNanoseconds: [1_000, 2_000, 4_000, 8_000],
    maximumAdjacentRatio: 3.0,
    maximumFittedExponent: 1.25
  )

  #expect(analysis.passed)
  #expect(abs(analysis.fittedExponent - 1.0) < 0.000_001)
}

@Test("QA-03 scaling detector rejects an isolated quadratic equivalent")
func qa03ScalingDetectorRejectsQuadraticGrowth() throws {
  let analysis = try QA03ScalingRunner.verifyQuadraticDetector()

  #expect(!analysis.passed)
  #expect(analysis.adjacentRatios == [4.0, 4.0, 4.0])
  #expect(abs(analysis.fittedExponent - 2.0) < 0.000_001)
}

@Test("QA-03 fuzz failure retains and replays its exact seed and index")
func qa03FuzzFailureReplaysExactSeedAndIndex() throws {
  let seed: UInt64 = 0x4844_584C_5141_3033
  let index = 37
  let configuration = QA03FuzzConfiguration(
    seed: seed,
    iterations: 64,
    fixtureDirectory: nil,
    injectedFailureIndex: index
  )
  let replayConfiguration = QA03FuzzConfiguration(
    seed: seed,
    iterations: 64,
    fixtureDirectory: nil,
    replayIndex: index,
    injectedFailureIndex: index
  )

  let firstFailure = try capturedFailure(configuration)
  let replayFailure = try capturedFailure(replayConfiguration)

  #expect(firstFailure == replayFailure)
  #expect(firstFailure.contains("seed=0x4844584C51413033"))
  #expect(firstFailure.contains("index=37"))
  #expect(firstFailure.contains("case-seed="))
}

private func capturedFailure(
  _ configuration: QA03FuzzConfiguration
) throws -> String {
  do {
    _ = try QA03FuzzRunner.run(
      configuration: configuration,
      commit: "qa-03-unit-test"
    )
    Issue.record("Injected fuzz failure unexpectedly passed.")
    return ""
  } catch let error as QA03Error {
    return error.description
  }
}
