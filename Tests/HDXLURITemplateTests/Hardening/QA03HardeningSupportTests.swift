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

@Test("QA-03 diagnostic oracle distinguishes sentinels from ordinary prose")
func qa03DiagnosticOracleDistinguishesSentinelsFromProse() throws {
  try qa03ExerciseDiagnosticPrivacyCanaries(index: 270_217)

  try qa03ValidatePublicDiagnostic(
    """
    The URI template could not be parsed. A literal contains a character that \
    URI-template syntax forbids.
    """
  )

  #expect(throws: QA03Error.self) {
    try qa03ValidatePublicDiagnostic(
      "Invalid source SENSITIVE_TEMPLATE_270217_"
    )
  }
  #expect(throws: QA03Error.self) {
    try qa03ValidatePublicDiagnostic(
      "Invalid value SENSITIVE_VALUE_0_payload"
    )
  }
  #expect(throws: QA03Error.self) {
    try qa03ValidatePublicDiagnostic(
      String(repeating: "x", count: 513)
    )
  }
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

@Test("QA-03 rejects an injected fuzz failure outside the iteration range")
func qa03RejectsOutOfRangeInjectedFailure() throws {
  let configuration = QA03FuzzConfiguration(
    seed: 0x4844_584C_5141_3033,
    iterations: 64,
    fixtureDirectory: nil,
    injectedFailureIndex: 64
  )

  #expect(throws: QA03Error.self) {
    try QA03FuzzRunner.run(
      configuration: configuration,
      commit: "qa-03-unit-test"
    )
  }
}

@Test("QA-03 CLI arguments consume valid options and reject unknown options")
func qa03CLIArgumentsRejectUnknownOptions() throws {
  var valid = try QA03Arguments([
    "--seed", "0x10",
    "--iterations", "64",
  ])
  #expect(try valid.seed(named: "--seed") == 0x10)
  #expect(try valid.integer(named: "--iterations", minimum: 1) == 64)
  try valid.requireNoUnusedOptions()

  let unknown = try QA03Arguments(["--typo", "value"])
  #expect(throws: QA03Error.self) {
    try unknown.requireNoUnusedOptions()
  }

  var malformedSeed = try QA03Arguments(["--seed", "not-hex"])
  #expect(throws: QA03Error.self) {
    try malformedSeed.seed(named: "--seed")
  }

  #expect(throws: QA03Error.self) {
    _ = try QA03Arguments(["--seed", "0x1", "--seed", "0x2"])
  }
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
