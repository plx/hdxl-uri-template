# Public API contract

Run the checked public API contract with:

```console
just check-docc
```

The check emits a fresh public symbol graph with the active Swift toolchain and
compares selected conformances and members against
`HDXLURITemplate.public-api.json`. The baseline is intentionally focused: it
protects explicit API decisions without treating every symbol-graph detail as a
permanent compatibility promise.

The checked Swift contract includes `URITemplate.ParseError`, its nested
structured `Kind`, and the deliberate absence of both
`ParseError.underlyingError` and `DataValidationError`. Public-only tests lock
the semantic categories, UTF-8 ranges, Codable propagation, and privacy-safe
Foundation bridging approved in
[API-05](../Decisions/API-05-Structured-Parse-Diagnostics.md).

The same command builds and runs `Tests/PublicAPIConsumer` in Debug and Release
as a separate package. That fixture cannot access `internal` or `package`
declarations. It exercises documented parsing and expansion, typed Swift and
Foundation error bridging, all runtime value flavors, `URITemplate.Codable`,
immutable template copies, and concurrent representation, metadata, equality,
hashing, and expansion reads from one shared `Sendable` template. The symbol
graph forbids `Encodable` and `Decodable` on `URIVariableValue` and
`URIVariableValueType` under the approved
[API-06 decision](../Decisions/API-06-URIVariableValue-Codable.md).

The check also evaluates the README SwiftPM manifest and requires the two
executable README examples to exactly match compiled fixture sources. The
DocC catalog contributes four more synchronized external-consumer examples.
DocC conversion treats diagnostics and unresolved links as errors, validates
parameter and return documentation, and requires an abstract for every
supported public symbol. `just test-check-docc` proves that the gate rejects
example drift, an unresolved link, and a deliberately invalid public API
example. The Debug job in Core CI runs the complete boundary, documentation,
and failure-detector checks.

The contract also inspects every `HDXLURITemplate-Swift.h` that the compiler
emits and rejects the removed Objective-C wrapper classes and enum. It requires
exactly three canonical generated headers from the package and test builds, so
the absence assertion cannot silently pass with missing or duplicate compiler
output. The package's initial supported contract is Swift-only.

The real `.m` consumer contemplated by QA-04 is deliberately not applicable.
The approved [Objective-C support decision](../Decisions/API-08-Objective-C-Support.md)
([#52](https://github.com/plx/hdxl-uri-template/issues/52)) and completed
[removal contract](../Decisions/API-10-Objective-C-Removal.md) make the native
Swift consumer plus generated-header absence checks the binding contract.
