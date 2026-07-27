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
