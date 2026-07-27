# Expanding Templates

Choose string expansion or Foundation URL construction deliberately.

## Overview

### Expand with typed values

Use ``URITemplate/evaluateAsString(parameters:)`` when the expanded text is the
desired result. Missing names and ``URIVariableValue/undefined`` values are
omitted according to RFC 6570, while empty defined values retain their operator
semantics.

Use ``URITemplate/evaluate(parameters:)`` when the result must also satisfy
Foundation's `URL` construction rules. That method first performs the same
string expansion and then converts the result to a URL.

```swift
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
```

### Apply an application security policy

Successful URL construction does not make a caller-influenced destination
safe. Before navigation, file access, redirects, or network requests, validate
the expanded URL against application-owned requirements such as:

- an allowlist of schemes and hosts;
- expected port and credential rules;
- path confinement and redirect behavior; and
- limits on template, value, and rendered-output sizes.

Prefer fixed trusted template structure with caller data supplied as typed
values. Do not concatenate untrusted text into template source when it should
be a variable value.
