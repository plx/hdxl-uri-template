# DOC-06 release-candidate preparation evidence

Date: July 27, 2026

Tracking issue:
[DOC-06/#43](https://github.com/plx/hdxl-uri-template/issues/43)

Preparation baseline:
`dea681ea83187ea32691f55f5f272ffc02d0e5ff`

## Pre-candidate state

At the baseline:

- all five implementation topic epics (#6–#10) were closed as completed;
- every leaf P0/P1 remediation issue had its intended terminal disposition;
- only candidate preparation #43 and final audit #44 remained as actionable
  P0 leaves;
- `master` was green under exact-SHA Core CI;
- the repository contained no Git tag; and
- `gh release view 0.1.0` reported that the release did not exist.

Packaging epic #11 remains open until candidate validation completes. Program
issue #5 remains open through the final audit verdict.

## Version and compatibility selection

The proposed version is `0.1.0`: the smallest Semantic Versioning version for
an intentional initial public contract without a `1.0` stability claim.

The checked candidate record defines the complete pre-`1.0` policy. Minor
versions may make incompatible public API, behavior, platform, or
serialization changes with migration guidance. Patch releases remain
backward-compatible. Only the latest published minor line and patch receive
security support. No binary ABI promise applies.

## Prepared materials

The preparation adds:

- a candidate identity protocol that records the otherwise self-referential
  squash SHA on issue #43;
- a complete evidence index for conformance, hardening, public API, DocC,
  performance, licenses, notices, and publication rights;
- draft `0.1.0` release notes covering support, corrected RFC behavior, API
  and Codable changes, Objective-C absence, security, performance, migration,
  limitations, and provenance;
- an explicit residual-risk register;
- exact-candidate Core CI, hardening, and remote-consumer requirements; and
- pre-publication invalidation plus post-publication withdrawal, fix-forward,
  and adopter rollback procedures.

The README and release checklist link the candidate record while continuing to
state that no tag, release, source-stability promise, or production verdict
exists.

## Immutable identity and post-merge evidence

The DOC-06 squash commit is the candidate. It cannot embed its own SHA. The
issue #43 closing timeline is therefore the public immutable identity record
and must contain the full candidate SHA plus:

- exact-SHA Core CI with the required aggregate gate;
- Recurring Hardening profile `candidate`, seed
  `0x4844584C51413033`, 1,000,000 iterations, and
  `failure_probe=false`;
- Address Sanitizer, Thread Sanitizer/concurrency, deterministic fuzz,
  five-sample Release scaling, detector-control, and aggregate results;
- retained artifact names;
- a clean remote dependency resolution and executable consumer by revision
  through `Scripts/check-remote-consumer.sh`;
- clean `master`/`origin/master` identity; and
- confirmation that `0.1.0` remains untagged and unpublished.

Any failure or subsequent change reopens DOC-06 and invalidates that record.

## Validation boundary

The preparation pull request must pass Markdown lint, link validation,
formatting, documentation synchronization, package tests, exact-head Core CI,
and review. The merge commit must then pass the candidate-specific checks
above.

Before opening the preparation pull request:

- Markdown lint passed on every changed authored page;
- Lychee checked 143 links, found 97 unique links, and reported zero errors;
- repository formatting, its negative/idempotence detector, shell syntax,
  action workflow syntax, package-manifest evaluation, and whitespace checks
  passed;
- the manifest reported Swift tools 6.3 and no package dependencies;
- the remote-consumer guard's syntax and malformed-revision regression
  checks passed;
- the remote-consumer script rejected an abbreviated SHA, then resolved,
  built, and ran the exact baseline revision
  `dea681ea83187ea32691f55f5f272ffc02d0e5ff`;
- all four pinned fixture hashes remained unchanged;
- the repository had zero tags; and
- a GitHub Release lookup for `0.1.0` returned `release not found`.

Completing this record prepares evidence for AUDIT-01/#44. It does not execute
that independent audit and does not authorize publication.
