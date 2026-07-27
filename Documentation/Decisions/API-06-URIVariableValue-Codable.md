# API-06: `URIVariableValue` Codable contract

Status: accepted

Decision date: July 27, 2026

Tracking issue: [#50](https://github.com/plx/hdxl-uri-template/issues/50)

## Decision

`URIVariableValue` and `URIVariableValueType` do not conform to `Encodable`,
`Decodable`, or `Codable`.

The internal value-storage enum and its text, list, pair, and association
wrappers likewise have no coding conformances. Their former coding
implementations existed only to synthesize the public value format and are not
an internal persistence contract.

This decision does not change `URITemplate.Codable`. A template continues to
encode as its one exact validated source string and decoding continues to
reparse that string through the public grammar.

## Context

Before the first supported release, `URIVariableValue` delegated coding to
private storage. JSON happened to contain numeric raw-value tags and private
wrapper details. For example, an ordered association encoded as:

```json
{"data":{"storage":[{"key":"b","value":"2"},{"key":"a","value":"1"}]},"type":8}
```

That shape was an implementation artifact. It used `1`, `2`, `4`, and `8` as
case tags, exposed the private `storage` wrapper, and had no documented
compatibility behavior for future value flavors. The README explicitly warned
consumers not to use it as a durable persistence or interchange format.

API-06 considered two bounded choices:

1. replace the artifact with a permanent textual tagged union covering
   undefined, text, list, and ordered association values; or
2. remove value coding until a concrete persistence use case justifies a
   separately designed format.

The maintainer approved the second choice.

## Evidence and rationale

Repository-wide review found that value coding was used by this package's
tests, public-consumer fixture, and hardening probes. No product persistence or
configuration requirement was identified. A public GitHub code search on the
decision date found no downstream package importing `HDXLURITemplate` and
persisting `URIVariableValue` or `URIVariableValueType`. Historical source in a
private repository was prior art rather than a current package consumer.

Retaining `Codable` would turn a newly designed tagged schema into a long-term
compatibility promise. It would require policies for unknown future cases,
malformed payloads, keyed and unkeyed archive compatibility, canonical
ordering, and migrations without a demonstrated consumer need. Removing the
conformances before the first supported release keeps the runtime value model
small and avoids presenting an accidental archive as a durable format.

`URIVariableValueType.RawValue` remains `UInt8` for source-level construction
and inspection. Raw values `1`, `2`, `4`, and `8` are not serialization tags
or persistence identifiers.

## Compatibility and migration

This is an intentional pre-`1.0` source break. Generic code requiring
`Codable`, `Encodable`, or `Decodable` no longer accepts
`URIVariableValue` or `URIVariableValueType`. Direct JSON and property-list
encoding and decoding of those types no longer compile.

The former numeric/private-wrapper payload is unsupported. The package does
not decode it, provide an archive migrator, or promise that its shape will
remain recognizable.

Applications that persist URI-template parameters should define and version an
application-owned DTO or schema. Decode and validate that source model, then
construct runtime values with:

- `URIVariableValue.undefined`;
- `URIVariableValue.text(_:)`;
- `URIVariableValue.list(_:)`; and
- `URIVariableValue.association(_:)`.

The throwing association factory preserves the unique-key invariant.
Applications needing later persistence should retain their source DTO
alongside the constructed `URIVariableValue`; read-only runtime inspection is
not a persistence contract.

Consumers that only parse templates, construct parameters, expand templates,
or use value equality, hashing, `Sendable`, `valueType`, the `is…Value`
properties, and the API-07 read-only payload accessors require no migration.

API-07 subsequently added `textValue`, `listValue`, and `associationValue` for
runtime inspection. Those accessors do not restore `Codable` or define a
persistence format. Applications needing durable storage still own and
version their source DTO.

## Rejected alternative

The proposed stable format was a semantic textual tagged union such as:

```json
{"type":"text","value":"hello"}
```

It was technically viable and would have hidden private storage. It was
rejected for this release contract because no current consumer requirement
justified the compatibility surface and test burden. A future persistence API
would require a new decision, explicit versioning and evolution rules, public
consumer evidence, and migration guidance. It must not silently restore the
removed implementation-derived shape.

## Validation contract

The decision is guarded by:

- a public symbol-graph contract forbidding `Encodable` and `Decodable` on
  `URIVariableValue` and `URIVariableValueType`;
- an external consumer that retains construction, inspection, equality,
  hashing, `Sendable`, errors, expansion, and `URITemplate.Codable` coverage;
- source scans showing no coding conformances on the private value wrappers;
- deterministic hardening that exercises every value flavor, invariants,
  equality, hashing, expansion, diagnostics, and concurrent value operations;
  and
- the full Debug, Release, `HEAVY_DEBUG`, sanitizer, fuzz, concurrency, scaling,
  and Apple platform matrices.

## Approval record

After reviewing the two alternatives, current schema, consumer research,
source-compatibility impact, migration requirements, and future compatibility
cost, the repository maintainer explicitly approved Option B on July 27, 2026.
