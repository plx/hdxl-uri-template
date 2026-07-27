# Operators and Modifiers

Apply RFC 6570 operators, explode, prefix, Unicode, and percent-encoded input
with their distinct semantics.

## Overview

### Operators

The package supports every RFC 6570 Level 4 operator:

| Operator | Expansion role |
| --- | --- |
| none | Simple string expansion |
| `+` | Reserved expansion |
| `#` | Fragment expansion |
| `.` | Label expansion |
| `/` | Path-segment expansion |
| `;` | Path-parameter expansion |
| `?` | Query expansion |
| `&` | Query continuation |

An explode modifier (`*`) emits list elements or association pairs separately.
A prefix modifier (`:N`) truncates a text value to `N` Unicode code points
before escaping. Prefix modifiers do not apply to list or association values.

Valid percent triplets are preserved only where the selected operator permits
them. Malformed percent input is escaped deterministically. Prefix counting
treats a well-formed percent-encoded UTF-8 scalar as one Unicode code point.

```swift
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
```
