import Foundation
import HDXLURITemplate

func readmeQuickStart() throws {
  let template = try URITemplate(
    parsing: "https://api.example.com{/version}/users/{id}{?query}"
  )
  let parameters: [String: URIVariableValue] = [
    "version": .text("v1"),
    "id": .text("42"),
    "query": .text("swift uri templates"),
  ]

  let rendered = try template.evaluateAsString(parameters: parameters)
  precondition(
    rendered
      == "https://api.example.com/v1/users/42?query=swift%20uri%20templates"
  )

  let url = try template.evaluate(parameters: parameters)
  precondition(url.absoluteString == rendered)
}
