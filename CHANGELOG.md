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

- Added read-only `textValue`, `listValue`, and ordered `associationValue`
  accessors to `URIVariableValue`. Flavor mismatches return `nil`, empty
  payloads remain distinguishable, and returned collections cannot mutate the
  original value or its association invariants.
- Added the complete byte-faithful `uri-templates/uritemplate-test` corpus,
  exact fixture integrity pins, and verified RFC 6570 errata coverage.
- Added clean Swift 6.3 Debug, Release, `HEAVY_DEBUG`, and Apple 26 platform
  CI gates plus recurring sanitizer, deterministic-fuzz, concurrency, and
  scaling evidence.
- Added a standalone public Swift consumer that compiles and runs documented
  examples, error bridging, template `Codable`, value-model, and concurrent-use
  contracts without `@testable`.
- Added warning-free DocC API and conceptual documentation for the complete
  supported public Swift surface, with synchronized compiled examples,
  link validation, symbol coverage, and failure-oriented CI detectors.
- Added a checked Swift 6.3 formatting policy, isolated mechanical baseline,
  nonmutating CI lint gate, idempotence detector, and explicit exclusions for
  generated output and vendored JSON fixtures.
- Prepared an explicitly untagged, audit-pending `0.1.0` candidate record,
  compatibility policy, evidence bundle, draft release notes, residual-risk
  register, and rollback/withdrawal procedures.

### Changed

- Removed seven unreachable historical expansion-error cases and made twelve
  total text, list, and association formatting functions nonthrowing. One
  typed internal error now carries composite-prefix rejection to the public
  evaluation boundary; invalid URL construction remains distinct.
- Removed pervasive cross-module and forced-inlining annotations that exposed
  internal parser, expansion, value-model, and storage declarations to client
  optimization. Measured public-client parse, expansion, hashing, and semantic
  Codable behavior remains within 3.7%, while the compiled module and final
  consumer executable are substantially smaller.
- Changed `URITemplate` storage to one immutable, compiler-checked `Sendable`
  reference initialized with parsed components, exact source, and variable
  names. Warm metadata reads no longer mutate lazy caches or acquire an unfair
  lock, while the measured reference representation preserves the existing
  eight-byte value size and cheap-copy behavior.
- Changed `URITemplate` encoding to a single validated template-source string.
  Decoding reparses that source through the public grammar; historical
  private-AST payloads are intentionally unsupported and require migration
  from an authoritative template string.
- Changed `URITemplate.ParseError` to expose a stable semantic `kind` and an
  authoritative half-open `sourceRange` measured in UTF-8 bytes. Zero-length
  ranges identify insertion points. Codable rejection of invalid template
  strings retains the same parse error as the underlying
  `DecodingError.dataCorrupted` cause.
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
  contract. Their existing `Equatable`, `Hashable`, and `Sendable` behavior
  remains available.
- Removed `Codable`, `Encodable`, and `Decodable` from
  `URIVariableValue` and `URIVariableValueType`, together with private coding
  machinery that existed only to support them. The pre-release numeric-tagged
  encoding exposed private storage and is unsupported. Persist an
  application-owned source DTO and construct runtime values through the public
  factories; `URITemplate.Codable` is unchanged.
- Removed `URITemplate.ParseError.underlyingError` and the public generic
  `DataValidationError<T>`. Inspect `ParseError.kind` and `sourceRange` instead
  of private parser errors.

### Fixed

- Corrected literal grammar, percent-triplet preservation, Unicode prefix
  truncation, composite-prefix rejection, ordered association invariants, and
  public error boundaries covered by the pinned conformance and regression
  suites.
- Stabilized the frozen percent-triplet scaling oracle by warming every input
  size and rotating measurement order across sample rounds, without changing
  its workloads, repetition counts, sample count, or rejection thresholds.

### Security

- Made default descriptions and bridged `NSError` diagnostics for
  `URITemplate.ParseError` and `URITemplate.EvaluationError` bounded and
  privacy-safe. Both errors expose payload-free failure metadata for
  programmatic diagnosis; parse locations contain offsets only, while explicit
  recovery properties remain potentially sensitive.
- Hardened GitHub Actions with least-privilege permissions, immutable
  third-party action pins, clean checkouts, exact candidate SHAs, and
  fail-closed aggregate gates.
- Documented untrusted-input, reserved-expansion, destination-validation,
  resource-limit, and safe-logging boundaries.

[Unreleased]: https://github.com/plx/hdxl-uri-template/commits/master
