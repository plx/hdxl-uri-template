# Modeling Variable Values

Represent undefined, text, list, and ordered association inputs explicitly.

## Overview

### Choose the matching flavor

``URIVariableValue`` has four runtime flavors:

- undefined omits a missing value without treating it as an empty string;
- text contains one string;
- list contains ordered strings; and
- association contains ordered string pairs with unique keys.

The throwing sequence association factory rejects duplicate keys. Dictionary
factories establish deterministic key order, and sequence factories preserve
their input order.

Use ``URIVariableValue/valueType`` as the exhaustive discriminator. The
``URIVariableValue/textValue``, ``URIVariableValue/listValue``, and
``URIVariableValue/associationValue`` accessors return ordinary Swift values
for the matching flavor and `nil` for a mismatch. Empty matching payloads are
non-`nil`, and returned collections are independent values.

```swift
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
```

Read-only payload access is a runtime inspection API, not a serialized schema.
See <doc:Persistence-and-Codable> before persisting parameters.
