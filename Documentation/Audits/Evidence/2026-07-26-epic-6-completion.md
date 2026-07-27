# Epic #6 RFC 6570 Conformance Completion Evidence

## Conclusion

**PASS.** At audited `master` commit
`b2fe806d14c71369050c456e1228c8cd1899da05`, HDXLURITemplate executes the
complete pinned RFC 6570 reference corpus with no unexplained failure, skip,
quarantine, fixture edit, or expected-failure ledger. The same corpus passes
the required Xcode 26.6 / Swift 6.3 gate in Debug, Release, and
`HEAVY_DEBUG`.

This record closes only
[epic #6](https://github.com/plx/hdxl-uri-template/issues/6). It does not
publish a release or broaden the supported Swift and Apple platform boundary.

## Audited revision and environments

- Revision:
  [`b2fe806d14c71369050c456e1228c8cd1899da05`](https://github.com/plx/hdxl-uri-template/commit/b2fe806d14c71369050c456e1228c8cd1899da05)
- Required hosted environment: Xcode 26.6, Apple Swift 6.3.3
  (`swiftlang-6.3.3.1.3`), `macos-26`
- Supplemental local environment: Xcode 27.0, Apple Swift 6.4,
  macOS 27.0 build `26A5378n`, Apple silicon
- Pinned oracle:
  [`uri-templates/uritemplate-test@4171dac22aa67fc710b3f6df308a50bd08552986`](https://github.com/uri-templates/uritemplate-test/commit/4171dac22aa67fc710b3f6df308a50bd08552986)

The local run is regression evidence only. Support evidence comes from the
hosted Xcode 26.6 / Swift 6.3 run.

## Native gate inventory

Every required child and the sole native blocker closed through its intended
merged pull request before this gate audit.

| Issue | Role | Closing pull request | Merge commit |
| --- | --- | --- | --- |
| [#55](https://github.com/plx/hdxl-uri-template/issues/55) | Fail-closed fixture-activation accounting | [#56](https://github.com/plx/hdxl-uri-template/pull/56) | `570c55afa72f1f5a20f8187f0c60b683b07bcd91` |
| [#12](https://github.com/plx/hdxl-uri-template/issues/12) | Complete byte-faithful fixture snapshot | [#57](https://github.com/plx/hdxl-uri-template/pull/57) | `dba31dacc1fe4601aa02f6183d8d8e5d7330900b` |
| [#13](https://github.com/plx/hdxl-uri-template/issues/13) | Four-suite behavioral runner | [#58](https://github.com/plx/hdxl-uri-template/pull/58) | `b88fc725af840adf4b4e45948d5768fde0518b91` |
| [#18](https://github.com/plx/hdxl-uri-template/issues/18) | Apostrophe and tilde literal grammar | [#60](https://github.com/plx/hdxl-uri-template/pull/60) | `85bcedc3a74aafdf99f93c3f6244ddd7f4b2041a` |
| [#25](https://github.com/plx/hdxl-uri-template/issues/25) | Unicode literal percent-encoding | [#62](https://github.com/plx/hdxl-uri-template/pull/62) | `c39d3a1939e0875cb1d8cfc40eb476f55bb53805` |
| [#26](https://github.com/plx/hdxl-uri-template/issues/26) | Reserved-expansion character set | [#63](https://github.com/plx/hdxl-uri-template/pull/63) | `020a235ca15ea10f6a000e592e4ca140fe3bb99a` |
| [#27](https://github.com/plx/hdxl-uri-template/issues/27) | Expression variable-list grammar | [#64](https://github.com/plx/hdxl-uri-template/pull/64) | `018a8ebc7d7f55e9eca0e1bc61f30006558f04b4` |
| [#29](https://github.com/plx/hdxl-uri-template/issues/29) | Prefix-modifier lexical ABNF | [#66](https://github.com/plx/hdxl-uri-template/pull/66) | `b78dca73a8444e1c8c36577fb6199ff3ffdf44b9` |
| [#33](https://github.com/plx/hdxl-uri-template/issues/33) | Composite-value prefix rejection | [#67](https://github.com/plx/hdxl-uri-template/pull/67) | `db5ddb21cfc878665ade2e2b9a9619db897c1687` |
| [#32](https://github.com/plx/hdxl-uri-template/issues/32) | Authoritative template source | [#68](https://github.com/plx/hdxl-uri-template/pull/68) | `5e079c880b82dd98665398441a22890cdb815db0` |
| [#34](https://github.com/plx/hdxl-uri-template/issues/34) | Decoded Unicode prefix counting | [#69](https://github.com/plx/hdxl-uri-template/pull/69) | `e31b569ce9d91526ae7d83a5bee11ae02295d501` |
| [#35](https://github.com/plx/hdxl-uri-template/issues/35) | Zero shared-suite exceptions | [#70](https://github.com/plx/hdxl-uri-template/pull/70) | `9914ca426ed08731305886d20b2c595a96146eb3` |
| [#20](https://github.com/plx/hdxl-uri-template/issues/20) | Native blocker: required Swift 6.3 CI | [#88](https://github.com/plx/hdxl-uri-template/pull/88) | `b2fe806d14c71369050c456e1228c8cd1899da05` |

The audited dormant `ucschar` transcription was intentionally removed after
proving it had no production consumer in
[ARCH-04/#38](https://github.com/plx/hdxl-uri-template/issues/38), merged as
[PR #84](https://github.com/plx/hdxl-uri-template/pull/84) at
`ac10d3f872867319199f858389a74b7e05afa1fd`. Active `ucschar` literal behavior
remains covered by the grammar and expansion regressions.

## Exit-criterion evidence

1. Complete unmodified pinned corpus with exact counts and provenance:
   `check-pinned-fixtures.sh` verified `64 / 117 / 53 / 36` cases, exact byte
   sizes, and all four SHA-256 values documented in the fixture README. The
   ledger identifies the immutable upstream commit, Apache-2.0 notice,
   reproduced license, and update procedure.
2. Both RFC suites, extended tests, and negative tests execute with correct
   semantics: `ReferenceExampleBehaviorVerificationTests` locks all four suite
   identities and counts. The unified parameterized test executed 270 cases:
   193 exact results, 41 allowed-alternative results, and 36 controlled
   negative outcomes. Synthetic verifier tests prove that exact/alternative
   mismatches, unexpected successes, and non-public errors fail closed.
3. Focused regressions prove every confirmed defect before and after its fix:
   the closing PRs above preserve red-before-fix evidence. Current focused
   suites cover literal grammar, Unicode literal encoding, reserved characters,
   whitespace/empty varspecs, prefix ABNF, exact source retention,
   composite-prefix rejection, and decoded Unicode prefix boundaries. PR #84
   preserves the separate removal evidence for the unused `ucschar` table. All
   focused coverage passed in the aggregate runs below.
4. `templateRepresentation` is valid and authoritative:
   `URITemplateSourceRepresentationTests` proves byte-exact retention for
   accepted sources, reparsing equality, evaluation equivalence, copy
   stability, Codable round trips, all parseable pinned sources, and 264
   generated valid sources.
5. All pinned cases pass with no exception mechanism or unrelated `URL`
   failure: the unified runner calls the public parser and string-expansion
   verifier directly. All 270 cases passed in every required lane. A source and
   filename scan found no `XCTSkip`, `withKnownIssue`, known/expected-failure
   registry, quarantine, or specification-runner skip file. Negative cases
   accept only controlled public parse or evaluation rejection; unrelated
   errors and unexpected successful expansion are explicit test failures.
6. The same conformance gate runs in CI: required
   [Core CI run 30238505867][core-ci] passed on the audited `master` SHA. Its
   Debug, Release, and `HEAVY_DEBUG` jobs each ran the complete 270-case
   parameterized test, including the 36-case negative-boundary test. The
   aggregate [required check][required-check] passed.

## Validation

- `just build-all` — Debug, `HEAVY_DEBUG`, and Release builds passed with the
  warning guard.
- `just test-all` — fixture integrity and guard regressions passed; the public
  API check passed; Debug passed 187 package tests plus 8 public-consumer
  tests; `HEAVY_DEBUG` passed 188 plus 8; Release passed 188 plus 8.
- `Scripts/check-pinned-fixtures.sh` — all four case counts, byte sizes, and
  SHA-256 values matched the committed ledger.
- Shared-suite exception scan — no skip, known-failure, expected-failure,
  quarantine, or exception-ledger mechanism found.
- `git diff -- Tests/HDXLURITemplateTests/Resources` — empty; this evidence
  work does not alter upstream fixtures.
- [Hosted Debug][debug-job] — Xcode 26.6 / Swift 6.3.3; complete 270-case
  runner and 36-case controlled negative boundary passed.
- [Hosted Release][release-job] — Xcode 26.6 / Swift 6.3.3; complete 270-case
  runner and 36-case controlled negative boundary passed.
- [Hosted `HEAVY_DEBUG`][heavy-job] — Xcode 26.6 / Swift 6.3.3; complete
  270-case runner and 36-case controlled negative boundary passed.
- [Hosted Apple 26 platform smoke][platform-job] — macOS, iOS, Mac Catalyst,
  tvOS, watchOS, and visionOS Release compiles passed.

## Inspection for regressions and unrepresented work

Current source, conformance support code, fixture provenance, regression tests,
and CI were inspected after all children landed. No fixture drift, reintroduced
exception path, dormant conformance implementation, or uncovered defect from
the epic definition was found. No new issue was required.

## Residual risks and owners

- Conformance is intentionally tied to the pinned upstream revision. A future
  fixture update requires a reviewed snapshot change, refreshed hashes/counts,
  and another complete run; the repository's fixture guard fails closed on
  unreviewed drift.
- This pass is limited to Swift 6.3 and Apple OS 26+ as documented. It makes no
  claim for older Swift, older Apple systems, Linux, Windows, or other
  platforms.
- Recurring sanitizer, fuzz, long concurrency, and performance-regression
  coverage remains owned by [QA-03/#21](https://github.com/plx/hdxl-uri-template/issues/21);
  it is not a conformance failure.
- Production user documentation, candidate preparation, and the independent
  final audit remain owned by
  [DOC-01/#39](https://github.com/plx/hdxl-uri-template/issues/39),
  [DOC-06/#43](https://github.com/plx/hdxl-uri-template/issues/43), and
  [AUDIT-01/#44](https://github.com/plx/hdxl-uri-template/issues/44).

No accepted residual risk weakens the epic's conformance conclusion.

[core-ci]: https://github.com/plx/hdxl-uri-template/actions/runs/30238505867
[required-check]: https://github.com/plx/hdxl-uri-template/actions/runs/30238505867/job/89891126563
[debug-job]: https://github.com/plx/hdxl-uri-template/actions/runs/30238505867/job/89890801032
[release-job]: https://github.com/plx/hdxl-uri-template/actions/runs/30238505867/job/89890801029
[heavy-job]: https://github.com/plx/hdxl-uri-template/actions/runs/30238505867/job/89890801043
[platform-job]: https://github.com/plx/hdxl-uri-template/actions/runs/30238505867/job/89890801012
