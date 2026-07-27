# Changelog

All notable changes to this package are documented in this file.

## Unreleased

### Changed

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
