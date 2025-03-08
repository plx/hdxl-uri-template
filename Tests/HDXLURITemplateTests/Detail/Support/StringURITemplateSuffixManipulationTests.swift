import Testing
@testable import HDXLURITemplate

extension Tag {
  @Tag
  static var suffixManipulation: Self
}

@Test(
  "`String+URITemplateSuffixManipulation` degenerate scenarios",
  .tags(.stringManipulation, .suffixManipulation)
)
private func degenerateScenarios() {
  verifyRemoval(
    ofSuffix: "",
    from: "",
    yields: ""
  )
  // empty-suffix
  verifyRemoval(
    ofSuffix: "",
    from: "a",
    yields: "a"
  )
  verifyRemoval(
    ofSuffix: "",
    from: "abc",
    yields: "abc"
  )
  
  // empty-target
  verifyRemoval(
    ofSuffix: "ab",
    from: "",
    yields: ""
  )
  verifyRemoval(
    ofSuffix: "abc",
    from: "",
    yields: ""
  )

}

@Test(
  "`String+URITemplateSuffixManipulation` canned examples",
  .tags(.stringManipulation, .suffixManipulation)
)
private func cannedExamples() {
  verifyRemoval(
    ofSuffix: "?",
    from: "foo?",
    yields: "foo"
  )
  verifyRemoval(
    ofSuffix: "?",
    from: "foo??",
    yields: "foo?"
  )
  verifyRemoval(
    ofSuffix: "??",
    from: "foo??",
    yields: "foo"
  )
  verifyRemoval(
    ofSuffix: "?",
    from: "?foo?",
    yields: "?foo"
  )
  verifyRemoval(
    ofSuffix: "?",
    from: "?foo",
    yields: "?foo"
  )
}

@Test(
  "`String+URITemplateSuffixManipulation` programatic mixtures",
  .tags(.stringManipulation, .suffixManipulation)
)
private func progammaticMixtures() {
  // note use of non-overlapping character sets to ensure not suffixes:
  let suffixes: [String] = ["a", "b", "c", "ab", "ac", "bc", "abc"]
  let targets: [String] = ["x", "y", "z", "xy", "xz", "yz", "xyz"]
  for suffix in suffixes {
    for target in targets {
      // verify it's not a suffix:
      #expect(!target.hasSuffix(suffix))
      // this should thus be a no-op:
      verifyRemoval(
        ofSuffix: suffix,
        from: target,
        yields: target
      )
      // this, too, should thus be a no-op:
      #expect(!(suffix+target).hasSuffix(suffix))
      verifyRemoval(
        ofSuffix: suffix,
        from: (suffix + target),
        yields: (suffix + target)
      )
      // whereas this *will* remove the unwanted suffix:
      #expect((target + suffix).hasSuffix(suffix))
      verifyRemoval(
        ofSuffix: suffix,
        from: (target + suffix),
        yields: target
      )
    }
  }
}

// MARK: Verifications

private func verifyRemoval(
  ofSuffix suffix: String,
  from target: String,
  yields expectation: String,
  sourceLocation: Testing.SourceLocation = #_sourceLocation
) {
  let result = target.conditionallyRemoving(
    suffix: suffix
  )
  
  #expect(
    result == expectation,
    """
    Expected `"\(target)".conditionallyRemoving(suffix: "\(suffix)") == "\(expectation)"`, but got "\(result)" instead!
    """,
    sourceLocation: sourceLocation
  )
  
  let mutableResult = target.mutated {
    $0.conditionallyRemove(suffix: suffix)
  }
  
  #expect(
    expectation == mutableResult,
    """
    Got unexpected mutable/immutable discrepancy when removing "\(suffix)" from "\(target)": immutable got "\(result)", mutable got "\(mutableResult)", and we expected "\(expectation)"!
    """
  )
}
