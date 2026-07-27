import Foundation

extension URL {

  static let extendedTestsJSONURL: URL = mandatory(
    value: Bundle.module.url(
      forResource: "extended-tests",
      withExtension: "json"
    )
  )

  static let negativeTestsJSONURL: URL = mandatory(
    value: Bundle.module.url(
      forResource: "negative-tests",
      withExtension: "json"
    )
  )

  static let specExamplesJSONURL: URL = mandatory(
    value: Bundle.module.url(
      forResource: "spec-examples",
      withExtension: "json"
    )
  )

  static let specExamplesBySectionJSONURL: URL = mandatory(
    value: Bundle.module.url(
      forResource: "spec-examples-by-section",
      withExtension: "json"
    )
  )

}

private func mandatory<T>(
  value: T?,
  file: StaticString = #file,
  line: UInt = #line
) -> T {
  guard let value else {
    fatalError(
      """
      Couldn't locate a mandatory value! 
      """,
      file: file,
      line: line
    )
  }

  return value
}
