import Foundation
import Testing
@testable import HDXLURITemplate

@Suite(.tags(.variableExpansion, .takenFromSpecification))
struct HandCheckedSpecCaseTests {

  @Test
  private func `/user{/id}{?token, tab}{&keys*} (from spec)`() throws {
    let template = try URITemplate(parsing: "/user{/id}{?token, tab}{&keys*}")
    let parameters: [String:URIVariableValue] = [
      "id": .text("admin"),
      "token": .text("12345"),
      "keys": .association([
        ("key1", "val1"),
        ("key2", "val2")
      ]),
      "tab": .text("overview")
    ]
    
    let expected: [String] = [
      "/user/admin?token=12345&tab=overview&key1=val1&key2=val2",
      "/user/admin?token=12345&tab=overview&key2=val2&key1=val1"
    ]
    
    let observed = try template.evaluateAsString(parameters: parameters)
    #expect(expected.contains(observed))
  }
  
  
  @Test
  private func `{/id*} (from spec)`() throws {
    let template = try URITemplate(parsing: "{/id*}")
    let parameters: [String:URIVariableValue] = [
      "q": .text("URI Templates"),
      "id": .list(["person", "albums"]),
      "token": .text("12345"),
      "format": .text("atom"),
      "lang": .text("en"),
      "page": .text("10"),
      "start": .text("5"),
      "geocode": .list(["37.76", "-122.427"]),
      "fields": .list(["id", "name", "picture"])
    ]
    
    let expected: String = "/person/albums"
    
    let observed = try template.evaluateAsString(parameters: parameters)
    #expect(expected == observed)
  }
  
  @Test
  private func `{/id*}{?fields, token} (from spec)`() throws {
    let template = try URITemplate(parsing: "{/id*}{?fields, token}")
    let parameters: [String:URIVariableValue] = [
      "q": .text("URI Templates"),
      "id": .list(["person", "albums"]),
      "token": .text("12345"),
      "format": .text("atom"),
      "lang": .text("en"),
      "page": .text("10"),
      "start": .text("5"),
      "geocode": .list(["37.76", "-122.427"]),
      "fields": .list(["id", "name", "picture"])
    ]
    
    let expected: String = "/person/albums?fields=id,name,picture&token=12345"
    
    let observed = try template.evaluateAsString(parameters: parameters)
    #expect(expected == observed)
  }
  
  @Test
  private func `{+not_pct} (from spec)`() throws {
    let template = try URITemplate(parsing: "{+not_pct}")
    let parameters: [String:URIVariableValue] = [
      "keys": .association([
        ("key1", "val1%2F"),
        ("key2", "val2%2F"),
      ]),
      "id": .text("admin%2F"),
      "not_pct": .text("%foo"),
      "list": .list([
        "red%25",
        "%2Fgreen",
        "blue"
      ])
    ]
    
    let expected: String = "%25foo"
    
    let observed = try template.evaluateAsString(parameters: parameters)
    #expect(expected == observed)
  }
  
  @Test
  private func `{&x, y, empty} (from spec)`() throws {
    let template = try URITemplate(parsing: "{&x, y, empty}")
    let parameters: [String:URIVariableValue] = [
      "x": .text("1024"),
      "y": .text("768"),
      "empty": .text("")
    ]
    
    let expected: String = "&x=1024&y=768&empty="
    
    let observed = try template.evaluateAsString(parameters: parameters)
    #expect(expected == observed)
  }
  
}
