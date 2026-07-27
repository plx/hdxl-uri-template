# Changelog

All notable changes to this package are documented in this file.

## Unreleased

### Changed

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
- Changed `URITemplate` encoding to a single validated template-source string.
  Decoding reparses that source through the public grammar; historical
  private-AST payloads are intentionally unsupported and require migration
  from an authoritative template string.
- Made the default descriptions and bridged `NSError` diagnostics for
  `URITemplate.ParseError` and `URITemplate.EvaluationError` bounded and
  privacy-safe. `EvaluationError` now exposes payload-free failure metadata
  for programmatic diagnosis; its explicit template, parameter, variable-name,
  and underlying-error recovery properties remain potentially sensitive.
- Raised the supported environment floor to Swift tools 6.3 in Swift language
  mode 6 and Apple OS version 26 across iOS, macOS, tvOS, watchOS, visionOS,
  and Mac Catalyst. Older Swift toolchains, older Apple OS releases, and
  non-Apple platforms are unsupported.
