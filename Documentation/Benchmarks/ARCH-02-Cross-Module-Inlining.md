# ARCH-02: cross-module inlining audit

Tracking issue: [#36](https://github.com/plx/hdxl-uri-template/issues/36)

## Decision

The package retains no source-level `@inlinable`, `@usableFromInline`,
`@inline(__always)`, or `@_alwaysEmitIntoClient` annotations.

The audit found 377 annotations across 50 of the library's 52 Swift files.
They serialized parser, expansion, storage, value-model, assertion, and support
implementation into consuming modules without declaration-level evidence. A
controlled public-client A/B comparison found no material end-to-end benefit
that justified retaining any site.

Ordinary module optimization remains enabled. This decision does not adopt
library evolution, add a binary-compatibility promise, or prevent a future
annotation backed by a separately reviewed consumer workload and measured
benefit.

## Inventory

The permanent `inventory-cross-module-inlining.swift` script classifies every
source occurrence by public API, parser, expansion, storage, Codable,
descriptions, Objective-C, tests/assertions, or support.

| Category | Before `@inlinable` | Before `@usableFromInline` | Before forced inline | After total |
| --- | ---: | ---: | ---: | ---: |
| Public API | 30 | 5 | 0 | 0 |
| Parser | 6 | 13 | 0 | 0 |
| Expansion and value model | 151 | 119 | 0 | 0 |
| Storage | 4 | 7 | 0 | 0 |
| Codable | 0 | 0 | 0 | 0 |
| Descriptions | 0 | 0 | 0 | 0 |
| Objective-C | 0 | 0 | 0 | 0 |
| Tests and assertions | 0 | 4 | 4 | 0 |
| Support | 20 | 13 | 1 | 0 |
| **Total** | **211** | **161** | **5** | **0** |

The before harness commit
`9a5a1bfe7b0c07d00df1d2ccfc30b3f887712fb1` contains no production-source
change relative to merged base
`d08d73610c09e6a20263bab229724128f1e94770`. The after production commit is
`6e6b052c274f46b57a32f1f2989aac01067dbc5e`.

The checked machine-readable aggregate, raw samples, artifact sizes, and exact
revisions are in
[`Data/ARCH-02/results.json`](Data/ARCH-02/results.json). The inventory command
also emits the complete per-file records:

```console
just arch-02-inventory before-inlining-removal \
  9a5a1bfe7b0c07d00df1d2ccfc30b3f887712fb1

just arch-02-inventory after-inlining-removal \
  6e6b052c274f46b57a32f1f2989aac01067dbc5e
```

## Measurement method

The public-client benchmark is a separate Swift module importing
`HDXLURITemplate` without `@testable`. It measures:

- parsing a representative mixed Unicode template;
- repeated expansion with text and list values;
- representation and variable-name metadata reads;
- value copies plus `Set` hashing/equality; and
- semantic JSON encoding and decoding of `URITemplate`.

Each workload is warmed, run for five samples, checked against a stable result
digest, and reported by median. Clean library and standalone public-consumer
builds each use five fresh scratch directories. Artifact inspection records
the compiled module, source-info, diagnostic textual interface, benchmark
executable, and final universal public-consumer executable.

Both revisions were measured on the same arm64 machine with 16 logical cores,
Xcode 26.6 build 17F113, Apple Swift 6.3.3, and Release optimization. The
external consumer uses SwiftPM's supported `swiftbuild` path, matching the
permanent public-API gate.

The textual interface is emitted only as a diagnostic artifact. Swift warns
that module interfaces require library evolution because this package
deliberately does not enable it. Four `@inlinable` spellings remain in the
after diagnostic interface for compiler-synthesized `RawRepresentable`
initializers/accessors; there are zero such annotations in project source.

Reproduce the full comparison with:

```console
just arch-02-measure before-inlining-removal \
  9a5a1bfe7b0c07d00df1d2ccfc30b3f887712fb1

just arch-02-measure after-inlining-removal \
  6e6b052c274f46b57a32f1f2989aac01067dbc5e
```

## Results

Runtime medians:

| Public-client workload | Before ns/op | After ns/op | Change |
| --- | ---: | ---: | ---: |
| Parse | 3,803.282 | 3,824.939 | +0.569% |
| Expansion | 5,607.580 | 5,605.153 | -0.043% |
| Metadata | 0.559 | 10.757 | +1,822.895% |
| Copy and hash | 611.103 | 633.387 | +3.646% |
| Semantic Codable | 5,087.379 | 5,094.348 | +0.137% |

Inlining had allowed the consuming optimizer to hoist and collapse the
deliberately repeated metadata getter workload. Removing it adds about
10.2 nanoseconds per composite access, or about 51 milliseconds across five
million accesses. That synthetic repetition is useful for exposing the
cross-module effect, but the absolute cost is not material to ordinary
parse-once use and does not justify serializing the storage graph into every
consumer. Parse, expansion, hashing, and Codable remain within 3.7%, with
identical result digests.

Clean-build medians:

| Build | Before | After | Change |
| --- | ---: | ---: | ---: |
| Library target | 3.983 s | 4.183 s | +5.004% |
| Standalone public consumer | 7.409 s | 6.692 s | -9.686% |

Five clean samples are enough to quantify this host run but not to claim a
portable compiler-speed guarantee. The consumer direction and artifact
reductions are consistent with removing serialized bodies; the small library
median increase is retained as measured rather than explained away.

Artifact sizes:

| Artifact | Before bytes | After bytes | Change |
| --- | ---: | ---: | ---: |
| Compiled Swift module | 1,213,636 | 238,952 | -80.311% |
| Swift source info | 170,224 | 48,288 | -71.633% |
| Diagnostic textual interface | 105,896 | 10,067 | -90.494% |
| Public-consumer executable | 1,503,360 | 1,141,888 | -24.044% |
| Benchmark executable | 786,896 | 606,176 | -22.966% |

The emitted artifacts contain the same public contract while no longer
embedding the package's implementation bodies and supporting internal
declarations. `just check-public-api` independently verifies the public symbol
graph, generated Objective-C absences, README examples, and external consumer.

## Permanent verification

- `just check-cross-module-inlining` fails on any source-level cross-module or
  forced-inline annotation.
- `just test-check-cross-module-inlining` proves the detector rejects all four
  forbidden spellings and accepts clean source.
- `just check-public-api` builds and runs every supported public operation
  from an external consumer in both Debug and Release.
- The complete conformance, Debug, Release, `HEAVY_DEBUG`, sanitizer, and
  hardening suites remain the semantic and concurrency gates.

The 50 legacy source files were not reformatted as part of this mechanical
annotation deletion. Repository-wide formatting remains owned by QA-06/#24,
which ARCH-02 unblocks.
