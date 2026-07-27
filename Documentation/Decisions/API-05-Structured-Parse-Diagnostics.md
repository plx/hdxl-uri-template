# API-05 structured parse diagnostics

Status: final on July 27, 2026.

Approver: repository maintainer.

Tracking issue:
[#49](https://github.com/plx/hdxl-uri-template/issues/49).

## Decision

`URITemplate.ParseError` exposes a stable semantic category and an
authoritative source range:

- `kind: URITemplate.ParseError.Kind`;
- `sourceRange: Range<Int>`, measured as a half-open range of UTF-8 byte
  offsets in `template`; and
- `template: String`, retained as explicit, potentially sensitive recovery
  context.

`Kind` is a `String`-backed, `CaseIterable`, `Sendable` enum with these cases:

| Kind | Meaning |
| --- | --- |
| `unexpectedOpeningBrace` | An opening brace appears inside an expression. |
| `unexpectedClosingBrace` | A closing brace appears outside an expression. |
| `unterminatedExpression` | An expression ends without a closing brace. |
| `emptyExpression` | An expression contains neither an operator nor a variable specification. |
| `emptyVariableSpecification` | A comma-delimited variable position is empty. |
| `invalidOperator` | An expression begins with an unsupported reserved operator. |
| `invalidLiteral` | Literal source contains a scalar forbidden by URI-template syntax. |
| `invalidVariableName` | A variable name does not match URI-template syntax. |
| `invalidModifier` | A prefix or explode modifier does not match URI-template syntax. |
| `malformedPercentEncoding` | A percent sign is not followed by two hexadecimal digits. |
| `other` | A future or defensive fallback cannot be classified more specifically. |

Both range bounds are always within `0...template.utf8.count`. A nonempty
range identifies offending bytes. A zero-length range identifies an insertion
point, including the missing close brace at end of input or a missing variable
after an operator or comma. UTF-8 is authoritative across Swift and Foundation
consumers; clients can derive another indexing system when their editor or
protocol requires one.

The error's default `description`, `debugDescription`, `LocalizedError`
description and failure reason, and bridged `NSError` text are bounded and
payload-free. Exact prose is diagnostic text, not a machine-readable contract;
clients branch on `kind` and locate with `sourceRange`. The explicit `template`
property remains available for recovery and can contain credentials, personal
data, or private URI components, so clients must not log or reflect it without
an application-owned privacy policy.

The previous public `ParseError.underlyingError` property is removed. Internal
parser errors are implementation details and are no longer a public inspection
path.

The generic public `DataValidationError<T>` is removed. It had no supported
public construction path, exposed implementation terminology, and could carry
value-derived diagnostic text. At the API-05 revision, `URIVariableValue`
decoding used standard `DecodingError` cases for malformed data and retained
`URIVariableValue.AssociationError` for duplicate association keys. API-06
subsequently removed value decoding.

`URITemplate` decoding continues to reject invalid semantic strings with
`DecodingError.dataCorrupted`. Its underlying error is the same structured
`URITemplate.ParseError` category and UTF-8 range that direct parsing produces,
while the coding path remains the decoder's.

## Evidence reviewed

The decision reviewed the parser layers, all public error and Codable paths,
the generated Swift symbol graph, the standalone public consumer, the pinned
RFC 6570 positive and negative corpus, and existing privacy-hardening tests.

Repository-wide search found `DataValidationError<T>` only in this package. It
had one production use after decoding private `URIVariableValue` storage and no
public initializer. GitHub code search found no external source consumer of
this package's `DataValidationError` or current parse-error surface. The only
other `URITemplate.ParseError` references were historical code in another
repository owned by the same maintainer, not a consumer of this package.

Before this change, parser failures crossed the public boundary as opaque
private error values. Some internal paths retained copied source fragments,
but clients had no stable category or location. Unicode made character-count
offsets ambiguous across Swift `String`, Foundation, editors, and wire
protocols.

## Rationale and alternatives

Semantic categories plus UTF-8 ranges give callers useful diagnostics without
freezing the parser's private types or copying source fragments into public
payloads. UTF-8 offsets are deterministic for the exact stored template,
portable across languages, and directly testable for multibyte input.

The following alternatives were rejected:

- keeping only prose and opaque underlying errors, because clients could not
  branch safely or highlight a failure;
- exposing private parser error cases, because their payloads and granularity
  are implementation details;
- using `String.Index`, because an index is tied to a particular Swift string
  value and is awkward to persist or bridge;
- using UTF-16 offsets, because that would privilege Foundation editor
  conventions over the package's exact UTF-8 source contract; and
- retaining or broadening `DataValidationError<T>`, because standard
  `DecodingError` already models corrupted encoded data and carries coding
  paths.

The `other` case is retained as a defensive forward-compatible category. It
must not replace a known grammar failure and is covered as part of the stable
case inventory.

## Compatibility and migration

This is an intentional pre-1.0 source break. Code that inspected
`ParseError.underlyingError` should switch on `ParseError.kind` and use
`sourceRange` when a location is needed. Treat `template` as sensitive.

Code that named or caught `DataValidationError` should remove that dependency.
The later [API-06 decision](./API-06-URIVariableValue-Codable.md) removed
`URIVariableValue` decoding entirely. Duplicate ordered-association keys
continue to use `URIVariableValue.AssociationError` at the throwing public
construction boundary.

The enum case names, their raw string values, and UTF-8 range semantics are the
stable API-05 contract. Adding a future semantic category is an API evolution
event and must update the contract, public tests, changelog, and this record.
API-06 removed the surrounding `URIVariableValue.Codable` surface and did not
reintroduce this generic error.

## Validation contract

The implementation is guarded by:

- public-only probes for every semantic category and representative failure;
- exact UTF-8 ranges before and after multibyte source scalars;
- direct parsing and Codable parity, including nested coding paths;
- typed `Error` and bridged `NSError` recovery plus payload-redaction checks;
- the external consumer package;
- a symbol-graph contract requiring `ParseError` and `Kind`, forbidding
  `ParseError.underlyingError`, and requiring `DataValidationError` to remain
  absent; and
- the full pinned RFC 6570 and regression suites to prevent the diagnostic
  scanner from changing the accepted grammar.

## Approval record

After reviewing the recommendation, consumer research, compatibility impact,
privacy boundary, range semantics, taxonomy, Codable behavior, and
`DataValidationError` disposition, the repository maintainer explicitly
approved this contract on July 27, 2026.
