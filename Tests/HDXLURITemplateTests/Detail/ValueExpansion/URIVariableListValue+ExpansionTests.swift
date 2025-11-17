import Foundation
import Testing
@testable import HDXLURITemplate

@Test(
  "`count` examples (direct list expansion)",
  .tags(.variableExpansion,.uriVariableListValue)
)
private func directlyHandCheckCountListExpansionNoTemplate() throws {
  let styles: [(URIValueExpansionType, URIValueExpansionModifier)] = [
    (.simple, .unmodified),
    (.simple, .explode),
    (.pathSegment, .unmodified),
    (.pathSegment, .explode),
    (.pathParameter, .unmodified),
    (.pathParameter, .explode),
    (.query, .unmodified),
    (.query, .explode),
    (.queryContinuation, .explode)
  ]
  let expectations = [
    "one,two,three",
    "one,two,three",
    "one,two,three",
    "one/two/three",
    "count=one,two,three",
    "count=one;count=two;count=three",
    "count=one,two,three",
    "count=one&count=two&count=three",
    "count=one&count=two&count=three"
  ]
  try #require(styles.count == expectations.count)
  
  let name = URITemplateVariableName(rawValue: "count")
  let value = URIVariableListValue(strings: ["one", "two", "three"])
  for ((expansionType, expansionModifier), expected) in zip(styles, expectations) {
    let observed = try value.expansion(
      expansionType: expansionType,
      variableName: name,
      expansionModifier: expansionModifier
    )
    
    #expect(
      expected == observed,
      """
      Found a basic list-expansion mistake:
      
      - `expansionType`: \(expansionType)
      - `expansionModifier`: \(expansionModifier)
      - `expected`: \(expected)
      - `observed`: \(observed)
      """
    )
  }
  
}

@Test(
  "`count` examples for list",
  .tags(.variableExpansion,.uriVariableListValue)
)
private func handCheckCountListExpansion() throws {
  let templates = [
    "{count}",
    "{count*}",
    "{/count}",
    "{/count*}",
    "{;count}",
    "{;count*}",
    "{?count}",
    "{?count*}",
    "{&count*}"
  ]
  let expectations = [
    "one,two,three",
    "one,two,three",
    "/one,two,three",
    "/one/two/three",
    ";count=one,two,three",
    ";count=one;count=two;count=three",
    "?count=one,two,three",
    "?count=one&count=two&count=three",
    "&count=one&count=two&count=three"
  ]
  
  for (_template, expected) in zip(templates, expectations) {
    let template = try URITemplate(parsing: _template)
    let variable: URIVariableValue = .list(["one", "two", "three"])
    
    let parameters: [String:URIVariableValue] = [
      "count": variable
    ]
    
    
    let observed = try template.evaluateAsString(parameters: parameters)
    #expect(
      expected == observed,
      """
      Found a basic list-expansion mistake:
      
      - `template`: \(_template)
      - `expected`: \(expected)
      - `observed`: \(observed)
      """
    )
  }

}
