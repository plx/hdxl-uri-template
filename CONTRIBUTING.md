# Contributing to HDXLURITemplate

Thank you for helping improve HDXLURITemplate. By participating, you agree to
follow the [Code of Conduct](CODE_OF_CONDUCT.md). Report vulnerabilities
privately as described in [SECURITY.md](SECURITY.md), not in an issue or pull
request.

## Supported development environment

The supported build environment is intentionally narrow:

- Swift tools 6.3 in Swift language mode 6;
- Xcode 26.6 with the Apple 26 SDKs; and
- macOS 26 for the complete local suite.

Older Swift toolchains, older Apple OS versions, and non-Apple hosts are not
supported test targets. A change may preserve compatibility outside this
matrix, but it must not weaken or replace the supported checks.

Select the intended Xcode before running commands:

```sh
export DEVELOPER_DIR=/Applications/Xcode_26.6.app/Contents/Developer
xcodebuild -version
xcrun swift --version
```

The reported compiler must be Swift 6.3. Install
[`just`](https://github.com/casey/just) to use the repository recipes.

## Set up and run the required checks

From a clean checkout:

```sh
just resolve
just dump-package
just build-all
just test-all
git diff --check
```

`build-all` and `test-all` cover Debug, Release, and `HEAVY_DEBUG`.
`test-all` also checks the pinned RFC fixtures, warning guards, and the
standalone public consumer. Run an individual configuration while iterating:

```sh
just build-debug
just test-debug
just build-heavy-debug
just test-heavy-debug
just build-release
just test-release
```

Run the public-only API and documentation-example boundary directly with:

```sh
just check-public-api
```

Run the complete pinned conformance corpus and its integrity guard with:

```sh
just check-pinned-fixtures
just test-debug
```

The Debug suite executes all 270 pinned case instances. Deleting, rewriting,
or skipping an upstream case to make a code change pass is prohibited.

## Hardening checks

The ordinary local hardening smoke and detector controls are:

```sh
just qa-03-smoke
just qa-03-detectors
```

Run the complete suite under each sanitizer when changing parsing, expansion,
storage, `Codable`, concurrency, or unsafe/low-level code:

```sh
xcrun swift test --sanitize address
xcrun swift test --sanitize thread
```

The authoritative scheduled and release-candidate procedure, exact fuzz
budgets, concurrency phases, and retained artifacts are documented in
[QA-03 Recurring Hardening](Documentation/Hardening/QA-03-Recurring-Hardening.md).
A local smoke run does not replace the hosted candidate profile.

## Formatting and clean output

Repository-wide formatting enforcement remains tracked separately in
[#24](https://github.com/plx/hdxl-uri-template/issues/24). Until that policy
lands, format and strictly lint each Swift file you change:

```sh
xcrun swift-format format --in-place path/to/Changed.swift
xcrun swift-format lint --strict path/to/Changed.swift
```

Do not submit new compiler warnings, unhandled-resource warnings, debug prints,
or generated build output. The warning guard can be exercised across all
configurations with:

```sh
just check-clean-output
```

## Tests and bug fixes

A behavioral bug fix must include a focused test or reproducer that fails
before the fix and passes afterward. Record the pre-fix behavior in the issue
or pull request. Keep the test after the fix unless the ticket explicitly
requires another durable form of evidence.

Use public imports for consumer-facing behavior. Use `@testable` only when the
test deliberately owns an internal invariant; it is not evidence that a
consumer can use an API.

## Updating the RFC fixture snapshot

Fixture changes must be isolated from implementation changes. Follow the
complete [snapshot update procedure](Tests/HDXLURITemplateTests/Resources/README.md)
in a temporary checkout:

1. Select and review one immutable upstream commit.
2. Replace all four JSON files byte-for-byte from that commit.
3. Review upstream `LICENSE`, `NOTICE`, and README attribution.
4. Recompute every case count, byte count, and SHA-256 digest.
5. Update the fixture README, guard constants, count tests, third-party notice,
   and reproduced license files when applicable.
6. Run the integrity guard and complete test suite.
7. Explain every upstream count, content, or license change in the pull
   request.

Never hand-edit the copied JSON. Project-specific interpretations and
regressions belong in separate Swift sources.

## Pull requests and dependencies

Keep each pull request reviewable and limited to one coherent issue:

- Link the owning issue and use one closing reference only when the PR fully
  satisfies it.
- Use a nonclosing `Refs #...` reference for related work.
- Do not combine fixture updates, formatting sweeps, generated output, or
  unrelated cleanup with a behavioral fix.
- State the supported configuration and commands you ran.
- Call out public API, serialization, Objective-C-absence, security, license,
  performance, and concurrency effects.
- Base dependent work on the merged predecessor. Do not bypass a blocker by
  duplicating its change in a descendant PR.
- Resolve review comments and rerun checks on the exact final head before
  merge.

Pull requests are squash-merged only after the required checks pass. A green
check from an older head does not apply to a changed branch.

## Documentation and release changes

Update README/API documentation and `CHANGELOG.md` with the code that changes
their claims. Security-relevant changes belong under the changelog's
`Security` heading; incompatible behavior belongs under `Changed` or
`Removed` with migration guidance.

Release work must follow the
[Release Checklist](Documentation/Release/Release-Checklist.md). Opening or
merging a release-preparation PR does not authorize a tag, GitHub Release, or
registry publication.
