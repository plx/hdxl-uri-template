# Post-Remediation Production-Readiness Audit

## Purpose

This playbook defines the audit that must be performed after the URI-template
remediation issue tree is complete and before HDXLURITemplate is represented as
suitable for production use.

It is intentionally more demanding than an ordinary pull-request review. Its
purpose is to answer, with reproducible evidence:

1. Does the package implement RFC 6570, including applicable verified errata?
2. Did every defect found in the initial due-diligence review receive an
   effective regression test and a complete fix?
3. Can malformed, adversarial, concurrent, or unusually large input cause
   incorrect results, a trap, a race, excessive resource use, or disclosure of
   sensitive values?
4. Are the public Swift, Codable, and Objective-C contracts coherent and safe
   to support?
5. Can consumers build, adopt, operate, update, and roll back the package
   within its documented support boundary?
6. Are the documentation, licensing, automation, and release mechanics
   sufficient for a public package?

The output is a go/no-go recommendation tied to one immutable release-candidate
commit. A passing run against one commit does not automatically apply to a
later commit.

**Program navigation:**
[initial due-diligence report](./2026-07-25-pre-release-due-diligence.md) ·
[remediation index](./Production-Readiness-Remediation-Index.md) ·
[remediation execution goal](./Production-Readiness-Remediation-Goal.md) ·
[final-audit issue #44](https://github.com/plx/hdxl-uri-template/issues/44)

## Intentional support boundary

The following constraints are product decisions, not audit findings:

- Swift tools version 6.3.
- Swift language mode 6.
- Apple operating-system versions 26 and later.
- A deliberately small compatibility matrix.

The audit must verify this boundary, document it, and test it. It must **not**
recommend older operating-system or Swift support merely to enlarge the
potential audience.

The minimum release matrix is:

| Lane | Purpose | Required |
| --- | --- | --- |
| macOS 26, Swift 6.3, Debug | Canonical build and complete test suite | Yes |
| macOS 26, Swift 6.3, Release | Optimized build, complete tests, benchmarks | Yes |
| macOS 26, Swift 6.3, `HEAVY_DEBUG` | Expensive invariants and assertions | Yes |
| Apple 26 SDKs for every declared platform | Compile-only package smoke test | Yes |
| Address Sanitizer | Memory-safety and trap-oriented test run | Yes |
| Thread Sanitizer | Concurrency test run | Yes |

The compile-only smoke tests may be consolidated into one CI job. They should
cover iOS, macOS, Mac Catalyst, tvOS, watchOS, and visionOS when all six remain
declared in `Package.swift`. Running the complete behavioral suite on every
platform is not required. A newer compiler or SDK may be tested as an
informational lane, but it does not replace Swift 6.3 and OS 26.

## Audit principles

The auditor must follow these rules:

- Audit a fresh checkout, not the remediation developer's existing build
  directory.
- Treat [RFC 6570](https://www.rfc-editor.org/rfc/rfc6570.html) plus applicable
  verified errata as normative. Treat the shared
  [`uritemplate-test`](https://github.com/uri-templates/uritemplate-test)
  repository as an important conformance corpus, but not as authority when it
  demonstrably conflicts with the RFC.
- Never edit an upstream fixture silently. Any local difference must have
  provenance, rationale, and a regression test.
- Preserve raw command output and machine-readable results. A prose statement
  that a command "passed" is not sufficient evidence.
- Run tests that prove both positive behavior and expected failure behavior.
- Distinguish an expected parse rejection from an expected expansion failure.
- Do not weaken or skip a test to obtain a green audit.
- Do not fix release-candidate code during the audit. Record a finding, mark
  the audit no-go when required, and begin a new audit on the fixed commit.
- Do not include secrets, production template values, credentials, private
  URLs, or personal data in committed evidence.
- Record every exception. An undocumented exception is a failed gate.

At least one auditor should not be the primary author of the remediation. If
that is impractical, a second maintainer must independently inspect the
evidence and sign the result.

## Required inputs

Do not begin the final audit until all of the following exist:

- A release-candidate commit SHA.
- The
  [initial due-diligence report](./2026-07-25-pre-release-due-diligence.md).
- The [remediation index](./Production-Readiness-Remediation-Index.md), the
  [top-level epic #5](https://github.com/plx/hdxl-uri-template/issues/5), and
  all component epics.
- A traceable list of every child issue and its closing pull request.
- A proposed version number.
- A draft changelog and release notes.
- A documented public API and Codable decision.
- A documented Objective-C support decision.
- A pinned revision or update policy for `uri-templates/uritemplate-test`.
- A third-party licensing and provenance inventory.
- A CI configuration intended to be used after release.
- A generic production-canary and rollback template. If a first load-bearing
  adopter is already identified, also require its populated, owner-approved
  plan; otherwise adopter-specific execution remains a conditional post-package
  gate.
- A checked-in audit-harness inventory that records the repository path, exact
  build/run invocation, deterministic inputs or seeds, expected output schema,
  and artifact location for:
  - the complete conformance runner;
  - the public Swift consumer and conditional Objective-C consumer;
  - parser, evaluator, and Codable fuzzers;
  - concurrency stress;
  - representative and adversarial benchmarks.

The inventory must let an independent auditor execute the existing tools. The
final audit is not the place to invent substantial missing harnesses. A missing
required harness is a finding and ordinarily a no-go until the owning
remediation ticket supplies it.

If an issue was closed as "won't fix" or "accepted risk," its disposition,
owner, impact, and expiry/review date must be available before the audit.

## Evidence layout

Create one evidence bundle for the audited commit. Raw artifacts may be stored
as durable CI artifacts rather than committed to Git when their size would
bloat the repository.

Use this logical layout:

```text
production-readiness-audit/
  audit-report.md
  audit-manifest.json
  finding-register.md
  remediation-traceability.csv
  environment/
    checkout.txt
    toolchain.txt
    package-description.json
    dependency-graph.txt
  build-and-test/
    debug.log
    release.log
    heavy-debug.log
    platform-builds/
    test-results/
    coverage/
  conformance/
    upstream-provenance.txt
    fixture-sha256.txt
    case-manifest.json
    results.json
    errata-review.md
  api/
    symbol-graph/
    api-diff.txt
    codable-results.json
    objc-consumer.log
  robustness/
    address-sanitizer.log
    thread-sanitizer.log
    fuzzing/
    concurrency/
  performance/
    environment.txt
    raw-results.json
    summary.csv
    analysis.md
  security-and-privacy/
    threat-model.md
    source-scan.txt
    dependency-and-action-review.md
  release/
    clean-consumer.log
    documentation-review.md
    license-review.md
    canary-plan.md
  sign-off.md
```

`audit-manifest.json` must include:

- Audit start and completion timestamps in UTC.
- Auditor names or agent identifiers.
- Repository URL and release-candidate commit SHA.
- Whether the worktree was clean.
- Proposed package version.
- Host hardware and operating-system build.
- Xcode, SDK, Swift, Clang, and SwiftPM versions.
- Build configuration and important environment settings.
- Upstream conformance-fixture URL, branch, commit, and retrieval time.
- SHA-256 digest of every fixture used.
- Deterministic random seeds, fuzz duration, and iteration counts.
- Links or content digests for every raw artifact.
- The final verdict.

## Phase 1: Establish a trustworthy checkout

### 1.1 Create and identify a clean checkout

Use a fresh clone or detached worktree at the exact release-candidate SHA.
Record commands and output equivalent to:

```sh
git rev-parse HEAD
git status --short --branch
git remote -v
git log -1 --show-signature --format=fuller
git submodule status --recursive
git tag --points-at HEAD
```

The release-candidate SHA must match the SHA in the audit manifest and all CI
artifacts. The worktree must be clean before and after the audit. If the audit
requires generated files, keep them outside the checkout or prove that only
ignored files were created.

Verify the expected branch-protection and review policy separately through the
hosting service. Do not infer it from local Git configuration.

### 1.2 Capture the toolchain

Record at least:

```sh
sw_vers
uname -a
xcodebuild -version
xcodebuild -showsdks
xcrun swift --version
swift --version
swift package dump-package
swift package describe --type json
```

Confirm all of the following:

- `// swift-tools-version: 6.3` appears in `Package.swift`.
- The package uses Swift language mode 6.
- Every declared Apple minimum is version 26.
- CI selects a toolchain that actually reports Swift 6.3; an unpinned newer
  default toolchain is not a substitute.
- The package does not accidentally claim Linux, Windows, or older Apple
  platform support.

### 1.3 Start with no cached build state

Build from an empty SwiftPM build directory. Preserve the initial dependency
resolution and build logs. Confirm that the package does not rely on:

- A developer's global build products.
- An undeclared package dependency.
- An untracked generated source.
- A network fetch other than declared dependencies.
- An environment variable that is absent from documentation and CI.

Review `Package.resolved` if one exists. Record that the library has no runtime
third-party dependencies if that remains true; do not assume this from the
initial audit.

## Phase 2: Build and test gates

### 2.1 Canonical SwiftPM runs

From the clean checkout, run and preserve complete logs for:

```sh
swift build
swift test
swift build -c release
swift test -c release
swift test -Xswiftc -DHEAVY_DEBUG
```

Also run every aggregate command advertised to contributors, including:

```sh
just build-all
just test-all
```

Adapt the command list if the repository intentionally replaces these recipes,
but execute the documented public equivalents. No advertised configuration may
be broken.

Acceptance criteria:

- Every command exits zero.
- There are no unexpected test skips.
- There are no compiler warnings from package source.
- There are no unhandled-resource warnings.
- Debug, Release, and `HEAVY_DEBUG` exercise the same public conformance
  corpus.
- `HEAVY_DEBUG` assertions add validation rather than changing correct output.
- Test output is bounded enough to be useful in CI; exhaustive loops should
  report concise failures instead of tens of thousands of argument rows.

Record the number of discovered, run, passed, failed, skipped, and expected-
failure tests for every configuration. A test process exiting zero without
discovering the expected test count is a failure.

### 2.2 Coverage

Run source coverage in a non-sanitized Debug configuration and preserve the
machine-readable profile:

```sh
swift test --enable-code-coverage
```

Use the toolchain's `llvm-cov` to report coverage for production targets while
excluding tests and generated glue.

Coverage is diagnostic, not the release decision. Investigate every uncovered
branch involving:

- Parser rejection.
- Modifier validation.
- Percent encoding.
- Unicode scalar boundaries.
- Codable failure.
- Objective-C error bridging.
- Invariant enforcement.

Do not accept a high aggregate percentage as a substitute for the behavioral
checks below.

### 2.3 Declared-platform compilation

Use `xcodebuild -list` to discover the generated package scheme, then build that
scheme with code signing disabled for generic OS 26 destinations. Cover every
platform declared in `Package.swift`.

Typical destinations are:

```text
generic/platform=macOS
generic/platform=iOS
generic/platform=macOS,variant=Mac Catalyst
generic/platform=tvOS
generic/platform=watchOS
generic/platform=visionOS
```

Record the exact working commands, selected SDK versions, and logs. If Xcode
uses different destination spelling, record the discovered values rather than
blindly copying the examples.

Acceptance criteria:

- All declared platforms compile using their version-26 SDK.
- No source is accidentally excluded from one platform.
- Objective-C exposure compiles on every platform on which it is documented.
- A platform-specific exception is reflected in `Package.swift` and public
  documentation, not only in CI.

## Phase 3: Independent RFC conformance verification

### 3.1 Retrieve and pin current upstream fixtures

Independently clone the official shared test repository:

```text
https://github.com/uri-templates/uritemplate-test
```

Record:

- Retrieval time.
- Remote URL.
- Default branch.
- Exact commit SHA.
- Latest commit metadata.
- SHA-256 digest of each JSON fixture.
- The upstream license at that commit.

The audit must examine these four suites:

```text
spec-examples.json
spec-examples-by-section.json
extended-tests.json
negative-tests.json
```

Compare them byte-for-byte and semantically with any vendored copies. For every
difference, record whether the local fixture is stale, intentionally augmented,
or intentionally changed. A changed upstream example must remain available
unaltered, with any local interpretation represented as a separate test.

The project may pin a reviewed upstream commit for reproducibility, but the
auditor must also inspect upstream `HEAD` at audit time. Any cases added after
the project pin must be run before release or explicitly adjudicated against
the RFC.

### 3.2 Prove complete test enumeration

Produce a machine-readable case manifest containing, for every suite:

- Suite filename and digest.
- Group name.
- Zero-based case index.
- Template text.
- Variable set identifier or digest.
- Expected string, set of permitted strings, or expected failure.
- Whether failure is expected during parsing or expansion, when knowable.
- Test identifier that executed the case.
- Actual outcome.

Count both source cases and concrete expected-output alternatives. Confirm:

- No file was merely decoded without executing its cases.
- No group or case was filtered, skipped, duplicated accidentally, or shadowed
  by another fixture.
- Both `spec-examples.json` and
  `spec-examples-by-section.json` execute despite their overlap.
- Every `false` result in `negative-tests.json` is treated as expected failure.
- A negative succeeds only when parsing or required expansion fails for the
  correct reason; returning an arbitrary error elsewhere is insufficient.
- Permitted alternative strings are handled as alternatives, not as multiple
  required outputs.

The execution count in CI must be derived from and equal to the fixture count.
Add an explicit count assertion so deleting a fixture or disconnecting a suite
cannot leave a deceptively green run.

### 3.3 Review RFC text and verified errata

Read RFC 6570 and query the
[RFC Editor's RFC 6570 errata index](https://www.rfc-editor.org/errata/rfc6570)
at audit time. Record each erratum, its status, and whether it affects this
package.

At minimum, explicitly verify
[verified erratum 6937](https://www.rfc-editor.org/errata/eid6937), which
restores apostrophe to the literal-character alternatives. Include an
apostrophe template in the executed regression corpus.

Build a concise requirements matrix covering:

- Literal grammar and percent-encoding of non-URI Unicode.
- Operator characters and expression grammar.
- Variable-name grammar, including percent-encoded characters and dotted
  names.
- Undefined and empty values.
- Scalar, list, and association expansion.
- Reserved, fragment, label, path, path-parameter, query, and continuation
  operators.
- Explode modifiers.
- Prefix modifiers, valid numeric grammar, Unicode code-point counting, and
  prohibition on composite values.
- Preservation of valid percent triplets and encoding of invalid ones.
- All normative error or non-applicability rules.

Link every requirement to one or more executed tests. If the shared suite lacks
a boundary, add a package-owned test rather than treating the omission as
permission to leave it untested.

When an upstream shared test and the normative RFC appear inconsistent:

1. Preserve and run the upstream test unchanged.
2. Cite the exact RFC text and erratum status.
3. Obtain maintainer review of the interpretation.
4. File an upstream issue when appropriate.
5. Record the local behavior and rationale publicly.

### 3.4 Independently exercise the public API

Do not rely solely on `@testable import`. Compile and run a small consumer that
uses only the package's public API to:

- Parse every positive fixture.
- Expand every positive fixture.
- Exercise every negative fixture.
- Encode and decode representative templates and values.
- Use templates as documented from synchronous and concurrent code.

This catches accidental dependence on internal test helpers and verifies that
the shipped surface is sufficient for actual consumers.

## Phase 4: Regression audit for previously discovered defects

For each confirmed behavioral defect, inspect the closing change and confirm it
added a focused test that fails before the fix. Demonstrate this using either:

- The test against the pre-fix parent commit in a disposable secondary
  worktree, or
- A temporary mutation that recreates the defect in that disposable worktree.

For nonbehavioral work, require equivalent pre-change evidence appropriate to
the ticket: an API or symbol-graph diff, compiler/linter failure, broken
consumer build, deliberately failing workflow gate, missing-file or provenance
check, benchmark baseline, documentation build failure, or another objective
signal named in the issue. Decision and research tickets must provide their
required analysis and durable conclusion; they do not need an artificial
failing unit test.

Record the exact command, input, and before/after result. Never mutate the
immutable release-candidate checkout to manufacture evidence. Delete or retain
the secondary worktree according to the evidence policy, then prove the audited
checkout remained clean.

The following regression inventory is mandatory even if issue titles or code
organization changed.

### 4.1 Literal grammar and evaluation

Verify:

- `~` is accepted in literals.
- Apostrophe is accepted as required by verified erratum 6937.
- Literal ASCII permitted by the grammar is preserved exactly.
- Disallowed ASCII is rejected or encoded according to its syntactic context.
- A literal such as `café/{var}` expands to `caf%C3%A9/value`.
- Representative one-, two-, three-, and four-byte UTF-8 literal scalars are
  percent-encoded correctly.
- Existing valid percent triplets in literals are preserved.
- Malformed percent triplets are rejected.
- Hexadecimal percent output uses the documented case consistently.

Exhaustively test every ASCII scalar at relevant literal boundaries rather than
only the previously mistyped characters.

If an RFC `ucschar` table remains in production or test support, explicitly
verify the `U+F900...U+FDCF` range and its boundaries. In particular, `U+FDD0`
through `U+FDEF` are noncharacters and must not become accepted through the
historical `U+FDFC` endpoint typo. Prefer one authoritative character-table
definition shared by production and tests.

### 4.2 Reserved-character set

Verify every RFC 3986 unreserved, gen-delim, and sub-delim character
individually under every applicable operator.

Include an explicit regression proving:

```text
template: {+x}
value:    a&b^c
expected: a&b%5Ec
```

Repeat the character-set table test for fragment expansion. A hand-written
character string without an exhaustive table test is not sufficient.

### 4.3 Strict expression and variable parsing

Confirm these malformed forms fail:

```text
{x,}
{,x}
{x,,y}
{x, y}
{ leading_space}
{trailing_space }
{}
{x.}
{x..y}
{%2x}
```

Confirm valid dotted and percent-encoded variable names still succeed.

If the API exposes a canonical or template representation, assert that:

- Its output is valid RFC syntax.
- Reparsing it succeeds.
- It does not introduce forbidden whitespace.
- It is stable and deterministic.
- The design clearly states whether original spelling or canonical spelling is
  preserved.

### 4.4 Prefix modifier grammar

Test the complete boundary partition:

```text
invalid: :     :0     :00     :01     :0001     :+1     :-1     :10000
valid:   :1    :9     :10     :999     :9999
```

Also test non-ASCII digits, whitespace, overflow-length digit strings, and
trailing junk. Parsing must enforce the RFC grammar directly rather than rely
on the permissiveness of a general-purpose integer parser.

### 4.5 Composite prefix rejection

For every applicable operator, prove a prefix modifier fails when the supplied
value is:

- A nonempty list.
- An empty list.
- A nonempty association.
- An empty association.

Include `{keys:1}` and `{+keys:1}`. Confirm scalar prefix expansion still works.
The test must distinguish expected non-applicability from an unrelated failure.

### 4.6 Unicode and percent-encoded prefix boundaries

Verify prefix length counts Unicode code points and never:

- Splits a Swift Unicode scalar.
- Splits a valid percent triplet.
- Splits the byte sequence representing one percent-encoded Unicode scalar.
- Emits a stray `%` or incomplete triplet.
- Double-encodes a preserved triplet.

Include:

- One-, two-, three-, and four-byte Unicode scalars.
- Combining sequences, with expected behavior based on Unicode code points
  rather than user-perceived grapheme clusters.
- `%C3%A9` under `{+x:1}`.
- Mixed literal, raw Unicode, and percent-encoded input.
- Boundaries immediately before and after encoded characters.

### 4.7 Linear percent-escape scanning

Retain a correctness test for adjacent, malformed, mixed-case, and dense
percent triplets. Retain a performance regression that exercises at least
10,000, 20,000, 40,000, and 80,000 `%20` triplets under reserved expansion.

The performance analysis in Phase 8 determines pass/fail. A timeout-only unit
test is insufficient because hardware-dependent thresholds are brittle.

### 4.8 Association invariants and trap elimination

Verify the documented duplicate-key policy through:

- Swift construction.
- Codable decoding.
- Codable round-trip.
- Objective-C construction.
- Objective-C dictionary projection, if retained.
- Exploded and non-exploded expansion.

Test duplicate keys, empty keys if representable, unequal Objective-C key/value
array lengths, `nil` where nullability permits it, and very large associations.

No public input may reach `precondition`, `fatalError`,
`Dictionary(uniqueKeysWithValues:)` with unvalidated duplicates, a forced cast,
or a forced unwrap. Expected rejection must use the documented Swift error,
failable initializer, or Objective-C `NSError` contract.

### 4.9 Codable validation and representation

The settled `URITemplate.Codable` contract is semantic serialization of one
authoritative, validated template-source string. The final audit must reject a
release candidate that reopens public AST serialization or decodes templates
without passing through the parser.

Verify:

- Encoding does not expose the internal AST.
- Decoding passes through the same validation as public string parsing.
- Crafted payloads cannot create `{}`, an empty expression, or any otherwise
  invalid internal state.
- Valid template round-trips preserve the documented semantic identity.
- Arrays and dictionaries of templates round-trip.
- JSON, property-list XML, and property-list binary encoders/decoders work when
  claimed.
- Malformed, truncated, oversized, wrong-type, and unknown-version data fail
  without a trap.
- Decoding data created by the documented compatibility window works.
- Data outside that compatibility window fails clearly or uses a documented
  fallback.

If a compiled-cache API exists, audit it separately. It must be documented as
disposable and must contain:

- A cache-format version.
- The authoritative source string or a secure reference to it.
- Validation that the compiled payload corresponds to the source.
- Safe detection of corrupt or obsolete payloads.
- Automatic reparsing from source.

The compiled payload must never be the only surviving copy of a durable
template unless its format has separately been designed and supported as
persistence.

### 4.10 Error semantics and privacy

Verify every public `LocalizedError` implements `errorDescription` and bridges
to a meaningful `NSError`.

Test errors:

- As their concrete Swift type.
- Caught as `any Error`.
- Bridged to `NSError`.
- Through the Objective-C API.
- Through Codable.

Default error descriptions must not contain full variable values, parameter
dictionaries, credentials, authorization headers, API tokens, query secrets,
or unbounded attacker-controlled strings. If detailed diagnostics exist, prove
that they are explicitly opt-in and documented as potentially sensitive.

### 4.11 Build configuration and API cleanup

Verify:

- `HEAVY_DEBUG` compiles and runs.
- No stale `storage` or similarly configuration-only reference exists.
- The unintended `Comparable` conformances for `URITemplate`,
  `URIVariableValue`, and `URIVariableValueType` are absent from the public
  symbol graph.
- Removing `Comparable` did not remove intended `Equatable`, `Hashable`,
  `Sendable`, or Codable behavior.
- Dead or test-only RFC character tables cannot silently diverge from
  production definitions.

## Phase 5: Public API, ABI, and architecture review

### 5.1 Produce and inspect the public API

Extract the public symbol graph with the Swift 6.3 toolchain. Compare it with:

- The pre-remediation public surface.
- The intended release API documented by the remediation issues.
- The most recent published version, if one exists.

Use Swift's API digester or an equivalent symbol-graph comparison and preserve
the report. Classify each difference as:

- Intended source-breaking change.
- Intended additive change.
- Accidental exposure.
- Accidental removal.
- Documentation-only difference.

Because Swift packages are normally built from source, do not claim a stable
binary ABI unless library evolution is deliberately enabled and tested.
Nevertheless, public declarations are a source-compatibility commitment and
must be reviewed before 1.0.

Inspect every public declaration for:

- A clear purpose and name.
- Appropriate access level.
- Useful documentation.
- Sendability and actor-isolation semantics.
- Error behavior.
- Empty and undefined semantics.
- Ownership and mutation behavior.
- Consistency between Swift and Objective-C.
- Availability matching the OS 26+ boundary.

Compile a consumer without `@testable import`. Warnings or missing operations
in this consumer are audit findings.

### 5.2 Review value semantics and invariants

Confirm that every publicly constructible and decodable value satisfies its
internal invariants in ordinary Release builds, not only under
`HEAVY_DEBUG`.

Check the laws for each advertised conformance:

- Equality is reflexive, symmetric, and transitive.
- Equal values have equal hashes.
- Encoding and decoding do not change equality unexpectedly.
- Template representation round-trips according to its documented identity.
- Dictionary and set membership remain stable.
- Concurrent reads cannot mutate observable value semantics.

Search for and individually adjudicate every occurrence of:

```text
@unchecked Sendable
unsafe
precondition
preconditionFailure
assertionFailure
fatalError
try!
as!
force unwraps
@inlinable
@usableFromInline
```

A source search is only the starting point. For each match, document why it is
unreachable from public input or replace it before release.

### 5.3 Review storage and synchronization

If `URITemplate` remains publicly immutable, determine whether mutable
copy-on-write storage, locks, and lazy caches still provide measured value.

For each retained lock or `@unchecked Sendable` conformance:

- Document the protected state.
- Identify every read and write.
- Prove no protected reference escapes.
- Verify copying preserves value semantics.
- Verify hashing and equality cannot race with lazy mutation.
- Measure cold and warm contention.
- Run the concurrency tests under Thread Sanitizer.

An architecture simplification may be deferred only when the current design is
correct, measured, documented, and free of release-blocking contention.

### 5.4 Review Codable as a public promise

For `URITemplate`, verify and document:

- The single validated semantic-string shape.
- Compatibility guarantees across package versions.
- How invalid and legacy data is handled.
- Whether the source string is preserved or canonicalized.
- That decoding invokes the public parser and cannot construct an otherwise
  unreachable template.

Review `URIVariableValue.Codable` separately according to its explicit
retain/remove decision and, if retained, its documented semantic tagged-union
schema. Do not treat that separate decision as permission to change
`URITemplate.Codable`.

Benchmark reparsing strings against decoding each supported serialization. Any
separately named compiled cache must be opaque, versioned, disposable, and
validated against authoritative source. It is not the public Codable contract.
Do not retain compiled-AST serialization solely on an unmeasured assumption
that it is faster.

### 5.5 Review Objective-C support

If Objective-C remains supported, compile and run a real `.m` consumer target.
Swift tests calling Objective-C wrappers do not satisfy this gate.

The consumer must exercise:

- Template parsing.
- Expansion.
- Scalar, list, association, empty, and undefined values.
- Expected parse and expansion errors through `NSError **`.
- Duplicate association keys.
- Unequal key/value array lengths.
- Nullability annotations.
- `NSCopying`, equality, hashing, and secure coding if advertised.

Confirm generated Swift names and Objective-C selectors are usable and
documented. No Objective-C-callable path may terminate the process on caller
input.

If Objective-C is removed or explicitly limited, verify that the package and
README no longer imply a broader contract.

## Phase 6: Robustness and fuzzing

### 6.1 Sanitizers

Run the complete suite separately with Address Sanitizer and Thread Sanitizer
using the Swift 6.3 toolchain:

```sh
swift test --sanitize=address
swift test --sanitize=thread
```

Also run targeted stress executables under the relevant sanitizer. Do not run
both sanitizers simultaneously unless the toolchain explicitly supports it.

Acceptance criteria:

- Zero sanitizer reports.
- Zero crashes, traps, hangs, and unexpected signals.
- Zero ignored suppressions added merely to pass this package.
- Expected platform-runtime noise, if any, is isolated and justified with a
  minimal reproduction outside the package.

### 6.2 Parser fuzzing

Seed a deterministic parser corpus with:

- All four shared fixture suites.
- Every package-owned regression.
- All operators and modifiers.
- Valid and malformed percent triplets.
- ASCII control characters.
- Whitespace in every grammar position.
- Dotted and percent-encoded variable names.
- Unicode scalars from each UTF-8 width.
- Combining marks and normalization variants.
- Very long literals, variable names, expressions, and component sequences.

Perform both structure-aware generation and byte/string mutation. For each
accepted template, evaluate it with multiple value shapes. Record seed,
duration, iteration count, corpus digest, peak memory, and every minimized
failure.

Minimum release-candidate budget:

- At least 1,000,000 deterministic generated or mutated templates, and
- At least 30 minutes of coverage-guided fuzzing when a suitable harness is
  available.

If the supported toolchain cannot run the checked-in coverage-guided harness,
the fallback is all of:

- At least 5,000,000 deterministic structure-aware and mutation cases.
- At least ten recorded nonoverlapping seeds.
- At least 60 minutes of aggregate execution.
- Instrumented production-code coverage before and after the generated corpus,
  with every newly reachable parser/evaluator error branch retained as a
  minimized seed.
- Mutation checks proving that the harness detects representative acceptance,
  rejection, percent-encoding, prefix-boundary, and invariant faults.

Record the limitation as at least a Medium finding and explain why the fallback
is adequate for this candidate. If neither the coverage-guided budget nor the
complete fallback can run, the audit is no-go. Do not describe ordinary random
unit tests as equivalent to either path.

### 6.3 Value and evaluator fuzzing

Generate variable maps containing:

- Undefined, empty, and nonempty scalar values.
- Empty and large lists.
- Empty and large associations.
- Duplicate keys according to the public construction policy.
- Reserved delimiters.
- Dense `%`, valid triplets, and malformed triplets.
- Raw and pre-percent-encoded Unicode.
- Strings at prefix boundaries.

Properties to assert:

- Evaluation is deterministic.
- Evaluation never traps.
- Output contains no incomplete percent triplet introduced by the library.
- Prefix handling respects Unicode code-point boundaries.
- Expansion type and modifier rules are enforced.
- Repeated evaluation of one parsed template has stable results.
- Errors have bounded, non-sensitive descriptions.

### 6.4 Codable fuzzing

Feed each public decoder:

- Arbitrary bytes.
- Mutated valid archives.
- Truncated archives.
- Deeply nested JSON and property lists.
- Oversized strings and collections within the audit machine's safe limits.
- Legacy formats in the documented compatibility window.
- Internal-AST-shaped payloads from the pre-remediation implementation.

Rejecting old internal representations is acceptable when no released
compatibility promise exists, but it must fail safely and intentionally.

### 6.5 Failure handling

Every crash, timeout, sanitizer report, memory blow-up, or unexpected success
must become:

1. A minimized reproducer.
2. A finding with severity.
3. A regression test proposal.
4. A no-go decision when it meets the severity rules below.

Do not discard a failure merely because the original random seed is difficult
to reproduce. Preserve the corpus and investigate.

## Phase 7: Concurrency audit

Run concurrency stress under Thread Sanitizer and without sanitizers.

At minimum:

- Share one parsed template across the Swift concurrency runtime and native
  threads.
- Perform at least 100,000 mixed expansions, hashes, equality checks, variable-
  name reads, template-representation reads, and Codable encodes.
- Mix cold-cache and warm-cache access if caches remain.
- Parse separate templates concurrently.
- Repeatedly copy values across task boundaries.
- Use successful and failing expansion inputs.
- Run with one worker and with a worker count at least equal to the host's
  active cores.

Assert results against single-threaded golden outputs. Capture operation counts,
wall time, failures, and TSan output.

Acceptance criteria:

- Zero data races and exclusivity violations.
- Zero nondeterministic output.
- Zero deadlocks, livelocks, or hangs.
- Equal/hash laws remain true during concurrent reads.
- Parallel warm reads do not exhibit unexplained catastrophic contention.

If `@unchecked Sendable` remains, an independent reviewer must approve the
written synchronization argument. A green TSan run alone is not a proof.

## Phase 8: Performance and resource-scaling audit

### 8.1 Benchmark hygiene

Run benchmarks:

- In Release mode.
- Without sanitizers, coverage, logging, or a debugger.
- On an otherwise idle, identified machine.
- With CPU architecture and active core count recorded.
- After warm-up.
- With multiple independent samples.

Report raw samples plus median, p95, dispersion, throughput, and peak resident
memory. Compare with the initial-audit baseline and the designated
pre-remediation commit on the same machine and toolchain.

Do not make release claims from a single timing.

For historical orientation, the initial audit measured representative Release
parsing at about 4.48 microseconds per operation and representative expansion
at about 4.31 microseconds per operation on its audit machine. It also observed
the following defective percent-dense scaling:

| `%20` triplets | Initial-audit time |
| ---: | ---: |
| 10,000 | 0.162 seconds |
| 20,000 | 0.591 seconds |
| 40,000 | 2.406 seconds |
| 80,000 | 10.502 seconds |
| 100,000 | 15.981 seconds |

These numbers are evidence of the old quadratic shape, not portable absolute
performance thresholds. Reproduce old and new revisions on the same audit
machine for a valid comparison.

### 8.2 Required workloads

Benchmark:

- Parsing representative short, medium, and long templates.
- Repeated evaluation of a pre-parsed representative template.
- Every expansion operator.
- Scalar, list, and association values.
- Empty and undefined values.
- Prefix and explode modifiers.
- Raw Unicode and pre-percent-encoded Unicode.
- Error paths.
- Cold and warm metadata access.
- Concurrent reads of one template.
- Codable encode/decode.
- Direct reparsing of the authoritative string.

If a compiled-cache representation exists, compare all of:

- Parsing the source string.
- Decoding semantic string serialization.
- Decoding the compiled cache.
- Encoded byte size.
- Validation and fallback cost.

### 8.3 Adversarial scaling

For each workload, use multiple doubling sizes and report time and memory:

- Dense valid percent triplets: 10,000, 20,000, 40,000, and 80,000 triplets.
- Dense malformed percent signs.
- Long literal-only templates.
- Many template components.
- Large scalar values.
- Large lists.
- Large associations.
- Long variable names and variable lists.
- Regex/parser near-misses that fail only near the end.

For percent-dense expansion, doubling input should remain consistent with
linear behavior. As a default gate:

- No adjacent doubling may exceed 3.0x after warm-up, and
- The fitted time-complexity exponent across all measured sizes must be no
  greater than 1.25.

If noise invalidates those thresholds, rerun on a quieter machine rather than
waiving them. A persistent superlinear curve is a release blocker even when
small normal inputs are fast.

Memory must grow linearly or better with input/output size, without large
retained allocations after autorelease pools and task scopes drain.

### 8.4 Regression policy

Define performance budgets before looking at the final numbers. At minimum:

- No material regression in representative parse or expansion throughput
  without an approved correctness or safety tradeoff.
- No newly superlinear path.
- No unbounded cache growth.
- No lock-contention cliff for concurrent immutable reads.
- No claim that serialization improves startup unless measurements demonstrate
  it at realistic template-set sizes.

Every accepted regression needs an owner, rationale, user impact, and follow-up
date.

## Phase 9: Security and privacy review

### 9.1 Threat model

Document trust boundaries for:

- Template source.
- Variable names.
- Variable values.
- Serialized templates and values.
- Objective-C callers.
- Files or network responses supplying cached data.
- The final URI consumer.

Evaluate at least:

- CPU and memory denial of service.
- Traps and process termination.
- URI delimiter injection through reserved or fragment expansion.
- Unexpected schemes such as `javascript:`, `data:`, or `file:`.
- SSRF and destination manipulation in consuming applications.
- Path traversal semantics.
- Percent-encoding ambiguity and double encoding.
- Secret leakage through errors, logs, test output, and telemetry.
- Deserialization of corrupt or hostile archives.

The library need not enforce application-specific scheme, host, or path policy.
It must clearly document that RFC-correct expansion does not make the resulting
URI safe for navigation, network access, or code execution.

### 9.2 Source and binary review

Search production source and generated interfaces for:

- Publicly reachable traps.
- Unsafe pointer operations.
- Forced casts and unwraps.
- Unbounded recursion.
- Catastrophic or superlinear regex/parser behavior.
- Debug descriptions containing values.
- Accidental logging.
- Mutable shared global state.
- Insecure temporary-file use.

Review compiler warnings, linker warnings, and sanitizer output. If the package
remains dependency-free, record that fact. Otherwise inventory transitive
dependencies, their licenses, pinned versions, update policy, and known
vulnerabilities.

Review GitHub Actions and other automation:

- Pin third-party actions to immutable commit SHAs.
- Grant minimum token permissions.
- Do not execute untrusted pull-request code with write-capable credentials.
- Keep secrets out of logs.
- Require review for workflow changes.

### 9.3 Error and telemetry privacy

Use canary-like values containing recognizable fake secrets and prove they do
not appear in:

- `LocalizedError.errorDescription`.
- `NSError.localizedDescription`.
- Test logs.
- Benchmark output.
- CI annotations.
- Default debug or textual descriptions.

If an explicit verbose diagnostic API can include values, its name and
documentation must make that risk unmistakable.

## Phase 10: Licensing, provenance, and ownership

Perform and record a file-level provenance review.

Confirm:

- The root license matches the intended project license.
- Vendored `uritemplate-test` fixtures retain their Apache-2.0 license and
  source/commit attribution.
- The
  [third-party notices file](../../THIRD_PARTY_NOTICES.md)
  identifies every copied fixture or asset.
- RFC-derived Code Components carry any notice required by the RFC Trust legal
  provisions, including the applicable Simplified BSD text where required.
- Copyright years and holders are accurate.
- No fixture was copied from an unrecorded source.
- Generated files identify their generator.
- Contributor and employer ownership questions have been resolved for the
  recreated private work.

The ownership review may require legal or employer confirmation outside this
repository. Record the confirmation, not confidential legal advice.

Missing required license text or unresolved ownership is a release blocker.

## Phase 11: Documentation and user-experience audit

Read the documentation as a new consumer and follow it exactly from a clean
sample package.

The public documentation must cover:

- What RFC 6570 URI templates are and what the package does.
- Installation with a valid version requirement.
- Swift 6.3 and OS 26+ support.
- Parsing and repeated expansion.
- Scalar, list, association, undefined, and empty values.
- Every supported operator and modifier, or a clear RFC reference.
- Error handling.
- Thread-safety and Sendable guarantees.
- Codable semantics and compatibility.
- Objective-C support or its explicit absence/limitations.
- Performance characteristics and any input-size guidance.
- Security warnings for untrusted templates, reserved expansion, URI schemes,
  SSRF, and logging.
- The difference between creating a URI-reference string and Foundation `URL`
  validation or application-specific safety.
- Semantic-versioning and support policy.
- License and fixture attribution.

Required project documents:

- A substantive README.
- API documentation, preferably DocC.
- Changelog.
- Contribution guide.
- Security policy and private reporting route.
- Code of conduct if desired by project governance.
- [Third-party notices](../../THIRD_PARTY_NOTICES.md).
- Release process.

Compile every documentation code sample as a test or documentation build.
Manually verify that a consumer can complete the basic example without
`@testable import` or knowledge of internal types.

## Phase 12: CI and release mechanics

### 12.1 CI verification

Trigger CI from the release-candidate commit and verify the required minimal
matrix defined at the beginning of this document.

CI must:

- Use Swift 6.3 deliberately.
- Build from clean state.
- Run Debug, Release, and `HEAVY_DEBUG`.
- Execute all four conformance suites and assert fixture counts.
- Preserve machine-readable test results.
- Compile every declared Apple OS 26 platform.
- Run public-consumer and real Objective-C consumer tests.
- Run formatting/lint policy selected by the project.
- Treat compiler and unhandled-resource warnings according to documented
  policy.

Address Sanitizer, Thread Sanitizer, fuzzing, and longer benchmarks may be
scheduled or manually required release jobs rather than blocking every pull
request. They must still run against the exact release-candidate SHA and remain
available as evidence.

Inspect a deliberately failing test in a temporary branch or controlled CI
fixture to ensure required jobs actually block merging. A green but nonrequired
job is not an effective gate.

### 12.2 Clean-consumer validation

Create a new package outside the repository that depends on the
release-candidate source in the same way a real consumer will. Before a release
tag exists, declare the remote package URL with SwiftPM's `revision:` requirement
set to the full audited commit SHA. Do not use a local path, movable branch, or
abbreviated revision. The consumer must:

- Resolve from scratch.
- Import only the documented product.
- Compile in Swift 6 language mode using Swift 6.3.
- Parse and expand a representative template.
- Exercise error handling and Codable.
- Resolve and run from the remote commit without local path assumptions.

After creating the immutable release tag, replace the revision requirement with
the intended semantic-version requirement and repeat resolution, build, and
execution before announcing the release.

Verify that:

- The Git tag points to the audited SHA.
- The version is valid semantic versioning for SwiftPM.
- `Package.swift` contains no local paths or development-only dependencies.
- The archive contains the license, README, and required notices.
- Release notes describe breaking changes, support boundary, known
  limitations, and security-relevant behavior.
- The changelog and hosted release agree.
- Rollback means pinning a known prior version or disabling adoption, and that
  procedure is tested.

Do not move or replace a published version tag.

## Phase 13: Production canary and operational validation

Library correctness tests are necessary but do not prove suitability inside a
particular production system. The first load-bearing adopter must run a
controlled canary.

For package sign-off before an adopter is named, audit the generic canary and
rollback template for completeness and mark adopter-specific execution not
applicable. If an adopter is named, require a populated plan with an owner and
predeclared thresholds. Completed canary observations may follow package
release, but production approval for that system remains conditional until they
pass.

### 13.1 Canary design

Before deployment:

- Inventory actual templates and classify which parts are trusted.
- Build a sanitized golden corpus of representative templates and value shapes.
- Compare package output with approved expected output or an incumbent
  implementation.
- Define allowed schemes, hosts, and destinations in the consuming
  application.
- Define maximum input and output sizes appropriate to the application.
- Add a feature flag or dependency rollback path.
- Add telemetry that records counts and latency without raw template values or
  expanded URIs.
- Define an owner and on-call escalation path.

Begin in shadow mode where feasible. Evaluate templates and compare outputs
without using the new result for network access or navigation.

### 13.2 Canary observations

Measure:

- Parse success and failure counts.
- Expansion success and failure counts.
- Output mismatches against the golden/incumbent result.
- Parse and expansion p50, p95, and p99 latency.
- Maximum observed template, value, collection, and output sizes.
- CPU and memory impact.
- Unexpected schemes, hosts, or delimiter structure.
- Error-log and telemetry redaction.
- Crashes, hangs, and watchdog events.

Default minimum observation is both:

- Seven consecutive days, and
- One million representative expansions.

The adopter may choose a different threshold based on traffic, but must record
the rationale before observing results.

### 13.3 Canary acceptance

The canary passes only with:

- Zero incorrect output in the approved golden corpus.
- Zero unexplained shadow mismatches.
- Zero crashes, hangs, traps, or data races.
- Zero sensitive-value disclosures.
- No unapproved destination or scheme change.
- Latency and resource use within the application's predefined budgets.
- Expected errors handled without service degradation.
- A demonstrated rollback.

A package-level release may precede a specific company's canary, but the
package must not be internally designated production-approved for that system
until its canary passes.

## Finding severity and go/no-go rules

Classify every finding by user impact and exploitability, not by estimated fix
size.

### Blocker

Examples:

- Release-candidate identity or evidence cannot be trusted.
- Required license or ownership is unresolved.
- The canonical build or test configuration does not run.
- A current normative RFC requirement lacks an adjudicated implementation.
- The conformance harness omits or silently changes required cases.
- Public input can cause a process trap, memory-safety violation, or data race.
- A critical security or privacy vulnerability exists.

Decision: **No-go.** No exception is permitted.

### High

Examples:

- Any unexplained positive or negative shared-suite failure.
- Incorrect expansion for a supported RFC construct.
- Invalid state can be publicly constructed or decoded.
- Adversarial input has demonstrated superlinear resource growth.
- Error paths disclose plausible secrets by default.
- Public Codable or Objective-C behavior contradicts its documentation.
- A required platform fails to compile.

Decision: **No-go.** Fix and rerun the affected phase plus all downstream
phases.

### Medium

Examples:

- Material API ambiguity without current incorrect behavior.
- A meaningful documentation gap.
- A performance regression within linear bounds.
- Incomplete automation for a check that was performed manually and preserved.

Decision: Ordinarily no-go for 1.0. A pre-1.0 release may accept it only with a
publicly documented limitation, named owner, tracking issue, and review date.
No security, correctness, trap, race, or license issue may be downgraded this
way.

### Low

Examples:

- Cosmetic consistency.
- Minor documentation polish.
- Nonessential developer-experience improvement.

Decision: May ship with a tracking issue. Record it in the final report.

### Informational

No action is required, but the observation may influence future work.

### Final decision rule

A production-ready verdict requires:

- Zero open Blocker findings.
- Zero open High findings.
- Zero unapproved Medium findings.
- Every required phase completed against the same commit.
- Every accepted Medium finding documented as above.
- CI green at the audited SHA.
- Maintainer and independent auditor sign-off.

If code changes after any phase, identify the affected evidence and rerun it.
Any change to parsing, expansion, storage, Codable, concurrency, or build
configuration requires rerunning all conformance, sanitizer, concurrency, and
performance phases.

## Required deliverables

The audit is incomplete without all of these:

1. **Audit report**
   - Executive summary.
   - Exact scope and commit.
   - Methods used.
   - Results by phase.
   - Limitations.
   - Final go/no-go recommendation.

2. **Audit manifest**
   - Machine-readable provenance and artifact digests described above.

3. **Finding register**
   - ID, title, severity, affected component, reproducer, impact, evidence,
     owner, disposition, and linked issue.

4. **Remediation traceability matrix**
   - Every initial-review finding and remediation issue mapped to its fixing
     commit, behavioral regression or other ticket-appropriate pre-change
     evidence, and final result.

5. **Conformance package**
   - Upstream commit and license.
   - Fixture digests.
   - Complete case manifest.
   - Machine-readable outcomes.
   - RFC and errata requirements matrix.

6. **Build and verification artifacts**
   - Debug, Release, `HEAVY_DEBUG`, coverage, platform-build, public-consumer,
     and Objective-C-consumer logs.

7. **Robustness package**
   - Sanitizer logs.
   - Fuzz seeds, corpus digests, counts, duration, minimized failures.
   - Concurrency workload and output.

8. **Performance package**
   - Hardware/toolchain environment.
   - Benchmark source.
   - Raw samples.
   - Summary and complexity analysis.
   - Baseline comparison.

9. **Security, privacy, and license review**
   - Threat model.
   - Trap/unsafe/source review.
   - Redaction verification.
   - Automation review.
   - Provenance and notice inventory.

10. **Release and operational package**
    - Clean-consumer result.
    - Documentation checklist.
    - Release/rollback procedure.
    - Canary plan and, when applicable, canary results.

11. **Signed decision**
    - Completed sign-off template below.

## Sign-off template

Copy this section into `sign-off.md`.

```markdown
# HDXLURITemplate Production-Readiness Sign-off

## Identity

- Release candidate:
- Commit SHA:
- Proposed version:
- Audit started (UTC):
- Audit completed (UTC):
- Swift version:
- Xcode and SDK build:
- Upstream `uritemplate-test` commit:
- Evidence bundle:
- Audit manifest SHA-256:

## Scope

- [ ] Swift 6.3
- [ ] macOS 26 full test lane
- [ ] All declared Apple OS 26 compile lanes
- [ ] Swift public API
- [ ] Codable
- [ ] Objective-C, or documented removal/limitation
- [ ] RFC 6570 and applicable verified errata
- [ ] Security and privacy
- [ ] Release mechanics
- [ ] Generic production canary and rollback template
- [ ] Adopter-specific plan/results, or explicitly not applicable

## Required gates

- [ ] Fresh, clean checkout verified
- [ ] Debug build and tests passed
- [ ] Release build and tests passed
- [ ] `HEAVY_DEBUG` build and tests passed
- [ ] Every advertised aggregate command passed
- [ ] Every declared OS 26 platform compiled
- [ ] All four current shared fixture suites were executed completely
- [ ] Fixture counts and digests were independently verified
- [ ] RFC and verified-errata requirements matrix is complete
- [ ] Every behavioral defect has a pre-fix-failing regression test
- [ ] Every nonbehavioral ticket has objective, ticket-appropriate pre-change
      evidence
- [ ] Public-only consumer passed
- [ ] Objective-C `.m` consumer passed or support is explicitly absent
- [ ] Codable malformed-input and compatibility checks passed
- [ ] Address Sanitizer passed
- [ ] Thread Sanitizer passed
- [ ] Fuzzing budget completed without unresolved failure
- [ ] Concurrency stress passed
- [ ] Adversarial scaling is linear within the defined gates
- [ ] Representative performance meets predefined budgets
- [ ] Security and privacy review passed
- [ ] License, provenance, and ownership review passed
- [ ] Documentation examples compiled
- [ ] CI required checks were proven to gate merges
- [ ] Clean external consumer resolved and ran
- [ ] Release and rollback procedures were tested

## Finding summary

| Severity | Open | Accepted | Closed |
| --- | ---: | ---: | ---: |
| Blocker |  |  |  |
| High |  |  |  |
| Medium |  |  |  |
| Low |  |  |  |
| Informational |  |  |  |

## Accepted risks

For each accepted Medium or Low finding:

- Finding:
- User impact:
- Why release may proceed:
- Publicly documented limitation:
- Owner:
- Tracking issue:
- Review/expiry date:

## Audit limitations

- [Describe each limitation, or write "None recorded."]

## Canary

- Adopter/system:
- Status: populated / not yet identified / not applicable
- Owner:
- Shadow period:
- Expansion volume:
- Golden mismatches:
- Crashes/hangs/traps:
- Sensitive disclosures:
- Performance result:
- Rollback demonstrated:
- Result or planned completion date:

## Decision

- [ ] GO — suitable for public production-oriented release within the
      documented Swift 6.3 / Apple OS 26+ boundary
- [ ] CONDITIONAL GO — package release may proceed, but the named production
      adopter still requires the documented canary
- [ ] NO-GO — unresolved findings prevent release

Decision rationale:

## Signatures

Maintainer:

- Name:
- Date:
- Decision:
- Signature or approval link:

Independent auditor/reviewer:

- Name:
- Date:
- Decision:
- Signature or approval link:

First production adopter, when applicable:

- Name:
- Date:
- Decision:
- Signature or approval link:
```

## Completion

The audit is complete only when the evidence bundle is durable, the sign-off is
reviewed, and the decision is linked from the release candidate. "All tests
pass" is not, by itself, a production-readiness conclusion.
