# Persistence and Codable

Persist semantic template source and application-owned parameter models, not
private runtime representation.

## Overview

### Template persistence

``URITemplate`` conforms to `Codable`. It encodes as one exact validated source
string and reparses that string during decoding. Private parser storage and
compiled caches are not part of the public format.

### Parameter persistence

``URIVariableValue`` and ``URIVariableValueType`` deliberately do not conform
to `Codable`. Their payload accessors are runtime inspection APIs, not a
versioned interchange format.

Applications that persist parameters should define and version a source DTO,
decode and validate it under application policy, and then construct runtime
values through the public factories.

```swift
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
```

Historical numeric tags, private wrapper payloads, Objective-C wrapper
archives, and hypothetical compiled caches are unsupported.
