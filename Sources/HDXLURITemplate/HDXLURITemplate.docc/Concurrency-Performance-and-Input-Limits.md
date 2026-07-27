# Concurrency, Performance, and Input Limits

Reuse immutable values safely and set workload limits at the application
boundary.

## Overview

### Concurrency

``URITemplate``, ``URIVariableValue``, and ``URIVariableValueType`` are
`Sendable` values. A parsed template can be shared across Swift tasks and
native threads for concurrent read-only metadata access and expansion.

```swift
import Foundation
import HDXLURITemplate

private enum InputPolicyError: Error {
  case templateTooLarge
}

func doccConcurrencyAndLimits() async throws {
  let source = "https://example.com/items/{id}"
  let maximumTemplateBytes = 4_096
  guard source.utf8.count <= maximumTemplateBytes else {
    throw InputPolicyError.templateTooLarge
  }

  let template = try URITemplate(parsing: source)
  let results = try await withThrowingTaskGroup(
    of: String.self,
    returning: Set<String>.self
  ) { group in
    for identifier in 0..<8 {
      group.addTask {
        try template.evaluateAsString(
          parameters: ["id": .text(String(identifier))]
        )
      }
    }

    var results: Set<String> = []
    for try await result in group {
      results.insert(result)
    }
    return results
  }

  precondition(results.count == 8)
}
```

### Performance characteristics

Parsing, validation, and expansion scale linearly for the package's pinned
hostile-input workloads. Runtime and allocation still scale with template
length, supplied values, collection sizes, percent density, and rendered
output. Flavor-specific list and association inspection creates a fresh
ordinary Swift array on each access.

Parse once and reuse a template when practical. Avoid repeatedly projecting a
large value payload in a hot loop when one recovered array can be reused.

### Input limits

The library does not impose one universal size, time, or destination limit.
Applications should bound untrusted template bytes, value and collection
sizes, rendered-output size, request time, and concurrency according to their
environment. Validate expanded destinations before performing network, file,
redirect, or navigation operations.
