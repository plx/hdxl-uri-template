import Testing
@testable import HDXLURITemplate

func verifyOrderedAscending<Element>(
  _ collection: some Collection<Element>,
  emptyOk: Bool = true,
  sourceLocation: Testing.SourceLocation = #_sourceLocation
) where Element: Comparable {
  if collection.isEmpty && !emptyOk {
    #expect(
      Bool(false),
      "Expected a non-empty collection here.",
      sourceLocation: sourceLocation
    )
  }
  
  for (lowerOffset, lowerIndex) in collection.indices.dropLast().enumerated() {
    let upperIndex = collection.index(after: lowerIndex)
    let lowerElement = collection[lowerIndex]
    let upperElement = collection[upperIndex]
    #expect(
      lowerElement < upperElement,
      "Expected an ascending ordering, but found \(lowerElement) >= \(upperElement) @ offsets \(lowerOffset), \(lowerOffset + 1) (indices: \(lowerIndex), \(upperIndex))",
      sourceLocation: sourceLocation
    )
  }
}

func verifyUniqueStringification<Element>(
  _ elements: some Collection<Element>,
  emptyOk: Bool = true,
  sourceLocation: Testing.SourceLocation = #_sourceLocation,
  using stringify: (Element) -> String
) {
  if elements.isEmpty && !emptyOk {
    #expect(
      Bool(false),
      "Expected a non-empty collection here.",
      sourceLocation: sourceLocation
    )
  }
  
  var elementStringifications: [String: Int] = [:]
  for element in elements {
    let stringRepresentation = stringify(element)
    elementStringifications[
      stringRepresentation,
      default: 0
    ] += 1
  }
  
  let duplicateMappings = elementStringifications.filter { $1 > 1 }
  guard !duplicateMappings.isEmpty else {
    return
  }
  
  let summaryLines = elementStringifications
    .map { "- `\($0.key)`: mapped-to \($0.value) times" }
    .joined(separator: "\n")
  
  #expect(
    duplicateMappings.isEmpty,
    Comment(rawValue: "Found \(duplicateMappings.count) duplications:" + summaryLines),
    sourceLocation: sourceLocation
  )
}

func verifyAllSatisfy<Element>(
  _ elements: some Collection<Element>,
  explanation: @autoclosure () -> String,
  sourceLocation: Testing.SourceLocation = #_sourceLocation,
  predicate: (Element) throws -> Bool
) rethrows {
  var cachedMessage: String? = nil
  for (index, element) in elements.enumerated() {
    if try !predicate(element) {
      let message = cachedMessage.obtainAssuredValue(guaranteedBy: explanation())
      #expect(
        Bool(false),
        """
        \(message) failed for \(element) @ position \(index)!
        """,
        sourceLocation: sourceLocation
      )
    }
  }
}

func verifyPairwiseDistinct<Element>(
  _ elements: some Collection<Element>,
  sourceLocation: Testing.SourceLocation = #_sourceLocation
) where Element: Equatable {
//  for (upperOffset, upperIndex) in elements.indices.enumerated() {
//    let upperElement = elements[upperIndex]
//    for (lowerOffset, lowerElement) in elements[..<upperIndex].enumerated() {
//      #expect(
//        lowerElement != upperElement,
//        """
//        Expected pairwise-distinctness, but found matching elements: \(lowerElement) == \(upperElement) @ positions (\(lowerOffset), \(upperOffset)).  
//        """,
//        sourceLocation: sourceLocation
//      )
//    }
//  }
}

func countOfTrue(_ arguments: Bool...) -> Int {
  arguments.reduce(into: 0) { result, argument in
    if argument {
      result += 1
    }
  }
}
