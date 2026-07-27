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

Record final command results here and on the exact-head pull request:

- clean supported-toolchain build and test commands;
- conformance and public-consumer checks;
- sanitizer and hardening smoke commands;
- temporary-copy fixture refresh and deliberate drift detection;
- Markdown and link validation;
- private-reporting setting verification; and
- non-release checklist dry run with expected blockers.

The dry run must create no tag or GitHub Release. Until DOC-06/#43 selects an
immutable candidate and AUDIT-01/#44 records independent sign-off, publication
remains blocked by design.
