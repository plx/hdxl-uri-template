# HDXLURITemplate

Port of (private) Objective-C implementation of URI templates.

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
