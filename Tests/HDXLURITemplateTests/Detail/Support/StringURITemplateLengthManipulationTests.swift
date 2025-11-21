import Testing
@testable import HDXLURITemplate

extension Tag {
  @Tag
  static var uriTemplateLengthManipulation: Self
}

@Suite(.tags(.stringManipulation, .uriTemplateLengthManipulation))
struct StringConstrainedToCodePointCountTests {
  
  @Test
  func `canned scenarios`() {
    verify(
      constraining: "abcdef",
      toCodePointCount: 0,
      yields: ""
    )
    verify(
      constraining: "abcdef",
      toCodePointCount: 1,
      yields: "a"
    )
    verify(
      constraining: "abcdef",
      toCodePointCount: 2,
      yields: "ab"
    )
    verify(
      constraining: "abcdef",
      toCodePointCount: 3,
      yields: "abc"
    )
    verify(
      constraining: "abcdef",
      toCodePointCount: 4,
      yields: "abcd"
    )
    verify(
      constraining: "abcdef",
      toCodePointCount: 5,
      yields: "abcde"
    )
    verify(
      constraining: "abcdef",
      toCodePointCount: 6,
      yields: "abcdef"
    )
    verify(
      constraining: "abcdef",
      toCodePointCount: 7,
      yields: "abcdef"
    )
  }
  
  @Test(arguments: probeStrings)
  private func `fixtures are sensible`(
    probeString: String
  ) {
    #expect(
      probeString.codePointCount == probeString.count
    )
  }
  
  @Test(arguments: probeStrings)
  private func `degenerate cases`(
    probeString: String
  ) {
    #expect(
      probeString == probeString.constrained(toCodePointCount: probeString.codePointCount)
    )
    #expect(
      "" == probeString.constrained(toCodePointCount: 0)
    )
  }
  
  @Test(arguments: probeStrings)
  private func `mutable/immutable equivalence`(probeString: String) {
    for codePointCount in probeLengths {
      let immutableResult = probeString.constrained(toCodePointCount: codePointCount)
      var mutableResult = probeString
      mutableResult.constrain(toCodePointCount: codePointCount)
      #expect(
        immutableResult == mutableResult,
        """
        Found mutable-vs-immutable mismatch for probeString `\(probeString)` when constrained to code-point-count \(codePointCount)! 
        """
      )
    }
  }
}

// MARK: - Verifications

private func verify(
  constraining target: String,
  toCodePointCount codePointCount: Int,
  yields expectation: String,
  sourceLocation: Testing.SourceLocation = #_sourceLocation
) {
  let result = target.constrained(toCodePointCount: codePointCount)
  #expect(
    expectation == result,
    """
    Expected `"\(target)".constrained(toCodePointCount: \(codePointCount)) == "\(expectation)", but got "\(result)" instead!
    """,
    sourceLocation: sourceLocation
  )
}

// MARK: - Fixtures

private let probeStrings = ["", "a", "ab", "abc", "abcd", "abcde"]
private let probeLengths = 0...10
