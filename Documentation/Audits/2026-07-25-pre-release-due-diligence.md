# Pre-release due-diligence audit

**Project:** HDXLURITemplate\
**Audit date:** 2026-07-25\
**Repository revision audited:** `a20b80ec0b95cb662d26cbdc6578a7aa9d9cfab9`\
**Audit purpose:** Assess whether the package is suitable for a public release and for production use outside toy, hobby, or experimental contexts.

**Program navigation:**
[remediation index](./Production-Readiness-Remediation-Index.md) ·
[post-remediation audit playbook](./Post-Remediation-Production-Readiness-Audit.md) ·
[final-audit issue #44](https://github.com/plx/hdxl-uri-template/issues/44)

## Executive verdict

The package is a good foundation, but it is not yet ready for a stable `1.0`
release or load-bearing workplace use.

The common expansion paths are broadly tested, fast, dependency-free, and
apparently thread-safe. Debug and release tests pass, production-source coverage
is unusually high, sanitizer runs were clean, and deterministic fuzzing did not
find a crash. The implementation is therefore not a rewrite candidate.

Those positive signals do not yet establish RFC conformance or production
readiness. The test harness does not execute the complete shared URI Template
test corpus, its vendored fixtures are stale and one active fixture was modified,
and direct testing against the current upstream corpus found nine failing case
instances. The audit also found:

- Multiple RFC 6570 correctness defects.
- A percent-escape path with confirmed quadratic behavior.
- Publicly reachable Objective-C process traps.
- Codable decoding that can bypass parsing and create invalid public values.
- A heavy-debug configuration that does not compile.
- Incomplete release, documentation, continuous-integration, and third-party
  attribution work.

After the release blockers in this report are fixed, a `0.x` public preview
would be reasonable. A `1.0` release should wait until the serialization,
Objective-C, variable-association, error, and architectural contracts have been
settled deliberately and the
[post-remediation production-readiness audit](./Post-Remediation-Production-Readiness-Audit.md)
has passed.

### Product decisions clarified after the audit

The following are intentional product decisions, not unresolved audit findings:

- The supported Apple platform floor is version 26 for iOS, macOS, tvOS,
  watchOS, visionOS, and Mac Catalyst. The narrow platform matrix is deliberate.
- The package should use Swift tools version 6.3, while continuing to use Swift
  language mode 6.
- Public `Comparable` conformance will be removed from `URITemplate`,
  `URIVariableValue`, and `URIVariableValueType`.
- Serialization remains desirable for convenient persistence of template
  collections. The public `URITemplate.Codable` representation will be a
  validated semantic template string, not the internal parsed object graph. A
  separate opaque,
  versioned compiled-cache format should be considered only if benchmarking
  demonstrates a meaningful benefit.

These decisions supersede the original concern that version-26 platform
minimums were accidentally restrictive.

## Readiness summary

| Area | Assessment |
| --- | --- |
| Common-case correctness | Good; most positive RFC examples pass |
| Complete RFC 6570 conformance | Not established; current shared-suite probing found 9 failing case instances out of 270 |
| Robustness | Sanitizer and fuzz results are strong, but public traps and malformed-input acceptance remain |
| Performance | Fast under representative input; one attacker-amplifiable O(n²) path exists |
| Concurrency | Good evidence; no race was found under TSan or targeted stress |
| API | Small and strongly typed, but serialization, error, association, and Objective-C contracts need work |
| Architecture | Clear layering, but storage and caching are complex for an immutable value |
| Release engineering | Not ready; no build/test CI, sparse documentation, no release history |
| Legal/provenance | Needs third-party notices and confirmation of the private-work ownership chain |

## Priority definitions

- **P0 — release blocker:** Address before any production-oriented preview.
- **P1 — high priority:** Resolve before production evaluation.
- **P2 — medium priority:** Resolve before a stable `1.0` release.
- **P3 — low priority:** Hardening or polish that may follow higher-priority
  work when the native dependency graph permits.

“P0” here means “blocks the intended public release,” not “an already-deployed
production emergency.” These meanings match the semantic labels recorded in
the [remediation index](./Production-Readiness-Remediation-Index.md).

## Scope and methods

The audit was read-only. It did not intentionally modify tracked files.

The audit inspected branch `plx/surat-v2` at the full revision above, using the
GitHub repository `plx/HDXLURITemplate`. The host environment was:

| Property | Value |
| --- | --- |
| Host | Apple silicon (`arm64`) |
| macOS | 27.0 (`26A5378n`) |
| Xcode | 27.0 beta at `/Applications/Xcode-beta.app` (`27A5218g`) |
| Swift | Apple Swift 6.4 (`swiftlang-6.4.0.25.4`) |
| Swift target | `arm64-apple-macosx27.0.0` |

This is an important evidence limitation: the baseline was gathered on a newer
host and compiler than the intended Swift 6.3/macOS 26 release lane. The
results characterize the audited revision in that environment; they do not
substitute for the Swift 6.3 and Apple OS 26 verification required by the
[final audit playbook](./Post-Remediation-Production-Readiness-Audit.md).

The following work was performed:

1. Inspected package metadata, source organization, public APIs, Objective-C
   wrappers, tests, resources, workflows, documentation, licensing, and recent
   history.
2. Built and tested debug and release configurations.
3. Attempted the advertised heavy-debug configuration.
4. Measured source coverage.
5. Ran Address Sanitizer and Thread Sanitizer configurations.
6. Ran a targeted concurrent shared-template stress probe under TSan.
7. Ran a deterministic 200,000-input public-API parsing and evaluation fuzz
   probe.
8. Compared vendored fixtures with the current official
   [`uritemplate-test`](https://github.com/uri-templates/uritemplate-test)
   repository at commit
   [`4171dac`](https://github.com/uri-templates/uritemplate-test/commit/4171dac22aa67fc710b3f6df308a50bd08552986).
9. Exercised all four current shared-suite files directly through the public
   package API.
10. Constructed adversarial probes for parser boundaries, prefix modifiers,
    percent escapes, duplicate associations, Codable invariants, Objective-C
    bridges, and Unicode.
11. Benchmarked representative parsing and expansion and measured scaling of
    suspicious paths.
12. Checked source-formatting and lint output for maintainability signals.

This audit is evidence, not a proof. It did not exercise the library inside a
real application under production traffic, inspect every compiler/SDK
combination, or constitute legal advice.

The durable command-level evidence retained by this report is:

| Check | Command |
| --- | --- |
| Debug tests | `swift test --parallel` |
| Release tests | `swift test -c release` |
| Heavy-debug attempt | `swift test -Xswiftc -DHEAVY_DEBUG` |
| Coverage | `swift test --enable-code-coverage` |
| Address Sanitizer | `swift test --sanitize=address` |
| Thread Sanitizer | `swift test --sanitize=thread` |

The conformance, concurrency, fuzz, trap, and benchmark probes were temporary
audit harnesses rather than checked-in tools, and their raw logs were not
committed. Their aggregate results and minimized reproductions are recorded
below, but the lack of a durable initial evidence bundle limits independent
reproduction. The remediation program and final playbook therefore require
checked-in harnesses, exact invocations, machine-readable output, and preserved
raw artifacts for the release-candidate audit.

## Baseline evidence

### Builds and tests

- `swift test --parallel` passed in debug configuration.
- `swift test -c release` passed.
- Swift Testing's terminal summary was
  `Test run with 108 tests in 0 suites passed`. Two of those tests each expanded
  to 10,001 parameterized cases, producing more than 20,000 progress lines.
- `swift test -Xswiftc -DHEAVY_DEBUG` did not compile; see finding R-14.
- The package emitted a SwiftPM warning for the unhandled
  `Tests/HDXLURITemplateTests/Resources/spec-examples-original.json` file.

### Production-source coverage

Coverage was measured with `swift test --enable-code-coverage`.

| Metric | Covered | Total | Percentage |
| --- | ---: | ---: | ---: |
| Lines | 2,832 | 2,843 | 99.613% |
| Functions | 374 | 376 | 99.468% |
| Regions | 994 | 1,000 | 99.400% |

This is excellent execution coverage. It is not equivalent to specification
coverage: the omitted negative and by-section suites demonstrate that almost
every line can execute while whole behavioral categories remain unverified.

### Sanitizers, concurrency, and fuzzing

- Full test runs passed with Address Sanitizer.
- Full test runs passed with Thread Sanitizer.
- A targeted TSan probe performed 100,000 concurrent evaluations, metadata
  reads, and hashes against a shared template without finding a race or result
  mismatch.
- A deterministic public-API fuzz probe generated 200,000 random template
  strings. It reached 21,306 successful parse/evaluation paths without a crash.
- Regex near-misses and large list/association expansions scaled linearly in the
  sampled ranges.

These are meaningful strengths. They do not cover the separately reproduced
Objective-C traps, which are deterministic preconditions/invariant failures
rather than memory races.

### Representative performance

Using a prebuilt release configuration on the audit machine:

| Operation | Iterations | Approximate latency | Approximate throughput |
| --- | ---: | ---: | ---: |
| Parse representative templates | 10,000 | 4.48 μs/op | 223,000 ops/s |
| Expand representative templates | 100,000 | 4.31 μs/op | 232,000 ops/s |

Normal-case performance is already good. In particular, a typical application
would spend roughly 4.5 ms parsing 1,000 templates on this machine. That
measurement weakens the performance justification for persisting the internal
AST and motivates benchmarking before introducing a compiled-cache format.

## Shared specification corpus analysis

The upstream shared test repository describes four suites and states that
`spec-examples.json` and `spec-examples-by-section.json` only partially overlap;
both must be run to cover every RFC example. It also uses `false` expectations
for templates/expansions that are expected to fail.

The package's active conformance list in
`Tests/HDXLURITemplateTests/Specification/Support/TemplateVerification.swift:10-17`
contains only:

```swift
[
  "spec-examples",
  "extended-tests"
]
```

`SpecificationParsingTests.swift:4-14` merely JSON-decodes three resource files.
It does not execute the by-section examples, and it does not even smoke-decode
`negative-tests.json`. The active negative suite is therefore never exercised.

### Fixture and result counts

| Suite | Local cases | Current upstream cases | Current expected behaviors passed |
| --- | ---: | ---: | ---: |
| `spec-examples.json` | 63 | 64 | 63/64 |
| `spec-examples-by-section.json` | 117 | 117 | 116/117 |
| `extended-tests.json` | 42 | 53 | 52/53 |
| `negative-tests.json` | 29 | 36 | 30/36 |
| **Combined case instances** | — | **270** | **261/270** |

The two RFC-example suites overlap, so `261/270` must not be presented as a
conformance percentage. It is a count of case instances and evidence of several
distinct defects.

The current upstream additions include multibyte prefix cases, Unicode literal
encoding, and malformed modifier/name cases. The active local
`spec-examples.json` also omits the upstream apostrophe example while the
unhandled `spec-examples-original.json` retains it. Git history shows that the
active example was deleted rather than handled. Apostrophe support is required
by [verified RFC erratum 6937](https://www.rfc-editor.org/errata/eid6937), so this
is not merely a test-suite compatibility preference.

## Detailed findings

### R-01 — Execute and pin the complete shared conformance corpus

**Priority:** P0\
**Domains:** specification, testing, release engineering\
**Primary locations:**

- `Tests/HDXLURITemplateTests/Specification/Support/TemplateVerification.swift:4-17`
- `Tests/HDXLURITemplateTests/Specification/SpecificationParsingTests.swift:4-14`
- `Tests/HDXLURITemplateTests/Specification/SpecificationTests.swift:31-65`
- `Tests/HDXLURITemplateTests/Resources/*.json`
- `Package.swift:35-48`

**Issue**

Only `spec-examples` and `extended-tests` are executed. The by-section suite is
decoded but not evaluated, the negative suite is not loaded by any test, and
the vendored files are not pinned to a documented upstream revision. One active
fixture was modified to remove a failing apostrophe case.

The existing harness cannot be repaired by simply adding the negative file:
`verifyTemplateParsing` requires every case to parse, and
`verifyTemplateExpansion` parses before examining `.evaluationFailure`. A
negative case that is supposed to fail parsing would therefore fail the harness
rather than satisfy the expectation.

**Impact**

The green suite creates false confidence in RFC coverage and allowed multiple
known failures to remain hidden. Fixture changes can silently alter the claimed
contract.

**Required outcome**

- Pin an upstream `uritemplate-test` commit in documentation or machine-readable
  metadata.
- Vendor all four unmodified files with source, commit, and license provenance.
- Execute both positive RFC-example files and `extended-tests`.
- Create a dedicated negative harness that accepts either parse failure or the
  explicitly expected expansion failure, according to the fixture's semantics.
- Add exact case/group-count assertions so stale or accidentally edited
  resources fail loudly.
- Remove or properly declare `spec-examples-original.json`; do not keep an
  ambiguous shadow fixture.

**Validation**

- Tests added for this work must fail against the audited revision because the
  by-section and negative suites are not currently executed.
- Temporarily deleting a case or group from each fixture must trip a count or
  provenance assertion.
- The unmodified upstream corpus at the pinned commit must run through the
  public API.
- SwiftPM must emit no unhandled-resource warning.

### R-02 — Correct the RFC literal grammar, including `~` and apostrophe

**Priority:** P0\
**Domains:** parsing, RFC conformance\
**Primary locations:**

- `Sources/HDXLURITemplate/Detail/TemplateComponent/URITemplateLiteralComponent.swift:139-148`
- `Sources/HDXLURITemplate/Detail/Parsing/URITemplateLiteralComponent+Parsing.swift`
- `Tests/HDXLURITemplateTests/Resources/spec-examples.json`

**Issue**

The literal singleton set contains `\u0073` where it should contain `\u007E`.
Lowercase `s` is already covered by the lowercase range, so the typo removes
valid literal `~`. Apostrophes are also rejected despite verified RFC erratum
6937.

**Reproduction**

The following valid templates fail to parse:

```text
https://example.com/~user
http://example.org/'{var}'
```

The latter is an official shared-suite example.

**Impact**

Valid RFC templates are rejected, including ordinary home-directory-style URI
paths.

**Required outcome**

Implement the corrected literal grammar from RFC 6570 plus verified errata.
Prefer deriving character tables from auditable named constants or exhaustive
tests instead of maintaining visually similar scalar literals without boundary
coverage.

**Validation**

- Add public-API parse-and-expand tests for both examples above; they must fail
  before the fix.
- Add table-driven tests at every literal-range boundary, including characters
  immediately below and above each accepted range.
- Execute the restored upstream apostrophe example unmodified.
- Assert that invalid expression delimiters and forbidden whitespace remain
  rejected.

### R-03 — Percent-encode non-URI Unicode in template literals

**Priority:** P0\
**Domains:** expansion, Unicode, RFC conformance\
**Primary location:**

- `Sources/HDXLURITemplate/URITemplate+Evaluation.swift:51-58`

**Issue**

Literal components are appended using `literal.rawValue`. RFC 6570 requires
non-URI literal characters to be encoded as UTF-8 and then percent-encoded,
while valid literal characters and valid existing percent triplets remain
intact.

**Reproduction**

```text
Template: café/{var}
Value:    var = "value"
Observed: café/value
Expected: caf%C3%A9/value
```

This behavior is covered by the current upstream
[`literal-encoding` addition](https://github.com/uri-templates/uritemplate-test/commit/4171dac22aa67fc710b3f6df308a50bd08552986).

**Impact**

The package can emit URI-reference strings containing raw non-URI characters
and disagree with conforming implementations.

**Required outcome**

Add a dedicated literal-expansion/normalization path that:

- Preserves allowed literal characters.
- Preserves valid percent-encoded triplets.
- Encodes other literal Unicode through UTF-8 bytes using uppercase hex.
- Does not apply variable-expansion reserved-character rules to literals.

**Validation**

- Add a failing-before-fix test for `café/{var}`.
- Cover composed and decomposed Unicode, BMP and non-BMP scalars, and multiple
  adjacent non-ASCII characters.
- Cover valid `%20`, mixed-case triplets, malformed `%` sequences, and literal
  reserved/unreserved boundaries.
- Run the current upstream literal-encoding group unchanged.

Reference: [RFC 6570 §§2.1 and 3.1](https://www.rfc-editor.org/rfc/rfc6570.html#section-3.1).

### R-04 — Correct the reserved/sub-delimiter character set

**Priority:** P0\
**Domains:** expansion, encoding, RFC conformance\
**Primary location:**

- `Sources/HDXLURITemplate/Detail/ValueExpansion/CharacterSet+URIValueExpansion.swift:145-149`

**Issue**

The sub-delimiter set uses `"!$^'()"`. It should include `&`, not `^`. As a
result, reserved and fragment expansion percent-encode a legal reserved
delimiter and preserve an illegal character.

**Reproduction**

```text
Template: {+x}
Value:    x = "a&b^c"
Observed: a%26b^c
Expected: a&b%5Ec
```

**Impact**

Reserved and fragment expansions can change URI semantics and produce output
that is not correctly encoded.

**Required outcome**

Define the reserved set exactly as RFC 3986:

```text
gen-delims = ":" / "/" / "?" / "#" / "[" / "]" / "@"
sub-delims = "!" / "$" / "&" / "'" / "(" / ")" /
             "*" / "+" / "," / ";" / "="
```

Prefer exhaustive membership tests for every ASCII scalar over a handful of
examples.

**Validation**

- Add the reproduction as a test that fails before the fix.
- For simple, reserved, fragment, label, path, parameter, query, and
  continuation operators, test all ASCII bytes and compare the preserved versus
  encoded set with the RFC table.
- Test valid percent triplets and non-ASCII input independently.

Reference: [RFC 3986 §2.2](https://www.rfc-editor.org/rfc/rfc3986.html#section-2.2).

### R-05 — Reject whitespace and empty entries in expression variable lists

**Priority:** P0\
**Domains:** parsing, validation, RFC conformance\
**Primary locations:**

- `Sources/HDXLURITemplate/Detail/Parsing/URITemplateExpressionComponent+Parsing.swift:20-26`
- `Sources/HDXLURITemplate/Detail/TemplateComponent/URITemplateExpressionComponent.swift:128-134`

**Issue**

Parsing splits comma-separated variables while omitting empty subsequences and
trims whitespace. This accepts invalid syntax and silently changes it into
another template. The canonical/template representation then inserts a
comma-space sequence that is itself outside the RFC expression grammar.

**Reproduction**

```text
Input       Current representation
{x,}        {x}
{,x}        {x}
{x,,y}      {x, y}
{x, y}      {x, y}
```

**Impact**

Typos and invalid templates are silently accepted. Round-tripping can produce
text that a strict RFC parser must reject.

**Required outcome**

- Parse expression variable lists without dropping empty subsequences.
- Reject all expression whitespace and missing members.
- Reject empty expressions.
- Emit a valid canonical representation such as `{x,y}`, or preserve the exact
  validated original source.
- Do not use normalization to make invalid input appear valid.

**Validation**

- Add parse-rejection tests for every example above, plus `{}`, `{,}`, `{x,,}`,
  and each ASCII whitespace scalar.
- Those tests must fail before the fix.
- Assert that `template.templateRepresentation` always reparses successfully
  under the strict public parser.
- Add a property test that parse → representation → parse preserves equality
  and expansion behavior for valid generated templates.

### R-06 — Enforce the prefix-modifier ABNF exactly

**Priority:** P0\
**Domains:** parsing, modifiers, RFC conformance\
**Primary location:**

- `Sources/HDXLURITemplate/Detail/Parsing/URIValueExpansionModifier+Parsing.swift:15-29`

**Issue**

The modifier parser delegates numeric syntax to `Int`. That accepts spellings
which are not in the RFC grammar and canonicalizes them silently.

**Reproduction**

```text
Input       Current representation
{x:01}      {x:1}
{x:0001}    {x:1}
{x:+1}      {x:1}
```

RFC 6570 permits a first digit in `1...9`, followed by zero to three decimal
digits: values `1...9999`, with no sign and no leading zero.

**Impact**

Invalid templates pass validation, including a current upstream negative case.

**Required outcome**

Validate the source spelling against the modifier ABNF before numeric
conversion. Reject zero, leading zeroes, signs, empty suffixes, non-ASCII
digits, and values longer than four digits.

**Validation**

- Add failing-before-fix rejection tests for `:0`, `:00`, `:01`, `:+1`, `:-1`,
  `:`, `:10000`, non-ASCII digits, and trailing junk.
- Accept and verify the boundary values `:1`, `:9`, `:10`, and `:9999`.
- Exhaustive iteration from `1...9999` may remain in a single test body to avoid
  creating 10,000 separately reported test arguments.

### R-07 — Fail expansion when a prefix modifier is applied to a composite

**Priority:** P0\
**Domains:** expansion, modifiers, values, RFC conformance\
**Primary locations:**

- `Sources/HDXLURITemplate/Detail/ValueExpansion/URIVariableListValue+ValueExpansion.swift:41-57`
- `Sources/HDXLURITemplate/Detail/ValueExpansion/URIVariableAssociationValue+ValueExpansion.swift:41-57`

**Issue**

Prefix modifiers are not applicable to lists or associations. The current
`.prefix` branches treat those values like ordinary unexploded composite
expansions and return successful output.

**Reproduction**

With an association such as `["a": "b"]`, the official negative cases
`{keys:1}` and `{+keys:1}` succeed instead of producing an evaluation failure.

**Impact**

The package violates modifier semantics and fails two shared negative cases.

**Required outcome**

Return a structured expansion error whenever a prefix modifier is applied to a
list or association. Ensure the public boundary wraps that error predictably in
`URITemplate.EvaluationError`.

**Validation**

- Add public-API list and association tests for every operator combined with a
  prefix modifier; they must fail before the fix.
- Verify ordinary unmodified and exploded composite behavior is unchanged.
- Execute the relevant upstream negative cases.

### R-08 — Do not split pre-percent-encoded characters during prefix expansion

**Priority:** P0\
**Domains:** expansion, Unicode, modifiers\
**Primary locations:**

- `Sources/HDXLURITemplate/Detail/ValueExpansion/URIVariableTextValue+ValueExpansion.swift:99-114`
- `Sources/HDXLURITemplate/Detail/Support/String+URITemplateLengthManipulations.swift:23`

**Issue**

Prefix processing truncates the raw Swift Unicode-scalar sequence before
recognizing percent-encoded units. A prefix can therefore end inside a percent
triplet or a multioctet percent-encoded character.

**Reproduction**

```text
Template: {+x:1}
Value:    x = "%C3%A9"
Observed: %25
```

The prefix represents one decoded Unicode code point and must not split `%C3%A9`.
Actual Swift strings such as `α`, `€`, and `𝄞` behaved correctly; the defect is
specific to pre-percent-encoded input.

**Impact**

Valid pre-encoded values can be corrupted during prefix expansion.

**Required outcome**

Count logical decoded Unicode code points while preserving valid percent
triplets and UTF-8 sequences. Define and test behavior for malformed triplets
without accidentally double-encoding valid input.

**Validation**

- Add failing-before-fix tests for one-, two-, three-, and four-byte encoded
  scalars at every prefix boundary.
- Include mixed literal ASCII, raw Unicode, and encoded Unicode.
- Include malformed and truncated percent sequences.
- Run the upstream multibyte-prefix examples unmodified.

### R-09 — Replace the percent scanner's quadratic algorithm

**Priority:** P0\
**Domains:** performance, security, expansion\
**Primary location:**

- `Sources/HDXLURITemplate/Detail/ValueExpansion/String+URIValueExpansion.swift:10-19`

**Issue**

`hasPercentEscape(at:)` computes the distance from each candidate percent sign
to the string's end. Distance over a Swift string/scalar collection is linear.
Repeating it for each percent triplet makes percent-dense reserved/fragment
values O(n²), in addition to small per-triplet allocations.

**Measured reproduction**

Release expansion of `{+x}` with repeated `%20`:

| Triplets | Input size | Time |
| ---: | ---: | ---: |
| 10,000 | 30 KB | 0.162 s |
| 20,000 | 60 KB | 0.591 s |
| 40,000 | 120 KB | 2.406 s |
| 80,000 | 240 KB | 10.502 s |
| 100,000 | 300 KB | 15.981 s |

The roughly fourfold runtime for each doubling demonstrates quadratic growth.

**Impact**

An attacker who can control a variable value can consume seconds of CPU with a
few hundred kilobytes of input. This is a denial-of-service risk in servers,
proxies, and batch processors.

**Required outcome**

Implement a single-pass scalar/byte state machine with constant bounded
lookahead and direct result construction. Preserve the finalized, RFC-correct
encoding semantics established by the conformance fixes, including valid
percent triplets, while avoiding repeated end-distance calculations and
temporary arrays.

**Validation**

- Add a correctness corpus for valid, invalid, adjacent, mixed-case, and
  truncated escapes.
- Add a release benchmark or performance regression check over geometrically
  increasing sizes.
- The 2× input-size ratio should remain near linear and must not approach 4×
  over repeated samples.
- Measure allocation count or bytes if tooling permits.
- Re-run ASan, TSan, and the fuzz probe after replacement.

### R-10 — Establish and enforce duplicate-association semantics without traps

**Priority:** P0\
**Domains:** values, invariants, Objective-C, robustness, Codable\
**Primary locations:**

- `Sources/HDXLURITemplate/URIVariableValue.swift:98-103`
- `Sources/HDXLURITemplate/Detail/VariableValue/URIVariableAssociationValue.swift:139-153`
- `Sources/HDXLURITemplate/ObjC/HDXLURIVariableValue.swift:105-117`
- `Sources/HDXLURITemplate/ObjC/HDXLURIVariableValue.swift:180-187`

**Issue**

The public Swift association constructor accepts duplicate keys, while the
internal validity predicate requires unique keys. Normal builds do not enforce
the invariant. The Objective-C dictionary view then calls
`Dictionary(uniqueKeysWithValues:)`, which traps on duplicates. The Objective-C
parallel-array initializer separately uses a public-input `precondition` when
the array counts differ.

Both process-termination paths were reproduced in a release build.

**Impact**

A value constructible through the public API may fail its own Codable
round-trip or terminate a client process when bridged. Public input must not be
able to trigger a trap.

**Required outcome**

Choose and document one association policy:

- Reject duplicates through a throwing/failable constructor.
- Resolve duplicates deterministically using a documented first- or last-value
  policy.
- Or genuinely support ordered duplicate pairs and remove the uniqueness
  invariant and dictionary-only assumptions.

Apply the same policy to Swift constructors, Objective-C constructors, Codable,
secure coding, expansion, equality, hashing, and inspection. Replace count
preconditions with a safe failable/throwing Objective-C API or another
nontrapping documented behavior.

**Validation**

- Add tests that construct duplicate pairs through every public entry point.
  At least the dictionary-access test must fail or crash before the fix and pass
  safely afterward.
- Add unequal parallel-array count tests through an actual Objective-C caller.
- Add encode/decode round-trip tests for all constructible association values.
- Run the scenarios in release as well as debug configuration.

### R-11 — Replace synthesized AST Codable with validated semantic coding

**Priority:** P0\
**Domains:** API, persistence, validation, compatibility\
**Primary locations:**

- `Sources/HDXLURITemplate/URITemplate.swift:69-78`
- `Sources/HDXLURITemplate/Detail/Template/URITemplateStorage.swift:310-328`
- `Sources/HDXLURITemplate/Detail/TemplateComponent/URITemplateExpressionComponent.swift:147-152`

**Issue**

`URITemplate` synthesizes Codable through the internal storage graph. Encoded
JSON exposes implementation keys, associated-value shapes, and numeric enum
representations. Decoding constructs internals directly rather than invoking
the parser.

A crafted public JSON payload can decode an expression with an empty variable
array. The `allSatisfy` validity check accepts that empty array vacuously,
yielding a supposedly valid template whose representation is `{}`. Deep
component coding can also create representations that the public parser could
never produce.

**Impact**

- Invalid state can enter through a public conformance.
- Private implementation structure becomes a de facto persistence contract.
- Parser corrections can be bypassed by old archives.
- Internal refactoring risks breaking user data.
- Synthesized coding is not demonstrated to be faster than reparsing.

**Product intent**

Serialization is desirable primarily to persist collections of parsed
templates between sessions, potentially avoiding repeated parsing. It is not
intended as a cross-machine transport format. Swift has no conformance that
expresses “Codable but local and disposable,” however, so ordinary `Codable`
still creates reasonable expectations of stable semantic persistence.

**Required outcome**

Keep `Codable`, but implement it as a single validated template string:

1. Encode an exact validated source string, or a guaranteed-valid and stable
   canonical template representation.
2. Decode by calling the public parser.
3. Reject any decoded string that the current implementation considers invalid.
4. Document this semantic representation and its compatibility expectations.

Benchmark source-string parsing against JSON and binary-property-list decoding
of both the string and existing AST before claiming a cache benefit.

If a compiled representation produces a meaningful measured startup win,
introduce a separate opaque and explicitly disposable cache API. It should
contain:

- A cache-format version.
- The authoritative source template.
- A compiled payload.
- Validation that source and payload correspond.
- Automatic fallback to reparsing when the version or payload is invalid.

The compiled cache must never be the sole durable copy and must not reuse the
public semantic `Codable` contract.

**Validation**

- Add a test that the crafted empty-expression payload no longer decodes.
- Add parse → encode → decode → equality/expansion tests for the complete shared
  corpus.
- Add malformed, stale, unknown-key, and invalid-template decoding tests.
- Assert the encoded form contains only the semantic string contract, not AST
  type or enum details.
- Record repeatable benchmarks before deciding whether to add a compiled cache.

### R-12 — Implement `LocalizedError` correctly and make errors actionable

**Priority:** P1\
**Domains:** API, diagnostics, Objective-C\
**Primary locations:**

- `Sources/HDXLURITemplate/URITemplateParseError.swift:9-23`
- `Sources/HDXLURITemplate/URITemplate+Evaluation.swift:5-38`

**Issue**

Both public errors implement `localizedDescription`, not
`LocalizedError.errorDescription`. When caught as `Error` or bridged to
`NSError`, callers receive the generic “The operation couldn’t be completed”
message. Existing tests call the concrete property and therefore miss the
protocol behavior.

The parse error also lacks a stable category and source offset, making
diagnostics difficult to present or act upon.

**Required outcome**

- Implement `errorDescription` and, where useful, `failureReason` and
  `recoverySuggestion`.
- Preserve an inspectable underlying error without making private types part of
  the public contract.
- Add a stable public parse category and source location/range if feasible.
- Ensure Objective-C receives useful `NSError` domain, code, and user-info.

**Validation**

- Add tests that erase each concrete error to `any Error`, bridge it to
  `NSError`, and verify useful descriptions.
- Add exact offset tests for representative syntax errors if location becomes
  public.
- Verify descriptions remain bounded and do not reveal parameter values; see
  R-13.

### R-13 — Do not disclose complete parameter values in default diagnostics

**Priority:** P1\
**Domains:** security, API, diagnostics\
**Primary locations:**

- `Sources/HDXLURITemplate/URITemplate+Evaluation.swift:5-36`
- `Sources/HDXLURITemplate/URITemplate+Evaluation.swift:100-108`
- Variable-value `errorMessageRepresentation` implementations

**Issue**

`EvaluationError` stores the complete parameter dictionary and interpolates its
raw values into a default diagnostic. Applications commonly expand API keys,
tokens, account identifiers, paths, and user data. Logging the error can
therefore disclose secrets.

**Impact**

Unexpected expansion failures can turn normal diagnostic logging into a data
leak.

**Required outcome**

- Keep enough structured context to diagnose which variable failed.
- Redact values by default.
- Bound template/value lengths in descriptions.
- If full diagnostics are useful, make them an explicit opt-in API with clear
  sensitivity documentation.
- Review `debugDescription`, Objective-C descriptions, and nested underlying
  errors for the same concern.

**Validation**

- Add a sentinel-secret test and assert the sentinel is absent from
  `String(describing:)`, `localizedDescription`, `NSError`, and default debug
  output.
- Verify variable names and failure categories remain available.

### R-14 — Restore and continuously test the heavy-debug configuration

**Priority:** P1\
**Domains:** build, assertions, CI\
**Primary locations:**

- `justfile:9-15`
- `Sources/HDXLURITemplate/Detail/TemplateComponent/URITemplateLiteralComponent.swift:22-23`
- `Sources/HDXLURITemplate/Detail/Variable/URITemplateVariableName.swift:23`

**Issue**

The advertised `just build-all` target fails in `build-heavy-debug`.
Heavy-debug assertion code refers to a nonexistent `storage` property in types
that expose `rawValue`.

**Impact**

The configuration intended to check invariants is unbuildable and therefore
cannot provide the protection it advertises. Assertion-only code has drifted
outside normal compiler coverage.

**Required outcome**

Correct the stale references and add heavy-debug build and test coverage to CI.
Review all `#if HEAVY_DEBUG` blocks for additional uncompiled drift.

**Validation**

- `just build-all` and a new heavy-debug test recipe must pass from a clean
  checkout.
- CI must compile this branch on every pull request.
- Add at least one controlled test proving that heavy-debug invariant checks are
  actually compiled and exercised.

### R-15 — Finish or deliberately remove the Objective-C support contract

**Priority:** P1\
**Domains:** Objective-C, API, testing\
**Primary locations:**

- `Sources/HDXLURITemplate/ObjC/HDXLURITemplate.swift:8-14`
- `Sources/HDXLURITemplate/ObjC/HDXLURITemplate.swift:53-85`
- `Sources/HDXLURITemplate/ObjC/HDXLURIVariableValue.swift`
- `Tests/HDXLURITemplateTests/DoubleCoverage/ObjCDoubleCoverageTests.swift`

**Issue**

The wrapper states that it makes package functionality accessible to
Objective-C, but it exposes parsing and inspection without template evaluation.
Parsing discards error information through a simple failable initializer.
Objective-C coverage is written in Swift, so it does not prove that the
generated interface is usable from a `.m` consumer. The public-input traps in
R-10 further weaken the bridge.

**Required outcome**

Choose one:

- Complete Objective-C support with parsing and expansion APIs, `NSError **`
  failure reporting, safe value construction, secure coding, documentation, and
  a real Objective-C consumer target.
- Or remove the wrappers from the initial supported contract and document the
  package as Swift-only.

Do not leave a partially functional, apparently supported surface.

**Validation**

- Compile and run a `.m` fixture importing the built module.
- Exercise every public Objective-C initializer, property, coding path, parse
  failure, and expansion operator.
- Confirm no caller-controlled input can invoke `precondition`, `fatalError`, or
  a trapping Foundation constructor.

### R-16 — Remove public `Comparable` and review value-inspection ergonomics

**Priority:** P1\
**Domains:** API design\
**Primary locations:**

- `Sources/HDXLURITemplate/URITemplate.swift:74-88`
- `Sources/HDXLURITemplate/URIVariableValue.swift:22-23`
- `Sources/HDXLURITemplate/URIVariableValue.swift:124-142`
- Internal component/storage `Comparable` implementations

**Issue**

There is no clear semantic ordering for URI templates. Current storage equality
uses component structure while ordering is derived from textual
representation; crafted decoded component arrays can therefore produce unequal
values for which neither value is less than the other. The useful public
contract is equality/hashability, not arbitrary sorting.

`URIVariableValue` similarly documents structural ordering by case and payload.
That may be surprising and appears to exist primarily because internal wrapper
types conform.

The public variable-value API is also intentionally write-mostly. That keeps
internal newtypes private, but decoded values and application configuration are
awkward to inspect.

**Product decision**

Public `Comparable` will be removed from `URITemplate`, `URIVariableValue`, and
`URIVariableValueType`.

**Required outcome**

- Remove `Comparable` from `URITemplate`.
- Remove `Comparable` from `URIVariableValue`.
- Remove `Comparable` from `URIVariableValueType`.
- Remove now-unnecessary internal comparison code where it serves no other
  purpose.
- Consider public payload accessors, a safe visitor, or an enum-like projection
  for inspecting text/list/association values without exposing internal
  newtypes.
- Review whether public `DataValidationError<T>` remains necessary after
  semantic decoding and invariant fixes.

**Validation**

- Ensure the public API compiles without comparison operators and tests do not
  depend on incidental ordering.
- Add public-only consumer tests for whatever value-inspection API remains.
- Treat the removal as a deliberate pre-1.0 source change in release notes.

### R-17 — Simplify immutable template storage and justify ABI-visible internals

**Priority:** P1\
**Domains:** architecture, concurrency, performance, maintainability\
**Primary locations:**

- `Sources/HDXLURITemplate/URITemplate.swift:7-34`
- `Sources/HDXLURITemplate/Detail/Template/URITemplateStorage.swift:9-38`
- `Sources/HDXLURITemplate/Detail/Template/URITemplateStorage.swift:154-214`
- Widespread `@inlinable` and `@usableFromInline` declarations

**Issue**

The public value is immutable, but it wraps a mutable reference storage with
lazy caches, a lock, COW-oriented commentary, and `@unchecked Sendable`.
Production has no public mutator; the mutable/COW path exists primarily for
tests. The result is substantial complexity and lock contention for metadata
that could be computed once during parsing.

No race was found. This is a maintainability and avoidable-contention concern,
not evidence of a current data race.

Eight million warm metadata reads measured approximately 0.127 seconds
sequentially and 1.134 seconds split across eight workers, indicating contention
on already-computed cache reads.

The extensive use of `@inlinable`/`@usableFromInline` also exposes internal
implementation details to client binaries and constrains future refactoring
without a demonstrated benchmark need.

**Required outcome**

- Prototype an immutable storage representation that computes components,
  source/canonical text, and variable names during parsing.
- Compare code size, parse cost, copy cost, evaluation cost, concurrent metadata
  access, and implementation complexity against the current design.
- Prefer compiler-checked `Sendable` over `@unchecked Sendable`.
- Retain lazy locking or COW only where a benchmark demonstrates a material
  benefit.
- Audit each public `@inlinable` declaration; keep it only when measurement
  justifies exposing the referenced internals.

**Validation**

- Preserve the full behavioral and Codable test suite.
- Repeat TSan and the 100,000-operation shared-template stress probe.
- Add before/after benchmarks for parsing, copying, metadata access, and
  expansion.
- Document the chosen tradeoff in an architecture note.

### R-18 — Establish a compact but real build, consumer, and quality CI gate

**Priority:** P1\
**Domains:** CI, packaging, toolchain\
**Primary locations:**

- `Package.swift:1-53`
- `justfile`
- `.github/workflows/claude-code-review.yml`
- `.github/workflows/claude.yml`

**Issue**

The repository has AI-assistance workflows but no workflow that builds or tests
the package. There is no public-only consumer target, actual Objective-C
consumer, sanitizer gate, formatting configuration, or performance-regression
signal. Existing tests consistently use `@testable import`, which can hide
problems in the exported API.

The package currently declares Swift tools 6.2. The intended minimum is 6.3.
All Apple platform minimums at version 26 are intentional and should not be
expanded merely to create a larger compatibility matrix.

Third-party actions are referenced by mutable major tags rather than commit
SHAs. The review workflow grants read-only pull-request permission while its
prompt asks the action to post a PR comment.

**Required outcome**

- Change `// swift-tools-version` to 6.3.
- Document version-26 Apple-only support explicitly.
- Add a compact primary CI lane using the intended Swift 6.3/macOS 26
  environment for debug, release, heavy-debug, and tests.
- Add a consumer fixture that imports the module without `@testable`.
- If Objective-C remains supported, add a genuine `.m` compile/run fixture.
- Add ASan/TSan and performance/fuzz jobs at a cadence proportionate to cost;
  they need not all run on every pull request.
- Add representative compile smoke checks for the documented Apple platforms
  at release time or on a scheduled cadence rather than maintaining an
  unnecessarily large per-PR matrix.
- Pin external actions by full commit SHA and grant only the permissions their
  exercised behavior actually requires.
- Adopt a formatter configuration and a deterministic lint/format gate after
  applying a dedicated mechanical-formatting change.

**Validation**

- A clean pull request must be blocked by failing build/test gates.
- Introduce controlled failures in public import, heavy-debug, release, and
  formatting to verify each gate.
- Package documentation and manifest must agree on Swift 6.3 and Apple OS 26+.

### R-19 — Provide release-grade documentation and an explicit security model

**Priority:** P1\
**Domains:** documentation, security, release management\
**Primary locations:**

- `README.md:1-3`
- Public declarations under `Sources/HDXLURITemplate`

**Issue**

The README contains only the project title and a one-line origin statement.
There is no installation example, expansion example, platform/toolchain table,
conformance statement, security guidance, API overview, contribution guide,
security policy, changelog, semantic-versioning policy, DocC catalog, or release
history. There are no version tags.

URI Template reserved and fragment expansion intentionally preserves
delimiters. Untrusted templates or values can therefore alter URI structure or
produce dangerous schemes such as `javascript:`. The library need not impose a
scheme policy, but consumers must understand that expansion is not URL
authorization or destination validation.

**Required outcome**

- Add a useful README with installation, Swift and Objective-C status, OS 26+
  and Swift 6.3 requirements, parsing, expansion, value types, error handling,
  RFC-conformance scope, and links to detailed documentation.
- Explain the distinction between `evaluateAsString` and Foundation `URL`
  construction.
- Add a security section covering untrusted templates, reserved/fragment
  expansion, scheme/host/destination validation, resource limits, and sensitive
  diagnostics.
- Add DocC for the supported public API, runnable examples, a contribution
  guide, a security-reporting policy, and changelog/release process.
- Publish an initial `0.x` release before promising API stability.

**Validation**

- Verify every README/DocC example in a compile-and-run documentation test.
- Have a new consumer follow only the public documentation to parse and expand
  all four value kinds.
- Review security guidance against
  [RFC 6570 §4](https://www.rfc-editor.org/rfc/rfc6570.html#section-4).

### R-20 — Add third-party attribution and confirm publication provenance

**Priority:** P1\
**Domains:** licensing, provenance, release management\
**Primary locations:**

- `LICENSE`
- `Tests/HDXLURITemplateTests/Resources/*.json`
- RFC-derived grammar, tables, and code comments under `Sources`

**Issue**

The repository ships only an MIT license. The vendored official test fixtures
come from an Apache-2.0 repository and lack an adjacent notice identifying their
source, commit, and license. RFC 6570's legal notice also applies Simplified BSD
terms to extracted Code Components. The source was recreated from earlier
private work, so publication should have a documented ownership/employer
clearance decision.

**Required outcome**

- Add `THIRD_PARTY_NOTICES` or equivalent with the exact
  `uritemplate-test` source, pinned commit, copyright, and Apache-2.0 license.
- Inspect copied/adapted RFC ABNF, tables, and code components and include the
  required Simplified BSD notice where applicable.
- Document fixture-update procedure and provenance.
- Confirm that the author has the right to publish the recreated private work,
  including any relevant prior-employer policy. Obtain legal advice if
  necessary.

**Validation**

- A release-source archive must contain all required notices.
- Each vendored fixture must be traceable byte-for-byte to its declared upstream
  revision unless an explicit, reviewed patch and rationale is recorded.
- Run a lightweight release-license checklist before tagging.

This section is a diligence recommendation and not legal advice.

### R-21 — Reduce test noise and clean up low-level maintainability issues

**Priority:** P2\
**Domains:** tests, maintainability, source quality\
**Primary locations:**

- `Tests/HDXLURITemplateTests/Detail/ValueExpansion/URIValueExpansionModifierTests.swift`
- `Sources/HDXLURITemplate/Detail/ValueExpansion/CharacterSet+URIValueExpansion.swift:170-174`
- Formatting across `Sources` and `Tests`

**Issue**

Parameterized testing of all 10,001 prefix values produces roughly 20,000 lines
of ordinary test output. This obscures useful CI failures. `swift-format lint`
also reports extensive whitespace/style and missing-public-documentation
warnings, with no repository configuration to make the intended style clear.

An apparently unused RFC `ucschar` character table contains `0xF900...0xFDFC`;
the RFC endpoint is `0xFDCF`. The active literal regex uses the correct value,
so this appears to be low-risk dead/test-support code rather than a demonstrated
production defect.

**Required outcome**

- Keep exhaustive modifier checking inside a small number of test bodies and
  expose representative boundary/equivalence classes as separate parameterized
  cases.
- Add a formatter configuration, apply formatting in a dedicated change, and
  make future drift deterministic.
- Correct or remove unused RFC tables and add exact boundary membership tests
  for any table retained.
- Remove stale comments and unused internal error/support types during focused
  cleanup, without combining that work with semantic fixes.

**Validation**

- Normal CI output should be concise while preserving exhaustive checks.
- Formatting/lint should pass from a clean checkout.
- Boundary tests must prove every retained RFC range exactly.

## API and architectural assessment

### Strengths worth preserving

- The package separates parsing from repeated evaluation.
- Undefined, text, list, and ordered association values are explicitly modeled.
- The public Swift template API is immutable.
- Ordered associations make expansion deterministic.
- String expansion is available independently from Foundation `URL`
  construction.
- There are no third-party runtime dependencies.
- The source is decomposed into parsing, component, variable, and expansion
  layers rather than being a single opaque parser.
- Common-case parsing and expansion are fast.
- Execution coverage, sanitizer results, deterministic fuzzing, and targeted
  concurrency results are all strong for a personal project.

Those strengths should remain visible while simplifying internals; resolving
the findings does not require replacing the package wholesale.

### Codable and cache semantics

The package should distinguish two concepts:

1. **Semantic serialization:** A public template is encoded as validated template
   text and reparsed on decode.
2. **Compiled cache serialization:** A disposable implementation-version-bound
   artifact attempts to avoid parsing.

Only the first should be the public `Codable` contract. It enables users to
encode arrays, dictionaries, configuration records, and suites of templates
without making the AST public. It also ensures every decoded value passes the
current parser and invariants.

The second should exist only after evidence shows that it materially improves a
real startup workload. On the audit machine, parsing was approximately
4.48 μs/template, and serialization/deserialization necessarily incurs its own
decoding, allocation, and validation costs. A versioned compiled cache may be
useful for extremely large template collections, but it should be separately
named, opaque, disposable, source-backed, and capable of falling back to
parsing.

If losing the artifact is acceptable because authoritative source text still
exists, it is a cache. If the artifact is the only copy, it is persistence and
needs the stable semantic string format.

### Platform policy

Apple OS version 26+ is an intentional boundary. It should be documented rather
than “fixed.” The package should update to Swift tools version 6.3 and keep a
small representative validation matrix. A compact support promise that is
actually maintained is preferable to a broad untested matrix.

### Security boundaries

The package expands strings according to RFC rules; it does not and should not
silently become a URL authorization framework. Documentation must make these
boundaries explicit:

- A template can determine the result's scheme, authority, path, query, or
  fragment.
- Reserved and fragment operators deliberately preserve syntax-significant
  delimiters.
- Untrusted input can therefore produce an unexpected host, path traversal-like
  structure, or dangerous scheme even when expansion is RFC-correct.
- Callers must validate the expanded scheme and destination for their use case.
- Resource consumption must scale linearly and callers handling untrusted large
  input may still need size limits.
- Error descriptions must not expose expansion values by default.

## Recommended work order

Semantic dependencies should control the order in which findings are fixed:

1. **Establish truthful tests first**
   - R-01: pin and execute the complete corpus.
   - Add regression tests for each known defect before or with its fix.
2. **Repair parser and expansion correctness**
   - R-02 through R-08.
   - Keep each semantic defect in a focused change.
3. **Repair robustness and state boundaries**
   - R-09: linear percent scanning.
   - R-10: association semantics and nontrapping APIs.
   - R-11: semantic Codable and parser-enforced decoding.
   - R-12 and R-13: correct, safe diagnostics.
4. **Restore all supported build surfaces**
   - R-14: heavy-debug.
   - R-15: decide and complete/remove Objective-C.
   - R-16: remove Comparable and settle value inspection.
5. **Simplify and benchmark**
   - R-17: immutable storage and ABI visibility.
   - Perform this after correctness tests provide a trustworthy safety net.
6. **Create the release system**
   - R-18 through R-20: toolchain/CI, documentation/security/release process,
     and attribution/provenance.
7. **Harden contributor experience**
   - R-21 and any follow-up cleanup.
8. **Run the independent final production-readiness audit**
   - Do not merely check that issue tickets are closed. Re-run the original
     probes and search for new defects introduced by the remediation.

## Release gates

### Gate A — Eligible for an experimental `0.x` public preview

All of the following should be true:

- The unmodified, pinned current shared corpus is fully executed and every case
  exhibits its expected behavior.
- R-02 through R-11 are resolved.
- No public input path identified by the audit traps the process.
- Percent-dense expansion demonstrates linear scaling.
- Debug, release, heavy-debug, public-consumer, ASan, and TSan checks are green.
- The supported Swift 6.3 and Apple OS 26+ policy is documented.
- README security guidance and third-party notices exist.
- The preview is labeled pre-1.0 and does not promise unresolved API stability.

### Gate B — Eligible for `1.0`

In addition to Gate A:

- Codable's semantic format and compatibility promise are documented and
  tested.
- Any compiled-cache API has benchmark evidence, explicit versioning, source
  fallback, and a disposable-cache contract.
- Duplicate-association behavior is coherent across Swift, Objective-C,
  Codable, and secure coding.
- Comparable has been removed as decided.
- Objective-C is either complete and tested by a real consumer or explicitly
  unsupported/removed.
- Public errors are structured, useful, and safe to log.
- Storage architecture and `@inlinable` exposure have been deliberately
  retained or simplified based on benchmark evidence.
- CI protects every documented supported surface.
- Documentation, security policy, contribution guidance, changelog, release
  process, and license notices are complete.
- The rigorous post-remediation audit passes without unresolved production
  blockers.

### Production-use acceptance criteria

Before introducing the library into a load-bearing work system, record evidence
that:

- Every pinned specification case behaves as expected through the public API.
- Boundary, property, differential, fuzz, sanitizer, and concurrency testing are
  clean.
- Adversarial runtime and allocation growth are linear or otherwise bounded and
  documented.
- No public or decoded input can create invalid state or terminate the process.
- Every constructible persisted value round-trips under its documented format.
- Error and debug surfaces do not disclose template values by default.
- Scheme/destination validation and input-size limits are implemented by the
  consuming application where required.
- The exact package version, Swift version, SDK, and platform configuration are
  reproducible in CI.
- Operational ownership exists for security reports, dependency/toolchain
  updates, RFC/test-suite updates, and regressions.

## Final assessment

HDXLURITemplate has more engineering substance than its sparse repository
presentation suggests. Its common paths are fast, the test suite executes nearly
all production lines, and targeted dynamic analysis found no general
memory-safety, fuzz-stability, or concurrency failure. These are meaningful
reasons to finish the project.

The decisive concern is that the current green test result is not a reliable
conformance claim. Important official suites are not run, active fixtures are
stale or modified, and direct adversarial checks expose correctness, complexity,
invariant, and public-API defects. Those defects are individually tractable and
can be resolved through a sequence of focused changes protected by a complete
test harness.

The appropriate next state is therefore:

1. Treat this document as the baseline audit record.
2. Track each independently addressable finding with explicit dependencies and
   failing-before-fix regressions for behavioral defects or equivalent
   objective pre-change evidence for nonbehavioral work.
3. Resolve the correctness and robustness blockers before promoting the package.
4. Publish an honest `0.x` preview once Gate A passes.
5. Run the rigorous post-remediation audit before deciding whether the package
   is suitable for `1.0` and production use.
