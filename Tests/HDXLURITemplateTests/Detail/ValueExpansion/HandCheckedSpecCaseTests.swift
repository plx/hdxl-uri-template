import Foundation
import Testing
@testable import HDXLURITemplate

@Test(
  "`/user{/id}{?token,tab}{&keys*}` (from spec)",
  .tags(.variableExpansion, .uriVariableAssociationValue, .takenFromSpecification)
)
private func variableAssocationValueHandCheckOnUserIDTokenTabKeys() throws {
  let template = try URITemplate(parsing: "/user{/id}{?token,tab}{&keys*}")
  let parameters: [String: URIVariableValue] = [
    "id": .text("admin"),
    "token": .text("12345"),
    "keys": try .association([
      ("key1", "val1"),
      ("key2", "val2"),
    ]),
    "tab": .text("overview"),
  ]

  let expected: [String] = [
    "/user/admin?token=12345&tab=overview&key1=val1&key2=val2",
    "/user/admin?token=12345&tab=overview&key2=val2&key1=val1",
  ]

  let observed = try template.evaluateAsString(parameters: parameters)
  #expect(expected.contains(observed))
}

@Test(
  "`{keys}` with an unexploded associative array",
  .tags(.variableExpansion, .uriVariableAssociationValue, .takenFromSpecification)
)
private func unexplodedAssociativeArrayUsesCommaDelimitedPairs() throws {
  let parameters: [String: URIVariableValue] = [
    "keys": try .association([
      ("a", "1"),
      ("b", "2"),
    ])
  ]

  let simple = try URITemplate(parsing: "{keys}")
  #expect(
    try simple.evaluateAsString(parameters: parameters) == "a,1,b,2"
  )

  let query = try URITemplate(parsing: "{?keys}")
  #expect(
    try query.evaluateAsString(parameters: parameters) == "?keys=a,1,b,2"
  )
}

@Test(
  "`{/id*}` (from spec)",
  .tags(.variableExpansion, .uriVariableListValue, .takenFromSpecification)
)
private func variableListValueHandCheckOnIDStar() throws {
  let template = try URITemplate(parsing: "{/id*}")
  let parameters: [String: URIVariableValue] = [
    "q": .text("URI Templates"),
    "id": .list(["person", "albums"]),
    "token": .text("12345"),
    "format": .text("atom"),
    "lang": .text("en"),
    "page": .text("10"),
    "start": .text("5"),
    "geocode": .list(["37.76", "-122.427"]),
    "fields": .list(["id", "name", "picture"]),
  ]

  let expected: String = "/person/albums"

  let observed = try template.evaluateAsString(parameters: parameters)
  #expect(expected == observed)
}

@Test(
  "`{/id*}{?fields,token}` (from spec)",
  .tags(.variableExpansion, .uriVariableListValue, .takenFromSpecification)
)
private func variableListValueHandCheckOnIDStarFieldsToken() throws {
  let template = try URITemplate(parsing: "{/id*}{?fields,token}")
  let parameters: [String: URIVariableValue] = [
    "q": .text("URI Templates"),
    "id": .list(["person", "albums"]),
    "token": .text("12345"),
    "format": .text("atom"),
    "lang": .text("en"),
    "page": .text("10"),
    "start": .text("5"),
    "geocode": .list(["37.76", "-122.427"]),
    "fields": .list(["id", "name", "picture"]),
  ]

  let expected: String = "/person/albums?fields=id,name,picture&token=12345"

  let observed = try template.evaluateAsString(parameters: parameters)
  #expect(expected == observed)
}

@Test(
  "`{+not_pct}` (from spec)",
  .tags(.variableExpansion, .uriVariableTextValue, .takenFromSpecification)
)
private func textVariableOnReservedNotPct() throws {
  let template = try URITemplate(parsing: "{+not_pct}")
  let parameters: [String: URIVariableValue] = [
    "keys": try .association([
      ("key1", "val1%2F"),
      ("key2", "val2%2F"),
    ]),
    "id": .text("admin%2F"),
    "not_pct": .text("%foo"),
    "list": .list([
      "red%25",
      "%2Fgreen",
      "blue",
    ]),
  ]

  let expected: String = "%25foo"

  let observed = try template.evaluateAsString(parameters: parameters)
  #expect(expected == observed)
}

@Test(
  "Undefined variables are skipped without swallowing empty strings",
  .tags(.variableExpansion, .uriVariableTextValue, .takenFromSpecification)
)
private func undefinedVariablesAreSkippedWithoutSwallowingEmptyStrings() throws {
  let parameters: [String: URIVariableValue] = [
    "var": .text("value"),
    "empty": .text(""),
  ]

  let pathWithUndefined = try URITemplate(parsing: "{/var,undef}")
  #expect(
    try pathWithUndefined.evaluateAsString(parameters: parameters) == "/value"
  )

  let pathWithEmpty = try URITemplate(parsing: "{/var,empty}")
  #expect(
    try pathWithEmpty.evaluateAsString(parameters: parameters) == "/value/"
  )
}

@Test(
  "`{;empty}` omits the equals sign",
  .tags(.variableExpansion, .uriVariableTextValue, .takenFromSpecification)
)
private func pathParameterEmptyStringOmitsEquals() throws {
  let template = try URITemplate(parsing: "{;empty}")
  let parameters: [String: URIVariableValue] = [
    "empty": .text("")
  ]

  let expected: String = ";empty"

  let observed = try template.evaluateAsString(parameters: parameters)
  #expect(expected == observed)
}

@Test(
  "Defined empty strings still emit operator prefixes",
  .tags(.variableExpansion, .uriVariableTextValue, .takenFromSpecification)
)
private func emptyStringsStillEmitOperatorPrefixes() throws {
  let parameters: [String: URIVariableValue] = [
    "empty": .text("")
  ]

  let fragment = try URITemplate(parsing: "foo{#empty}")
  #expect(
    try fragment.evaluateAsString(parameters: parameters) == "foo#"
  )

  let label = try URITemplate(parsing: "X{.empty}")
  #expect(
    try label.evaluateAsString(parameters: parameters) == "X."
  )
}

@Test(
  "`{&x,y,empty}` (from spec)",
  .tags(.variableExpansion, .uriVariableTextValue, .takenFromSpecification)
)
private func textVariableQueryContinuationXYEmpty() throws {
  let template = try URITemplate(parsing: "{&x,y,empty}")
  let parameters: [String: URIVariableValue] = [
    "x": .text("1024"),
    "y": .text("768"),
    "empty": .text(""),
  ]

  let expected: String = "&x=1024&y=768&empty="

  let observed = try template.evaluateAsString(parameters: parameters)
  #expect(expected == observed)
}
