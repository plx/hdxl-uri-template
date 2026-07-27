# API-07 read-only variable-value payload inspection

Date: July 27, 2026

Tracking issue:
[API-07/#51](https://github.com/plx/hdxl-uri-template/issues/51)

Baseline revision:
`d158a012ab0d4065a75b58bdf4f64798037b546b`

Implementation revision:
`b14ce960dc5d13e39e7cfdf6eaab19e9a6537caf`

Approved CI-stabilization revision:
`1888e3b08ee90b3987c739beaac77bc3fe8dfe78`

## Baseline characterization

At the baseline revision, public Swift consumers could construct every
`URIVariableValue` flavor and inspect `valueType`, `is…Value`, `count`, and
`isEmpty`, but could not recover the wrapped text, list, or ordered
association through supported API. The internal storage enum and its newtype
wrappers were the only payload readers.

This missing capability was a source-level absence rather than a runtime
failure, so it could not be retained as a passing executable test before the
API existed. The baseline source and public symbol graph provide the
pre-change characterization. The external consumer and public-only test target
now compile against the positive inspection contract without `@testable`.

The issue's original reference to decoded `URIVariableValue` instances was
superseded by the accepted
[API-06 Option B decision](../../Decisions/API-06-URIVariableValue-Codable.md):
runtime variable values deliberately do not conform to `Codable`.

## Selected contract

API-07 uses the issue's flavor-specific optional-property shape:

| Property | Matching flavor | Matching result | Mismatch result |
| --- | --- | --- | --- |
| `textValue` | `.text` | `String`, including `""` | `nil` |
| `listValue` | `.list` | ordered `[String]`, including `[]` | `nil` |
| `associationValue` | `.association` | ordered `[(key: String, value: String)]`, including `[]` | `nil` |

`valueType` remains the exhaustive four-flavor discriminator. The optional
properties keep undefined and flavor mismatch explicit without publishing a
second constructible tagged union or any internal wrapper.

List and association accessors project fresh arrays of ordinary Swift values.
Mutating either result cannot mutate the original `URIVariableValue`.
Association projection preserves factory-established order and the original
unique-key invariant; callers receive no route back into protected storage.
`URIVariableValue` remains an immutable, `Sendable` value.

## Persistence and Objective-C boundaries

Payload inspection does not reverse API-06. `URIVariableValue`,
`URIVariableValueType`, and the private wrappers remain non-`Codable`, and the
historical numeric/private-wrapper archive remains unsupported. Applications
needing persistence still own and version their source DTO; the accessors are
not a serialization schema or compatibility promise.

The validation checklist's Objective-C parity wording is not applicable after
the accepted
[API-08 Swift-only decision](../../Decisions/API-08-Objective-C-Support.md)
and API-10 wrapper removal. The generated-header contract instead verifies
that the removed Objective-C value facade remains absent, while the real
external Swift consumer exercises every new accessor.

## Contract and invariant coverage

`PublicValueContractTests` imports the product normally and switches
exhaustively on all four `URIVariableValueType` cases. It verifies:

- every matching payload;
- every mismatched property returning `nil`;
- empty text, list, and association values remaining non-`nil`;
- sequence association order and key uniqueness;
- independent mutation of recovered list and association arrays; and
- `Sendable` acceptance for both recovered collection types.

The synchronized README/external-package example independently compiles and
runs in Debug and Release. It recovers text, list, and ordered association
payloads, mutates a projected list, and confirms that the original value is
unchanged.

LLVM coverage for `Sources/HDXLURITemplate/URIVariableValue.swift` on the
implementation revision was:

| Metric | Covered | Result |
| --- | ---: | ---: |
| Regions | 39/39 | 100% |
| Functions | 26/26 | 100% |
| Lines | 115/115 | 100% |

The report recorded both matching and mismatching branches for all three new
properties.

## Approved CI measurement stabilization

PR #101's first Release run and its unchanged-SHA rerun both completed the
API-07 and functional assertions but failed the pre-existing HARD-01
percent-triplet scaling test. The reported outlier moved between adjacent
sizes: the first run measured a `4.20x` 40,000-to-80,000 ratio, while the
rerun measured a `4.47x` 20,000-to-40,000 ratio. The entire measurement took
only 45–62 milliseconds and ran concurrently with the 20–30-second API-03
benchmark. An earlier unchanged `master` run had exhibited the same failure
mode before passing on a later run.

The explicitly-approved stabilization increases work per sample from
`[8, 4, 2, 1]` to `[64, 32, 16, 8]` repetitions and the median sample count
from three to five. It does not change production code, workloads, input
sizes, the `3.0x` adjacent-ratio ceiling, or the `1.25` fitted-exponent
ceiling.

One initial run and ten consecutive focused Release reruns passed. Their
fitted exponents ranged from `0.989` to `1.010`, and the largest observed
adjacent ratio was `2.064`. The complete Release suite also passed with the
stabilized test running beside API-03. The combined post-fuzz smoke invocation
then produced one transient `large-list` rejection; its separate five-sample
QA-03 scaling rerun passed all six frozen workloads, with fitted exponents
ranging from `0.957` to `0.998`.

## Validation record

All validation used Xcode's Swift 6.3 toolchain. The implementation revision
completed:

```sh
swift test --filter publicPayloadInspection
just check-public-api
just test-all
swift test --enable-code-coverage
swift test --sanitize address
swift test --sanitize thread
just qa-03-detectors
just qa-03-smoke
```

The approved CI-stabilization revision completed the following additional
validation:

```sh
swift test -c release --filter HDXLURITemplateTests.PercentEscapeScannerStressTests
just test-all
swift run -c release HDXLURITemplateQA03 fuzz --iterations 200000 …
swift run -c release HDXLURITemplateQA03 concurrency --operations 100000
swift run -c release HDXLURITemplateQA03 scaling --baseline Hardening/QA03/baselines.json --samples 5
```

Results:

- the public API/README gate built and ran the external consumer in Debug and
  Release, emitted the public symbol graph, and verified three generated
  headers;
- Debug passed 204 tests;
- `HEAVY_DEBUG` and Release each passed 205 tests;
- Address Sanitizer and Thread Sanitizer each passed 204 tests;
- the pinned conformance runner passed all 270 cases;
- detector controls proved seed replay, quadratic rejection, and TSan race
  detection;
- deterministic fuzz completed 200,000 iterations;
- Swift-task serial, Swift-task parallel, and native-thread phases each
  completed 100,000 operations with one identical result digest; and
- all six scaling workloads passed with fitted exponents below the 1.25
  ceiling.
