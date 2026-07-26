# HDXLURITemplate

Port of (private) Objective-C implementation of URI templates.

## Supported environments

HDXLURITemplate declares Swift tools version 6.3 and uses Swift language mode 6.
It supports iOS 26 or later, macOS 26 or later, tvOS 26 or later, watchOS 26 or
later, visionOS 26 or later, and Mac Catalyst 26 or later.

Older Swift toolchains, older Apple OS releases, and non-Apple platforms,
including Linux, are intentionally unsupported. This deliberately narrow floor
is the package's maintained compatibility contract.

## Build and test

Select an Xcode installation containing Apple Swift 6.3 through
`DEVELOPER_DIR`, then resolve, inspect, build, and test the package with that
toolchain:

```sh
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
xcrun swift package resolve
xcrun swift package dump-package
xcrun swift build -c debug
xcrun swift test -c debug
xcrun swift build -c release
xcrun swift test -c release
```

The repository's `just` recipes use the same `DEVELOPER_DIR`/`xcrun` selection.

## Codable representation

`URITemplate` encodes as one string containing its exact, validated
`templateRepresentation`. Decoding always reparses that string through
`URITemplate.init(parsing:)`, so decoded values have the same acceptance
boundary and invariants as directly parsed values.

This semantic string is the supported persistence format. Historical payloads
that expose the package's private parser storage are unsupported and rejected;
they are not migrated. Compiled or otherwise derived template caches should be
treated as separate, disposable data rather than as this Codable
representation.

JSON supports a template string as a top-level value. Foundation property
lists do not support top-level string fragments, so encode a template inside a
property-list array, dictionary, or keyed container when using
`PropertyListEncoder`.

## License and notices

Project-authored material is available under the
[MIT License](LICENSE). Vendored test fixtures and standards-derived Code
Components have separate attribution and redistribution terms in
[Third-party notices](THIRD_PARTY_NOTICES.md).

## Diagnostic privacy

`URITemplate.ParseError` and `URITemplate.EvaluationError` use bounded,
privacy-safe default text. Their Swift descriptions, localized descriptions,
debug descriptions, and bridged `NSError` diagnostics omit template source,
literal content, parameter names and values, rendered URIs, variable names,
and nested-error payloads.

The errors still retain complete recovery context in explicit properties such
as `template`, `parameters`, and `underlyingError`. Those properties—and the
descriptions of `URITemplate` and `URIVariableValue` themselves—can contain
sensitive data. Variable names can also be sensitive; they are omitted from
default text and exposed only through deliberate structured access such as
`failingVariableName`.

Raw `Mirror` child enumeration is deliberate programmatic introspection, not
a default error representation, and can expose the same retained recovery
context. Treat mirrored children as sensitive and do not log them by default.

For routine logging, use the localized description or the payload-free
evaluation category:

```swift
do {
  _ = try template.evaluate(parameters: parameters)
} catch let error as URITemplate.EvaluationError {
  logger.error(
    "URI template evaluation failed: \(error.kind.description, privacy: .public)"
  )
}
```
