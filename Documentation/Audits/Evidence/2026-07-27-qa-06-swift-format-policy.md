# QA-06 deterministic Swift formatting policy

Date: July 27, 2026

Tracking issue:
[QA-06/#24](https://github.com/plx/hdxl-uri-template/issues/24)

Baseline revision:
`3fb753d95b3f63a1bce11f41e0806a0849fe8cf0`

## Baseline characterization

The baseline had no checked-in `swift-format` configuration or repository-wide
gate. A formatter invocation from this checkout searched parent directories
and silently inherited a personal configuration four directories above the
repository. Another contributor or a clean CI checkout could therefore receive
different results from the same command.

After installing the selected repository-owned policy, but before changing any
Swift source, strict lint reported 1,070 mechanical findings across 76 files:

| Finding | Count |
| --- | ---: |
| Indentation | 445 |
| Trailing whitespace | 261 |
| Spacing | 196 |
| Trailing comma | 81 |
| Add line break | 40 |
| Remove line break | 39 |
| Line length | 8 |

The findings were confined to 32 library files and 44 test files. Recently
added package, benchmark, hardening, script, and public-consumer Swift sources
already matched the selected layout.

## Checked policy and scope

The repository root now owns a version-1 `.swift-format` configuration for the
formatter supplied by the supported Xcode 26.6/Swift 6.3 toolchain. It fixes
two-space indentation, a 100-column line length, one maximum blank line,
multiline trailing commas, and consistent multiline declaration arguments,
generic requirements, and attributes.

Public declarations must have documentation. The dedicated DocC gate remains
authoritative for complete symbol coverage, structured-comment analysis,
links, and compiled examples. Naming, access-control, synthesized-initializer,
and comment-style rules that are not automatic formatting are disabled; QA-06
does not redesign APIs or mix semantic cleanup into the baseline.

`Scripts/swift-format.sh` provides the exact nonmutating and mutating
invocations:

```sh
./Scripts/swift-format.sh lint
./Scripts/swift-format.sh format
```

The default roots are `Package.swift`, `Benchmarks`, `Hardening`, `Scripts`,
`Sources`, and `Tests`. This allowlist covers all 157 tracked Swift files while
excluding `.build`, editor state, and other generated output. Recursive
selection is limited to `.swift`, so the vendored JSON conformance fixtures are
not scanned or rewritten.

## Isolated mechanical baseline

One formatter pass changed 76 Swift files with 1,020 added and 1,007 deleted
lines. The pass was restricted to the seven mechanical finding categories
listed above. No package behavior, public API, test expectation, fixture,
benchmark input, documentation example, or generated file was changed.

A second complete formatting pass produced an identical binary diff.
`swift-format lint --strict` then reported no findings.

## Failure-oriented detector and CI

`Scripts/test-swift-format.sh` uses validated temporary directories to prove
that:

- deliberately unformatted Swift is rejected;
- applying the formatter makes that file pass;
- a second formatting pass is byte-for-byte idempotent; and
- deliberately unformatted `.build` Swift and a vendored JSON sentinel remain
  byte-for-byte unchanged.

Core CI runs both strict lint and the detector without mutating the checkout in
the Swift 6.3 Debug lane. The required aggregate gate therefore fails closed
for formatting drift or a broken detector.

## Validation record

The local machine exposed Xcode 27/Swift 6.4 rather than the supported Xcode
26.6/Swift 6.3 toolchain. Under that forward toolchain:

- strict repository lint and every detector control passed;
- the second formatting pass was byte-for-byte idempotent;
- Debug passed 204 tests, while `HEAVY_DEBUG` and Release each passed 205;
- all three modes passed the complete 270-case pinned conformance runner;
- the pinned JSON fixture hashes remained unchanged; and
- shell syntax, Justfile parsing, `actionlint`, `yamllint`, and
  `git diff --check` passed.

The aggregate local recipe could not provide supported-toolchain evidence:
Swift 6.4 timed out type-checking an unchanged expression in
`Scripts/check-public-api.swift`, and its SwiftPM emitted a new warning for the
unchanged DocC catalog. Direct package tests passed despite that
forward-toolchain-only warning. The closing pull request's exact-head Core CI
is the authoritative Xcode 26.6/Swift 6.3 validation record.
