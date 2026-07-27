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
