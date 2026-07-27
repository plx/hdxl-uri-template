# Changelog

All notable changes to this package are documented in this file.

The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) categories and the
package uses [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

During `0.x`, a minor release may make incompatible public API, serialization,
or behavior changes. Patch releases are reserved for backward-compatible
fixes, security remediation, and documentation/build corrections. Every
incompatible change must appear under `Changed` or `Removed` with migration
guidance. Security-relevant changes are called out separately under
`Security`.

There are no published versions yet.

## [Unreleased]

### Added

- Added the complete byte-faithful `uri-templates/uritemplate-test` corpus,
  exact fixture integrity pins, and verified RFC 6570 errata coverage.
- Added clean Swift 6.3 Debug, Release, `HEAVY_DEBUG`, and Apple 26 platform
  CI gates plus recurring sanitizer, deterministic-fuzz, concurrency, and
  scaling evidence.
- Added a standalone public Swift consumer that compiles and runs documented
  examples, error bridging, `Codable`, and concurrent-use contracts without
  `@testable`.

### Changed

- Changed `URITemplate` encoding to a single validated template-source string.
  Decoding reparses that source through the public grammar; historical
  private-AST payloads are intentionally unsupported and require migration
  from an authoritative template string.
- Raised the supported environment floor to Swift tools 6.3 in Swift language
  mode 6 and Apple OS version 26 across iOS, macOS, tvOS, watchOS, visionOS,
  and Mac Catalyst. Older Swift toolchains, older Apple OS releases, and
  non-Apple platforms are unsupported.

### Removed

- Removed the incomplete pre-release Objective-C facade. The
  `HDXLURITemplate` and `HDXLURIVariableValue` wrapper classes,
  `HDXLURIVariableValueType` Objective-C exposure, wrapper-only
  `NSCopying`/`NSCoding`/`NSSecureCoding` surface, and Objective-C SwiftPM test
  target are no longer present. The initial `0.x` contract is Swift-only;
  migrate to native `URITemplate` and `URIVariableValue` APIs. Removed wrapper
  archives are unsupported and are not migrated.
- Removed the public `Comparable` conformances and `<` operators from
  `URITemplate`, `URIVariableValue`, and `URIVariableValueType`. Their former
  structural ordering was an implementation detail rather than a semantic
  contract. Their existing `Equatable`, `Hashable`, `Sendable`, and `Codable`
  behavior remains available.

### Fixed

- Corrected literal grammar, percent-triplet preservation, Unicode prefix
  truncation, composite-prefix rejection, ordered association invariants, and
  public error boundaries covered by the pinned conformance and regression
  suites.

### Security

- Made default descriptions and bridged `NSError` diagnostics for
  `URITemplate.ParseError` and `URITemplate.EvaluationError` bounded and
  privacy-safe. `EvaluationError` exposes payload-free failure metadata for
  programmatic diagnosis; explicit recovery properties remain potentially
  sensitive.
- Hardened GitHub Actions with least-privilege permissions, immutable
  third-party action pins, clean checkouts, exact candidate SHAs, and
  fail-closed aggregate gates.
- Documented untrusted-input, reserved-expansion, destination-validation,
  resource-limit, and safe-logging boundaries.

[Unreleased]: https://github.com/plx/hdxl-uri-template/commits/master
