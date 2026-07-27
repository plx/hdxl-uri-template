# QA-04 public-consumer evidence

## Scope

This record closes QA-04 against the Swift-only support contract selected by
[API-08/#52](https://github.com/plx/hdxl-uri-template/issues/52). The pre-fix
baseline is `c27f85d53f2d45c6de76642778ec346bdea4b4f3`.

## Pre-fix observation

At the baseline SHA, `Tests/PublicAPIConsumer` was a real external Swift
package and imported `HDXLURITemplate` without `@testable`. However, the
boundary was incomplete:

- `Scripts/check-public-api.swift` used `swift build` for the consumer and
  never ran its executable.
- `.github/workflows/core-ci.yml` contained no reference to either
  `PublicAPIConsumer` or `check-public-api`.
- The consumer contained no typed parse/evaluation failure, `NSError`, prefix,
  or asynchronous task coverage.
- The package's internal test suite could continue to compile through
  `@testable import HDXLURITemplate` without proving those operations remained
  available to a supported external client.

The issue's original example of an inaccessible Objective-C expansion is no
longer an applicable product requirement. The approved
[Objective-C decision](../../Decisions/API-08-Objective-C-Support.md) and
completed [removal contract](../../Decisions/API-10-Objective-C-Removal.md)
removed the wrappers, selectors, and `.m` target before the supported
contract. QA-04 therefore verifies their absence instead of recreating an
unsupported consumer.

## Enforced external boundary

The external executable now:

- runs the README text, list, association, undefined, and explode examples;
- runs a successful text-prefix example;
- catches public parse, evaluation, and duplicate-association errors after
  erasure to `Error` and validates their applicable `NSError` surfaces;
- round-trips `URITemplate`, every `URIVariableValue` flavor, and
  `URIVariableValueType` through JSON and property lists;
- shares one immutable `URITemplate` across 64 child tasks and checks every
  expansion; and
- retains compile-time `Sendable`, equality, hashing, and raw-value checks
  without internal imports.

`Scripts/check-public-api.swift` now runs that executable. It also evaluates
the README SwiftPM manifest, requires both executable README examples to
exactly match their compiled source files, validates the selected public symbol
contract, and rejects the removed Objective-C declarations in both canonical
generated headers.

Core CI's supported Debug lane executes the complete check from a clean
checkout. A fixture failure, README drift, public availability regression, or
stale Objective-C wrapper therefore fails the required aggregate gate.

## Local acceptance

The implementation passed:

- `xcrun swift Scripts/check-public-api.swift`;
- `just build-all`;
- `just test-all`, including Debug, `HEAVY_DEBUG`, and Release;
- strict Swift formatting;
- `actionlint` and `yamllint` for Core CI;
- Markdown lint and link validation; and
- `git diff --check`.

Hosted exact-head CI and review evidence remain attached to the closing pull
request so the tested SHA and merge decision are auditable together.
