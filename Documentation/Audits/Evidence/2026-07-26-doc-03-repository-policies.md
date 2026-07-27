# DOC-03 repository-policy evidence

## Scope and baseline

DOC-03/#41 adds the contribution, security, changelog, conduct, and release
process required for a public package. The pre-fix baseline is
`9b41ee5f152d711211dec9b6a9eda2c5efe0b615`.

At that baseline:

- `CONTRIBUTING.md`, `SECURITY.md`, `CODE_OF_CONDUCT.md`, and a release
  checklist did not exist;
- the changelog had an Unreleased section but no explicit format or `0.x`
  compatibility rules;
- README said no private vulnerability-reporting channel existed; and
- GitHub's private vulnerability-reporting endpoint returned
  `{"enabled":false}`.

## Delivered policy

- `CONTRIBUTING.md` records the supported Swift 6.3/Apple 26 setup, all build
  configurations, conformance, hardening, sanitizer, formatting,
  public-consumer, fixture-update, bug-reproducer, and PR dependency rules.
- `SECURITY.md` records pre-release and future `0.x` support, the private
  GitHub reporting route, response targets, coordinated disclosure, and
  URI-template-specific boundaries.
- `CHANGELOG.md` uses explicit Keep a Changelog categories, preserves an
  Unreleased section, defines `0.x` Semantic Versioning behavior, and separates
  security, behavior, removal, and migration information.
- `CODE_OF_CONDUCT.md` governs outside contributions and keeps the
  vulnerability channel limited to security reports.
- The release checklist binds one immutable candidate to Core CI, complete
  conformance, recurring hardening artifacts, API/serialization/Objective-C
  absence review, licensing, documentation, the committed independent audit,
  explicit publication approval, signed immutable tags, release notes, and
  rollback.
- The canary template provides application-owned limits, redacted telemetry,
  thresholds, staged rollout, and a demonstrated rollback record.

## Repository setting

After the repository became public, the maintainer credential successfully
enabled GitHub private vulnerability reporting:

```text
PUT /repos/plx/hdxl-uri-template/private-vulnerability-reporting
HTTP 204

GET /repos/plx/hdxl-uri-template/private-vulnerability-reporting
{"enabled":true}
```

No fake advisory or sensitive content was created. GitHub's enabled setting
exposes the private **Report a vulnerability** form to external reporters and
routes submissions to repository security maintainers.

## Validation record

The policy implementation commit
`2e24ed7e39100e0306f787cfd82c7c44d259184a` was cloned into a separate clean
checkout. The checkout remained clean after validation. It used:

```text
Xcode 26.6 (17F113)
Apple Swift 6.3.3 (swiftlang-6.3.3.1.3 clang-2100.1.1.101)
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
```

All of the following completed successfully:

- `just resolve`, `just dump-package`, `just build-all`, and `just test-all`;
- Debug, Release, and `HEAVY_DEBUG`, including the complete 270-case pinned
  conformance runner and standalone public consumer;
- `just check-clean-output`;
- `xcrun swift test --sanitize address` and
  `xcrun swift test --sanitize thread`, each with an isolated scratch path;
- `just qa-03-smoke`, including 200,000 deterministic fuzz iterations,
  100,000-operation concurrency phases, and all scaling workloads; and
- `just qa-03-detectors`, including controlled seed-replay, quadratic-growth,
  and known-race Thread Sanitizer negative controls.

The documentation was checked with Markdownlint, Lychee 0.24.2, and
`git diff --check`. Lychee checked 49 links, found 36 unique links, reported
zero errors, and followed one redirect.

## Fixture refresh rehearsal

A temporary clone of
[`uri-templates/uritemplate-test`](https://github.com/uri-templates/uritemplate-test)
was detached at
`4171dac22aa67fc710b3f6df308a50bd08552986`. Its `LICENSE` and README
copyright/license notice were reviewed; no upstream `NOTICE` file exists at
that commit. `cmp` confirmed all four repository fixtures are byte-for-byte
identical:

| Fixture | Cases | Bytes | SHA-256 |
| --- | ---: | ---: | --- |
| `spec-examples.json` | 64 | 6,650 | `9148100604d25beb4fcc56b9d3a3ed6a0067d5f042bd472918030aff808f77be` |
| `spec-examples-by-section.json` | 117 | 14,594 | `0122630fddc249595045baef5122ccf41343c052d8524074920c9dc7bcd99543` |
| `extended-tests.json` | 53 | 7,426 | `547c6d6669132a62ea002791cbefed43251c7fe2ad82f8725d930d401e5acd23` |
| `negative-tests.json` | 36 | 2,516 | `7f4bd7def905c492b40fae92b6a51665489539dd773db464022a52eb37907e81` |

`./Scripts/test-check-pinned-fixtures.sh` then proved that both deliberate
content drift and a missing fixture are rejected. The tracked fixtures were
not modified.

## Private-reporting exercise

The enabled setting was read back through GitHub's private
vulnerability-reporting endpoint. The public repository's Security Advisories
page exposes the private reporting route. No test advisory, public report, or
sensitive content was created.

## Non-release checklist dry run

```text
Test commit: 2e24ed7e39100e0306f787cfd82c7c44d259184a
Proposed test version: none; DOC-06/#43 owns candidate selection
Walked by: repository maintainer and remediation agent
Walked at (UTC): 2026-07-27T07:34:45Z
Expected blockers: test commit is not origin/master; no version or immutable
  release candidate has been selected; candidate-profile hardening has not
  been run for this documentation commit; DOC-06/#43 and independent
  AUDIT-01/#44 remain open; no adopter exists for an application rollback drill
Unexpected blockers: none
No tag/release created: confirmed; the repository has no tags or GitHub Releases
Rollback path reviewed: yes; adopter-specific execution is not yet applicable
Final result: DRY RUN ONLY — NOT AUTHORIZED FOR PUBLICATION
```

The checklist therefore stops before tag, signing, release-note publication,
or rollback execution. Until DOC-06/#43 selects an immutable candidate and
AUDIT-01/#44 records independent sign-off, publication remains blocked by
design.
