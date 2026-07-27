# Epic #7 Security, Robustness, and Adversarial-Performance Completion Evidence

Current-status note: this immutable-SHA evidence accurately describes its
audited revision. The later
[API-06 decision](../../Decisions/API-06-URIVariableValue-Codable.md) removed
value coding and changed current hardening from value round trips to equivalent
runtime semantic validation. `URITemplate.Codable` remains covered.

## Conclusion

**PASS.** At audited `master` commit
`8b0862085cb50f25246631b697849a9abe4f2422`, HDXLURITemplate processes
percent-dense expansion input linearly, rejects invalid public association
input through controlled errors, preserves the ordered unique-key invariant,
keeps default parse and evaluation diagnostics bounded and payload-free, and
documents the delimiter, destination, input-size, and logging boundaries that
remain the caller's responsibility.

The exact audited commit also passed the supported Xcode 26.6 / Swift 6.3.3
Core CI and the complete QA-03 release-candidate hardening profile. This record
closes only
[epic #7](https://github.com/plx/hdxl-uri-template/issues/7). It does not
publish a release or broaden the supported Swift and Apple platform boundary.

## Audited revision and environments

- Revision:
  [`8b0862085cb50f25246631b697849a9abe4f2422`](https://github.com/plx/hdxl-uri-template/commit/8b0862085cb50f25246631b697849a9abe4f2422)
- Required hosted environment: Xcode 26.6 build `17F113`, Apple Swift 6.3.3
  (`swiftlang-6.3.3.1.3`), macOS 26.4 on the `macos-26` ARM64 image
  `20260720.0258.1`
- Supplemental local environment: Xcode 27.0 build `27A5218g`, Apple Swift
  6.4, macOS 27.0 build `26A5378n`, Apple silicon
- Candidate hardening seed: `0x4844584C51413033`
- Frozen scaling thresholds: no adjacent ratio above `3.0` and no fitted
  exponent above `1.25`

The local aggregate is regression evidence. Support and hardening acceptance
evidence comes from the hosted Xcode 26.6 / Swift 6.3.3 runs.

## Native gate inventory

Every required child and cross-workstream blocker closed through its intended
merged pull request before this gate audit.

| Issue | Role | Closing pull request | Merge commit |
| --- | --- | --- | --- |
| [#19](https://github.com/plx/hdxl-uri-template/issues/19) | `HARD-01`: linear percent-escape scanning | [#61](https://github.com/plx/hdxl-uri-template/pull/61) | `b9e6bb54ee3e579fc5e812edfdf8b839d6efdd2d` |
| [#28](https://github.com/plx/hdxl-uri-template/issues/28) | `HARD-02`: controlled association invariants | [#65](https://github.com/plx/hdxl-uri-template/pull/65) | `ad37a2a6567bc8ece1d1ee24cae66597d15e12b7` |
| [#30](https://github.com/plx/hdxl-uri-template/issues/30) | `HARD-03`: privacy-safe default errors | [#78](https://github.com/plx/hdxl-uri-template/pull/78) | `4843b7861a9d83758b28cc009b87852f29828f1d` |
| [#39](https://github.com/plx/hdxl-uri-template/issues/39) | Native blocker: security-boundary user documentation | [#91](https://github.com/plx/hdxl-uri-template/pull/91) | `98d2fbc64cf9eae7500293b9337dbf4660d6991c` |
| [#21](https://github.com/plx/hdxl-uri-template/issues/21) | Native blocker: recurring hardening automation | [#92](https://github.com/plx/hdxl-uri-template/pull/92) | `8b0862085cb50f25246631b697849a9abe4f2422` |

The later Objective-C policy branch removed the unsupported facade in
[API-10/#81](https://github.com/plx/hdxl-uri-template/issues/81), merged through
[PR #85](https://github.com/plx/hdxl-uri-template/pull/85) at
`51f06ea3d2fcb6e9ec478d53fa49af3df92d587a`. The current public API guard
therefore verifies the absence of the three former Objective-C entry points;
there is no remaining Objective-C caller-input boundary to claim as supported.

## Exit-criterion evidence

1. **Percent-triplet processing is single-pass and demonstrably linear.**
   `String+URIValueExpansion.swift` advances once over the UTF-8 view, uses
   bounded lookahead for each `%HH` triplet and at most one encoded UTF-8
   scalar for prefix counting, and appends directly to one reserved result
   buffer. The retained Release-only
   `PercentEscapeScannerStressTests` gate passed locally. In the supported
   hosted candidate, `dense-valid-percent` measured a fitted exponent of
   `1.0026` with a maximum adjacent ratio of `2.0326`;
   `dense-malformed-percent` measured `0.8469` and `2.0721`. All values are
   below the frozen `1.25` and `3.0` rejection thresholds.
2. **Caller-controlled failures are controlled rather than trapping.**
   Public pair-sequence construction routes through
   `URIVariableValue.association(_:)`, which throws the first duplicate's
   indices. Codable decoding uses the same validator. Dictionary construction
   is total and deterministically ordered. A current source scan found no
   `Dictionary(uniqueKeysWithValues:)` in production and no public-input
   `precondition`; the remaining preconditions are internal lock/invariant or
   literal helpers whose inputs are already canonical. Malformed templates,
   composite-prefix misuse, duplicate associations, and malformed coding
   payloads all passed their controlled-failure regressions in Debug,
   `HEAVY_DEBUG`, and Release.
3. **Public associations obey one documented invariant.**
   `URIVariableValue` documents associations as ordered unique-key pairs and
   documents `AssociationError.duplicateKey`. Direct construction, arbitrary
   sequence consumption, deterministic first-duplicate selection, large and
   seeded inputs, JSON, property-list, expansion, equality, and hashing tests
   passed. The established ordered Codable shape remains unchanged.
4. **Default errors do not disclose sentinel secrets or rendered
   credentials.** Parse and evaluation errors expose bounded, payload-free
   default string, debug, localized, ordinary `String(reflecting:)`, and
   bridged-error surfaces. Raw `Mirror.children` traversal remains an explicit
   sensitive-recovery boundary. The retained adversarial tests cover template
   source, text/list/association values and keys, variable names, rendered
   output, and nested causes with a 512-byte UTF-8 bound. The hosted ASan fuzz
   lane additionally generated
   `SENSITIVE_TEMPLATE_` and `SENSITIVE_VALUE_` payloads and completed 20,000
   cases without a diagnostic-leak or sanitizer failure.
5. **Permanent deterministic hardening preserves the audit evidence.**
   [Recurring Hardening run 30243840657][hardening-run] passed its required
   aggregate on the exact audited SHA. It completed 1,000,000 deterministic
   parser/value/Codable cases; the ASan full suite and 20,000-case fuzz lane;
   the TSan full suite and three 100,000-operation concurrency phases; all six
   frozen Release scaling workloads; and the exact-replay, quadratic-detector,
   and real TSan-race negative controls. The three concurrency phases produced
   the same `0xA56FC2B48241E87E` digest. The separate
   [controlled-failure run 30243485936][controlled-run] proved the required
   gate fails and retains `qa-03-detector-controls-1` after an intentional
   failure.
6. **Security documentation explains delimiter injection and unsafe
   resulting destinations.** The README's top-level security boundary states
   that reserved and fragment expansion preserve `/`, `?`, and `#`; explains
   that untrusted values can change URI structure; requires
   application-owned scheme, host, port, path, and destination allowlists;
   recommends simple expansion when delimiters should be encoded; requires
   caller-selected input/output limits; and identifies the explicit recovery
   and reflection surfaces that can contain sensitive data.

## Validation

- `just build-all` — Debug, `HEAVY_DEBUG`, and Release builds passed under the
  supplemental local Xcode 27 / Swift 6.4 environment.
- `just test-all` — pinned fixture and warning-guard regressions passed; the
  public API contract passed; Debug passed 193 package tests plus 8 public API
  tests; `HEAVY_DEBUG` passed 194 plus 8; Release passed 194 plus 8, including
  the Release-only linear geometric gate.
- [Core CI run 30243470294][core-ci] — passed on the exact audited SHA. The
  supported [Debug][debug-job], [Release][release-job],
  [`HEAVY_DEBUG`][heavy-job], and [all-platform Apple 26 smoke][platform-job]
  lanes passed, followed by the [required aggregate][required-check].
- [Recurring Hardening run 30243840657][hardening-run] — passed all five
  substantive lanes and the required aggregate on the exact audited SHA.
  Retained artifacts are `qa-03-address-sanitizer-1`,
  `qa-03-thread-sanitizer-1`, `qa-03-deterministic-fuzz-1`,
  `qa-03-release-scaling-1`, and `qa-03-detector-controls-1`.
- The downloaded deterministic report recorded 1,000,000 requested and
  completed iterations, 547,164 accepted templates, 452,836 controlled parser
  rejections, 460,763 successful expansions, 86,401 controlled expansion
  failures, and 961,620 variable-value Codable round trips.
- The downloaded scaling report recorded all six workloads as passing; fitted
  exponents ranged from `0.8211` to `1.1242` and every adjacent ratio remained
  below `2.35`.
- The downloaded concurrency report recorded 100,000 completed operations in
  each single-task, parallel-task, and native-thread phase with identical
  result digests and no TSan report.
- [Controlled-failure run 30243485936][controlled-run] — every substantive
  lane passed, the deliberate detector probe and aggregate failed as designed,
  and all five artifacts remained downloadable with exact SHA, profile, seed,
  iteration budget, toolchain, OS, and hardware provenance.
- Production source scan — no trapping unique-key dictionary construction;
  remaining preconditions are confined to internal invariant/literal,
  assertion, or lock-ownership helpers rather than caller-controlled public
  association, parsing, evaluation, or decoding boundaries.
- README and hardening-document inspection — the user-facing security boundary
  and frozen hardening contracts agree with current source, tests, and hosted
  workflow behavior.
- `git diff --check` — passed.

## Inspection for regressions and unrepresented work

Current expansion, variable-value, error, test, hardening, workflow, and README
surfaces were inspected after all children and blockers landed. The aggregate
and hosted candidate runs exercised the current repository rather than relying
only on child-PR evidence. No reintroduced quadratic scanner, caller-controlled
association trap, secret-bearing default error, stale security claim, disabled
hardening lane, or uncovered epic-scoped defect was found. No new program issue
was required.

## Residual risks and owners

- The library intentionally accepts caller-sized strings and collections and
  can produce proportional output. Application-specific limits and destination
  policy remain caller responsibilities documented in the README.
- Generic `DataValidationError<T>` and the final structured public diagnostic
  contract remain owned by
  [API-05/#49](https://github.com/plx/hdxl-uri-template/issues/49). They do not
  weaken the bounded default parse/evaluation surfaces audited here.
- The formal private security-reporting and release process remains owned by
  [DOC-03/#41](https://github.com/plx/hdxl-uri-template/issues/41).
- QA-03 is deterministic and bounded. The broader independent audit and any
  additional coverage-guided work remain owned by
  [AUDIT-01/#44](https://github.com/plx/hdxl-uri-template/issues/44).
- This pass is limited to Swift 6.3 and Apple OS 26+ as documented. It makes no
  claim for older Swift, older Apple systems, Linux, Windows, or other
  platforms.

No accepted residual risk weakens the epic's security, robustness, or
adversarial-performance conclusion.

[core-ci]: https://github.com/plx/hdxl-uri-template/actions/runs/30243470294
[required-check]: https://github.com/plx/hdxl-uri-template/actions/runs/30243470294/job/89905804220
[debug-job]: https://github.com/plx/hdxl-uri-template/actions/runs/30243470294/job/89905363270
[release-job]: https://github.com/plx/hdxl-uri-template/actions/runs/30243470294/job/89905363269
[heavy-job]: https://github.com/plx/hdxl-uri-template/actions/runs/30243470294/job/89905363268
[platform-job]: https://github.com/plx/hdxl-uri-template/actions/runs/30243470294/job/89905363192
[hardening-run]: https://github.com/plx/hdxl-uri-template/actions/runs/30243840657
[controlled-run]: https://github.com/plx/hdxl-uri-template/actions/runs/30243485936
