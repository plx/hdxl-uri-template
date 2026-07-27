# HDXLURITemplate

HDXLURITemplate parses and expands
[RFC 6570 URI Templates](https://www.rfc-editor.org/rfc/rfc6570.html) in Swift.
It provides native Swift value types for validated templates and their
undefined, text, list, and ordered-association variables.

## Status

This package is pre-release. The complete pinned RFC 6570 corpus passes, but
the production-readiness program, candidate preparation, and independent
final audit are still in progress. The repository has no
published release tag, so it does not yet make a production-suitability or
source-stability promise.

Use the mutable `master` branch only for evaluation. Production adopters should
wait for a versioned release and review the
[open readiness work](Documentation/Audits/Production-Readiness-Remediation-Index.md)
against their own requirements.

## Security boundaries

HDXLURITemplate expands strings. It does not fetch a URI, open a connection,
authorize a request, or decide whether a rendered destination is safe.

Treat templates and values from outside your trust boundary as untrusted:

- Reserved (`{+value}`) and fragment (`{#value}`) expansion deliberately
  preserve URI delimiters such as `/`, `?`, and `#`. Untrusted values can
  therefore change the structure or interpretation of the rendered URI.
- `evaluate(parameters:)` checks only whether Foundation can construct a
  `URL`. It does not require an absolute URL or an approved scheme, host, port,
  path, or destination. Validate those components against an application-owned
  allowlist before using the result.
- Parsing and expansion accept caller-sized input and can produce output
  proportional to the supplied strings and collections. Apply
  application-specific limits to template length, variable count, value
  length, collection size, and rendered-output length.
- Prefer simple expansion (`{value}`) when reserved delimiters should be
  percent-encoded. Use reserved or fragment expansion only when preserving
  delimiters is intentional.

Parse and evaluation errors have bounded, payload-free default descriptions.
Their explicit recovery properties—including `ParseError.template` and
`EvaluationError.template`, `parameters`, `underlyingError`, and
`failingVariableName`—can contain sensitive data. Descriptions of
`URITemplate` and `URIVariableValue`, and raw `Mirror` inspection, can also
expose source or values. Do not log that recovery context without an
application-specific privacy policy. Use `ParseError.kind` and
`EvaluationError.kind` for payload-free categories.

Report suspected vulnerabilities through the repository's
[private vulnerability-reporting form](https://github.com/plx/hdxl-uri-template/security/advisories),
not through a public issue. Never include secrets, personal data, or private
production URIs; use synthetic values. The complete response and disclosure
process is in [SECURITY.md](SECURITY.md).

## Supported environments

The package declares Swift tools version 6.3 and Swift language mode 6. It
supports iOS 26 or later, macOS 26 or later, tvOS 26 or later, watchOS 26 or
later, visionOS 26 or later, and Mac Catalyst 26 or later.

Older Swift toolchains, older Apple OS releases, and non-Apple platforms,
including Linux, are intentionally unsupported.

## Installation

Until a versioned release exists, an evaluation package can depend on the
mutable `master` branch:

```swift
// swift-tools-version: 6.3

import PackageDescription

let package = Package(
  name: "URITemplateExample",
  platforms: [
    .macOS(.v26)
  ],
  dependencies: [
    .package(
      url: "https://github.com/plx/hdxl-uri-template.git",
      branch: "master"
    )
  ],
  targets: [
    .executableTarget(
      name: "URITemplateExample",
      dependencies: [
        .product(
          name: "HDXLURITemplate",
          package: "hdxl-uri-template"
        )
      ]
    )
  ]
)
```

A branch dependency is mutable and is not a reproducible production pin.
Replace it with the supported version requirement documented by the first
release.

## Quick start

Parse once, expand to a string, and convert to a Foundation `URL` only when a
`URL` is actually required:

```swift
import Foundation
import HDXLURITemplate

func readmeQuickStart() throws {
  let template = try URITemplate(
    parsing: "https://api.example.com{/version}/users/{id}{?query}"
  )
  let parameters: [String: URIVariableValue] = [
    "version": .text("v1"),
    "id": .text("42"),
    "query": .text("swift uri templates"),
  ]

  let rendered = try template.evaluateAsString(parameters: parameters)
  precondition(
    rendered
      == "https://api.example.com/v1/users/42?query=swift%20uri%20templates"
  )

  let url = try template.evaluate(parameters: parameters)
  precondition(url.absoluteString == rendered)
}
```

Place the function in an executable target and call `try readmeQuickStart()`
from that target's entry point.

`URITemplate.init(parsing:)` validates and retains the exact source in
`templateRepresentation`. `variableNames` reports the distinct variables used
by the parsed template.

## Variable values

Every parameter is a `URIVariableValue` with one of four flavors:

- `.undefined` omits the variable according to the active operator.
- `.text(_:)` holds one string.
- `.list(_:)` holds an ordered sequence of strings.
- `.association(_:)` holds ordered, unique string pairs.

The sequence association factory preserves the supplied order and throws
`URIVariableValue.AssociationError` for a duplicate key. The dictionary
factory is nonthrowing and orders keys in ascending lexical order by default.

```swift
import Foundation
import HDXLURITemplate

func readmeVariableValues() throws {
  let orderedFilters = try URIVariableValue.association([
    ("sort", "updated"),
    ("limit", "20"),
  ])
  let parameters: [String: URIVariableValue] = [
    "absent": .undefined,
    "title": .text("URI Templates"),
    "segments": .list(["users", "42"]),
    "filters": orderedFilters,
  ]
  let template = try URITemplate(
    parsing: "https://example.com{/segments*}{?absent,title,filters*}"
  )

  let rendered = try template.evaluateAsString(parameters: parameters)
  precondition(
    rendered
      == "https://example.com/users/42"
      + "?title=URI%20Templates&sort=updated&limit=20"
  )
  precondition(parameters["absent"]?.isUndefined == true)
  precondition(parameters["absent"]?.textValue == nil)
  precondition(parameters["title"]?.textValue == "URI Templates")

  var segments = parameters["segments"]?.listValue
  precondition(segments == ["users", "42"])
  segments?.append("local-only")
  precondition(parameters["segments"]?.listValue == ["users", "42"])

  let filters = orderedFilters.associationValue
  precondition(filters?.map(\.key) == ["sort", "limit"])
  precondition(filters?.map(\.value) == ["updated", "20"])
}
```

Use `valueType` to distinguish all four flavors exhaustively. `textValue`,
`listValue`, and `associationValue` recover the matching payload as ordinary
Swift values and return `nil` for every mismatch. Empty payloads return
non-`nil` empty values. Returned arrays are independent values, so mutating
them cannot change the original `URIVariableValue` or its association
invariants.

## Operators and modifiers

The package implements all RFC 6570 expression operators:

| Form | Name | Example for text `a/b` |
| --- | --- | --- |
| `{value}` | Simple | `a%2Fb` |
| `{+value}` | Reserved | `a/b` |
| `{#value}` | Fragment | `#a/b` |
| `{.value}` | Label | `.a%2Fb` |
| `{/value}` | Path segment | `/a%2Fb` |
| `{;value}` | Path parameter | `;value=a%2Fb` |
| `{?value}` | Query | `?value=a%2Fb` |
| `{&value}` | Query continuation | `&value=a%2Fb` |

An explode modifier (`*`) expands list and association members separately.
For example, `{?items*}` with `["red", "green"]` becomes
`?items=red&items=green`, while an ordered association in `{?keys*}` becomes
one query pair per association entry in its stored order. Without `*`, a
composite value is joined according to the operator's RFC rules.

A prefix modifier (`:n`) limits a text value to its first `n` Unicode code
points: `{value:3}` expands `"abcdef"` as `abc`. A prefix modifier on a list or
association is invalid and throws an `EvaluationError` whose kind is
`.prefixModifierNotApplicable`.

## Error boundaries

The public API keeps three failure stages distinct:

1. `URITemplate.init(parsing:)` throws `URITemplate.ParseError` when source is
   not valid URI-template syntax. Its `kind` is a stable semantic category and
   its half-open `sourceRange` locates the failure in `template` using UTF-8
   byte offsets. A zero-length range is an insertion point.
2. `evaluateAsString(parameters:)` throws `URITemplate.EvaluationError` when a
   parsed expression cannot be expanded, such as a prefix modifier applied to
   a list or association.
3. `evaluate(parameters:)` first performs the same string expansion and then
   calls `URL(string:)`. If Foundation rejects the rendered string, it throws
   an `EvaluationError` whose `kind` is `.invalidURL`.

Successful string expansion is not proof that the result is an authorized,
absolute, or network-safe URL. Inspect `.kind` for a payload-free category and
access the retained recovery context only when the application needs it.
The complete parse-diagnostic and decoding contract is recorded in
[API-05](Documentation/Decisions/API-05-Structured-Parse-Diagnostics.md).

## RFC 6570 conformance

The implemented feature surface is RFC 6570 Level 4: every operator, list and
association expansion, explode modifier, and prefix modifier is active.

Conformance is tied to the byte-faithful
[`uri-templates/uritemplate-test` snapshot](Tests/HDXLURITemplateTests/Resources/README.md)
at upstream commit
[`4171dac22aa67fc710b3f6df308a50bd08552986`](https://github.com/uri-templates/uritemplate-test/commit/4171dac22aa67fc710b3f6df308a50bd08552986).
The unified gate passes all 270 pinned cases: 234 positive examples and 36
controlled negative outcomes, with no skip, quarantine, or expected-failure
exception. The complete
[conformance evidence](Documentation/Audits/Evidence/2026-07-26-epic-6-completion.md)
records the fixture hashes, individual remediation gates, and required hosted
CI runs.

The normative target is RFC 6570 plus verified RFC errata. The current
implementation applies
[verified erratum 6937](https://www.rfc-editor.org/errata/eid6937) for the
apostrophe literal rule. A future verified erratum or shared-suite revision
requires explicit review, a new immutable fixture pin, refreshed provenance
and hashes, and a complete green gate before this conformance statement
changes.

## Thread safety and performance

`URITemplate`, `URIVariableValue`, and `URIVariableValueType` conform to
`Sendable`. The public template API is immutable and supports concurrent
reads. The initial audit passed the complete suite under Thread Sanitizer and a
targeted 100,000-operation shared-template stress probe without a detected race
or result mismatch. That is measured evidence, not a universal proof. The
[recurring hardening gate](Documentation/Hardening/QA-03-Recurring-Hardening.md)
runs separate sanitizers, deterministic fuzz, shared-template concurrency, and
Release scaling weekly and for exact candidate SHAs; the independent final
audit remains a separate release gate.

The accepted Xcode 26.6 / Swift 6.3.3 benchmark on an Apple M4 Max measured
direct parsing of a balanced 1,000-template corpus at a median 4.907 ms in a
warm process and 6.546 ms in a fresh child. At 10,000 templates, the medians
were 49.201 ms and 54.900 ms. These are machine-specific Release measurements,
not cross-machine latency guarantees. See the
[benchmark report](Documentation/Benchmarks/API-03-Compiled-Cache-Benchmark.md)
and [raw evidence](Documentation/Benchmarks/Data/API-03/README.md).

Runtime and allocation scale with the template, supplied values, collection
sizes, and rendered output. Very large or percent-dense inputs deserve
application-level limits and workload-specific measurement. Parse once and
reuse a template when practical.

## Codable representation

`URITemplate` encodes as one string containing its exact, validated
`templateRepresentation`. Decoding reparses that string through
`URITemplate.init(parsing:)`, so decoded templates cross the same validation
boundary as directly parsed templates.

That semantic string is the entire supported template persistence format.
Private parser storage and derived syntax trees are not serialized. The
[compiled-cache decision](Documentation/Decisions/API-03-Compiled-Cache.md)
found no performance case for a cache, and no compiled cache ships in the
public product. Any future cache would require a separately reviewed,
versioned, disposable sidecar that retains the authoritative source.

`URIVariableValue` and `URIVariableValueType` deliberately do not conform to
`Codable`, `Encodable`, or `Decodable`. Their pre-release numeric-tagged
encoding exposed private storage and is unsupported. Applications that persist
parameters should own and version a source DTO, then construct runtime values
with `undefined`, `text(_:)`, `list(_:)`, and `association(_:)`. The read-only
payload accessors are runtime inspection APIs, not a persistence format or
compatibility promise. See the
[API-06 decision](Documentation/Decisions/API-06-URIVariableValue-Codable.md).

JSON permits a template string as a top-level value. Foundation property lists
do not permit a top-level string fragment, so encode a template inside an
array, dictionary, or keyed container when using `PropertyListEncoder`.

## Objective-C support

The initial `0.x` contract is Swift-only. Importing or using this package from
Objective-C is unsupported. The pre-release `HDXLURITemplate` and
`HDXLURIVariableValue` wrapper classes and the
`HDXLURIVariableValueType` Objective-C enum were removed before the first
supported release contract. Their selectors, binary interface, and
`NSCoding`/`NSSecureCoding` archives have no compatibility or migration
guarantee.

The
[support decision](Documentation/Decisions/API-08-Objective-C-Support.md) and
[removal contract](Documentation/Decisions/API-10-Objective-C-Removal.md)
record the rationale and final evidence. Objective-C applications should
provide an application-owned Swift boundary around the specific operations
they require.

## Build and test

Select an Xcode installation containing Apple Swift 6.3 through
`DEVELOPER_DIR`, then resolve, inspect, build, and test with that toolchain:

```sh
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
xcrun swift package resolve
xcrun swift package dump-package
xcrun swift build -c debug
xcrun swift test -c debug
xcrun swift build -c release
xcrun swift test -c release
```

The repository's `just` recipes use the same
`DEVELOPER_DIR`/`xcrun` selection. `just test-all` also verifies fixture
integrity, warning guards, and builds and runs a separate public consumer that
cannot access `internal` or `package` declarations. The consumer executes the
README and DocC examples from synchronized source files. The DocC gate treats
documentation diagnostics and unresolved links as errors and requires an
abstract for every supported public symbol and conceptual page.

Every pull request and `master` update runs the required
`Required Swift 6.3 / Apple 26 gate` from a clean checkout. Its Xcode 26.6 /
Swift 6.3.3 lanes run the complete suite in Debug, Release, and `HEAVY_DEBUG`;
the Debug lane also runs the public-consumer, API-boundary, and DocC checks.
A Release smoke job compiles for every declared Apple 26 platform.

## Project documentation

- [DocC documentation](Sources/HDXLURITemplate/HDXLURITemplate.docc/HDXLURITemplate.md)
  covers strict parsing, expansion choices, runtime values, operators and
  modifiers, structured diagnostics, persistence, concurrency, performance,
  input limits, and the Swift-only support boundary. The
  [public API contract](Documentation/API/README.md) describes the checked
  external-consumer, symbol-graph, documentation-coverage, and compiled-example
  boundaries.
- [CONTRIBUTING](CONTRIBUTING.md) defines the supported development workflow
  and pull-request requirements. [SECURITY](SECURITY.md) defines private
  reporting and response, and the [Code of Conduct](CODE_OF_CONDUCT.md)
  governs project spaces.
- [CHANGELOG](CHANGELOG.md) records project changes and the `0.x`
  compatibility policy. The
  [Release Checklist](Documentation/Release/Release-Checklist.md) and
  [Canary and Rollback Template](Documentation/Release/Canary-and-Rollback-Template.md)
  define evidence-based release and operational gates.
- Project-authored material is available under the [MIT License](LICENSE).
  Vendored fixtures and standards-derived Code Components have separate terms
  in [Third-party notices](THIRD_PARTY_NOTICES.md), reproduced licenses in
  [`LICENSES/`](LICENSES/), and a
  [fixture provenance ledger](Tests/HDXLURITemplateTests/Resources/README.md).
  The
  [publication-rights record](Documentation/Decisions/DOC-05-Publication-Rights.md)
  covers the private Objective-C origin and public Swift recreation.
- The
  [original pre-release audit](Documentation/Audits/2026-07-25-pre-release-due-diligence.md),
  [re-audit playbook](Documentation/Audits/Post-Remediation-Production-Readiness-Audit.md),
  [remediation goal](Documentation/Audits/Production-Readiness-Remediation-Goal.md),
  and
  [live remediation index](Documentation/Audits/Production-Readiness-Remediation-Index.md)
  define the evidence and remaining release gates.
