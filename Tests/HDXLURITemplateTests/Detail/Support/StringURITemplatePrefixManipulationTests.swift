import Testing
@testable import HDXLURITemplate

extension Tag {
  @Tag
  static var uriTemplatePrefixManipulation: Self
}

@Suite(.tags(.stringManipulation, .uriTemplateLengthManipulation))
struct URITemplatePrefixManipulationTests {
  
  @Test
  private func `degenerate scenarios`() {
    // all empty
    verifyRemoval(
      ofPrefix: "",
      from: "",
      yields: ""
    )
    // empty-prefix
    verifyRemoval(
      ofPrefix: "",
      from: "a",
      yields: "a"
    )
    verifyRemoval(
      ofPrefix: "",
      from: "abc",
      yields: "abc"
    )
    
    // empty-target
    verifyRemoval(
      ofPrefix: "ab",
      from: "",
      yields: ""
    )
    verifyRemoval(
      ofPrefix: "abc",
      from: "",
      yields: ""
    )
  }
  
  @Test
  private func `canned scenarios`() {
    verifyRemoval(
      ofPrefix: "?",
      from: "?foo",
      yields: "foo"
    )
    verifyRemoval(
      ofPrefix: "?",
      from: "??foo",
      yields: "?foo"
    )
    verifyRemoval(
      ofPrefix: "??",
      from: "??foo",
      yields: "foo"
    )
    verifyRemoval(
      ofPrefix: "?",
      from: "?foo?",
      yields: "foo?"
    )
    verifyRemoval(
      ofPrefix: "?",
      from: "foo?",
      yields: "foo?"
    )
  }

  @Test
  private func `programmatic mixture`() {
    let prefixes: [String] = ["a", "b", "c", "ab", "ac", "bc", "abc"]
    let targets: [String] = ["x", "y", "z", "xy", "xz", "yz", "xyz"]
    for prefix in prefixes {
      for target in targets {
        // verify it's not a prefix:
        #expect(!target.hasPrefix(prefix))
        // this should thus be a no-op:
        verifyRemoval(
          ofPrefix: prefix,
          from: target,
          yields: target
        )
        // this, too, should thus be a no-op:
        #expect(!(target + prefix).hasPrefix(prefix))
        verifyRemoval(
          ofPrefix: prefix,
          from: (target + prefix),
          yields: (target + prefix)
        )
        // whereas this *will* remove the unwanted prefix:
        #expect((prefix+target).hasPrefix(prefix))
        verifyRemoval(
          ofPrefix: prefix,
          from: (prefix + target),
          yields: target
        )
      }
    }
  }

}

private func verifyRemoval(
  ofPrefix prefix: String,
  from target: String,
  yields expectation: String,
  sourceLocation: Testing.SourceLocation = #_sourceLocation
) {
  let result = target.conditionallyRemoving(
    prefix: prefix
  )
  #expect(
    result == expectation,
    """
    Expected `"\(target)".conditionallyRemoving(prefix: "\(prefix)") == "\(expectation)"`, but got "\(result)" instead!
    """
  )
  let mutableResult = target.mutated {
    $0.conditionallyRemove(prefix: prefix)
  }
  #expect(
    expectation == mutableResult,
    """
    Got unexpected mutable/immutable discrepancy when removing "\(prefix)" from "\(target)": immutable got "\(result)", mutable got "\(mutableResult)", and we expected "\(expectation)"!
    """
  )
}
