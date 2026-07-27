import Foundation
import HDXLURITemplate

func readmeVariableValues() throws {
  let orderedFilters = try URIVariableValue.association([
    ("sort", "updated"),
    ("limit", "20"),
  ])
  let parameters: [String: URIVariableValue] = [
    "absent": .undefined,
    "title": .text("URI Templates"),
    "segments": .list(["users", "42"]),
    "filters": orderedFilters,
  ]
  let template = try URITemplate(
    parsing: "https://example.com{/segments*}{?absent,title,filters*}"
  )

  let rendered = try template.evaluateAsString(parameters: parameters)
  precondition(
    rendered
      == "https://example.com/users/42"
      + "?title=URI%20Templates&sort=updated&limit=20"
  )
  precondition(parameters["absent"]?.isUndefined == true)
  precondition(parameters["absent"]?.textValue == nil)
  precondition(parameters["title"]?.textValue == "URI Templates")

  var segments = parameters["segments"]?.listValue
  precondition(segments == ["users", "42"])
  segments?.append("local-only")
  precondition(parameters["segments"]?.listValue == ["users", "42"])

  let filters = orderedFilters.associationValue
  precondition(filters?.map(\.key) == ["sort", "limit"])
  precondition(filters?.map(\.value) == ["updated", "20"])
}
