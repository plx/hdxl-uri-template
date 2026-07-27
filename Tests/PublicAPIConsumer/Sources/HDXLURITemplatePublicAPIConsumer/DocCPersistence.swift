import Foundation
import HDXLURITemplate

private struct StoredParameters: Codable {
  struct Pair: Codable {
    let key: String
    let value: String
  }

  let title: String?
  let segments: [String]
  let filters: [Pair]

  func runtimeValues() throws -> [String: URIVariableValue] {
    [
      "title": title.map(URIVariableValue.text) ?? .undefined,
      "segments": .list(segments),
      "filters": try .association(
        filters.map { ($0.key, $0.value) }
      ),
    ]
  }
}

func doccPersistence() throws {
  let template = try URITemplate(
    parsing: "https://example.com{/segments*}{?title,filters*}"
  )
  let templateData = try JSONEncoder().encode(template)
  let decodedTemplate = try JSONDecoder().decode(
    URITemplate.self,
    from: templateData
  )
  precondition(decodedTemplate == template)

  let stored = StoredParameters(
    title: "URI Templates",
    segments: ["users", "42"],
    filters: [
      .init(key: "sort", value: "updated")
    ]
  )
  let storedData = try JSONEncoder().encode(stored)
  let decodedStored = try JSONDecoder().decode(
    StoredParameters.self,
    from: storedData
  )
  let rendered = try decodedTemplate.evaluateAsString(
    parameters: decodedStored.runtimeValues()
  )
  precondition(
    rendered
      == "https://example.com/users/42"
      + "?title=URI%20Templates&sort=updated"
  )
}
