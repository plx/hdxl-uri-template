package struct QA03DeterministicGenerator: Sendable {

  package private(set) var state: UInt64

  package init(seed: UInt64) {
    state = seed
  }

  package mutating func next() -> UInt64 {
    state &+= 0x9E37_79B9_7F4A_7C15
    var value = state
    value = (value ^ (value >> 30)) &* 0xBF58_476D_1CE4_E5B9
    value = (value ^ (value >> 27)) &* 0x94D0_49BB_1331_11EB
    return value ^ (value >> 31)
  }

  package mutating func next(upperBound: Int) -> Int {
    precondition(upperBound > 0)
    return Int(next() % UInt64(upperBound))
  }

  package mutating func nextBool() -> Bool {
    next() & 1 == 0
  }

  package static func caseSeed(rootSeed: UInt64, index: Int) -> UInt64 {
    var generator = QA03DeterministicGenerator(
      seed: rootSeed &+ UInt64(index)
    )
    return generator.next()
  }
}
