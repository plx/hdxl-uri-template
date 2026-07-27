import Foundation
import HDXLURITemplate

func doccOperatorsAndModifiers() throws {
  let parameters: [String: URIVariableValue] = [
    "value": .text("abcdef"),
    "unicode": .text("αβγ"),
    "encoded": .text("%2F"),
    "segments": .list(["users", "42"]),
    "filters": try .association([
      ("sort", "updated"),
      ("limit", "20"),
    ]),
  ]

  let prefix = try URITemplate(parsing: "{value:3}")
  let prefixResult = try prefix.evaluateAsString(parameters: parameters)
  precondition(prefixResult == "abc")

  let unicodePrefix = try URITemplate(parsing: "{unicode:2}")
  let unicodeResult = try unicodePrefix.evaluateAsString(
    parameters: parameters
  )
  precondition(unicodeResult == "%CE%B1%CE%B2")

  let reserved = try URITemplate(parsing: "{+encoded}")
  let reservedResult = try reserved.evaluateAsString(
    parameters: parameters
  )
  precondition(reservedResult == "%2F")

  let exploded = try URITemplate(
    parsing: "{/segments*}{?filters*}"
  )
  let explodedResult = try exploded.evaluateAsString(
    parameters: parameters
  )
  precondition(explodedResult == "/users/42?sort=updated&limit=20")
}
