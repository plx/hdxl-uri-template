import Testing
@testable import HDXLURITemplate

extension Tag {
  @Tag
  static var lastComponentManipulation: Self
}

@Test(
  "`String+URITemplateLastComponentManipulation` degenerate scenarios",
  .tags(.stringManipulation, .lastComponentManipulation)
)
private func checkDegenerateLastComponentManipulationScenarios() {
  // all-empty
  verifyLastComponent(
    of: "",
    forSeparator: "",
    yields: nil
  )
  verifyRemovingLastComponent(
    of: "",
    forSeparator: "",
    yields: ""
  )

  // empty-target
  verifyLastComponent(
    of: "",
    forSeparator: ",",
    yields: nil
  )
  verifyRemovingLastComponent(
    of: "",
    forSeparator: ",",
    yields: ""
  )

  // empty-separator
  verifyLastComponent(
    of: "abc",
    forSeparator: "",
    yields: nil
  )
  verifyRemovingLastComponent(
    of: "abc",
    forSeparator: "",
    yields: "abc"
  )

}

// MARK: Verifications

private func verifyLastComponent(
  of target: String,
  forSeparator separator: String,
  yields expectation: String?,
  sourceLocation: Testing.SourceLocation = #_sourceLocation
) {
  let result = target.lastComponent(forSeparator: separator)
  #expect(
    result == expectation,
    """
    Expected `"\(target)".lastComponent(forSeparator: "\(separator)") == "\(expectation ?? "<nil>")"`, but got "\(result ?? "<nil>")" instead!
    """,
    sourceLocation: sourceLocation
  )
}

private func verifyRemovingLastComponent(
  of target: String,
  forSeparator separator: String,
  yields expectation: String,
  sourceLocation: Testing.SourceLocation = #_sourceLocation
) {
  let result = target.removingLastComponent(forSeparator: separator)
  #expect(
    result == expectation,
    """
    Expected `"\(target)".removingLastComponent(forSeparator: "\(separator)") == "\(String(reflecting: expectation))"`, but got "\(result)" instead!
    """,
    sourceLocation: sourceLocation
  )
}
