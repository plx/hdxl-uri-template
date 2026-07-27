# Changelog

All notable changes to this package are documented in this file.

## Unreleased

### Changed

- Removed the public `Comparable` conformances and `<` operators from
  `URITemplate`, `URIVariableValue`, and `URIVariableValueType`. Their former
  structural ordering was an implementation detail rather than a semantic
  contract. Their existing `Equatable`, `Hashable`, `Sendable`, and `Codable`
  behavior remains available.
