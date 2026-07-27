# API-08 Objective-C support decision

Status: final on July 26, 2026.

Approver: repository maintainer.

Tracking issue:
[#52](https://github.com/plx/hdxl-uri-template/issues/52).

## Decision

The initial `0.x` contract is Swift-only.

Objective-C import and use are unsupported. Remove the public
`HDXLURITemplate` and `HDXLURIVariableValue` wrappers, the Objective-C exposure
of `HDXLURIVariableValueType`, their wrapper-only coding and archive surfaces,
and their Objective-C-specific tests before the initial public contract is
declared.

The decision and its removal contract are complete. The final evidence below
records the implementation, validation, and authorized downstream disposition.

## Evidence reviewed

The decision considered the generated Xcode 26.6 / Swift 6.3.3 interface,
production wrappers, package targets, Swift and Objective-C tests, repository
history, compatibility implications, and the cost of both supported outcomes.

At decision time, the generated interface exposed three Objective-C symbols:

- `HDXLURITemplate`, with parsing, representation, variable-name, copying, and
  secure-coding operations;
- `HDXLURIVariableValue`, with value inspection, construction, association
  enumeration, copying, and secure-coding operations; and
- `HDXLURIVariableValueType`, as a closed `uint8_t` enum.

That surface is not a usable facade for the package's core operation:

- `HDXLURITemplate` has no expansion or evaluation API;
- `initWithURITemplate:` returns `nil` through `try?` and discards the parse
  failure;
- the dictionary initializer calls a comparator block `sortDescriptor:`;
- ordered associations lose their ordering when projected to `NSDictionary`;
- nullability and callback-pointer safety depend on Objective-C callers
  honoring the generated Swift bridge contract; and
- secure archives delegate to private Swift `Codable` schemas whose
  compatibility is not an intentional public contract.

The two wrapper source files contain 438 physical lines. Supporting them would
also require a permanent second public contract for selectors, nullability,
Foundation collections, `NSError`, copying, secure coding, archive migration,
and Swift/Clang agreement across future semantic changes.

The repository identifies no actual or committed Objective-C consumer. The
project's origin as a recreation of private Objective-C work is provenance, not
evidence of current demand.

A real `.m` test fixture existed during the decision review, so the earlier
absolute claim that there was no Objective-C caller was stale. The fixture
covered association construction, enumeration, ordering, copying, and
secure-coding round trips. It did not parse or expand a template and therefore
was not a real core-operation consumer. API-10 removed that fixture with the
unsupported facade.

## Rationale and tradeoff

Removing the incomplete facade before the first release produces one coherent,
fully usable Swift contract. It avoids implying support for a bridge that
cannot perform expansion and avoids freezing accidental selectors and archive
schemas.

Retaining the facade was a defensible alternative because the package was
Apple-only, its core Swift API was small, the wrapper code already existed, and
a SwiftPM Objective-C test target built. Retention would have become preferable
if a named current or committed consumer had required it. No such consumer or
compatibility horizon was identified.

Removal can inconvenience an unrecorded private Objective-C caller and can make
existing wrapper archives unreadable once the wrappers disappear. That cost is
accepted for the pre-release contract. The package does not promise migration
of wrapper objects or archives.

## Removal contract

Issue #81 was scoped to own one complete, reviewable removal:

- delete the two public wrapper classes;
- remove Objective-C exposure from the value-type enum while preserving the
  Swift enum if the Swift implementation still needs it;
- remove wrapper `NSCopying`, `NSCoding`, and `NSSecureCoding` behavior;
- remove the Objective-C interop package target, `.m` bridge fixture, and
  wrapper-double tests;
- preserve or migrate Swift association-invariant coverage;
- prove the wrapper symbols are absent from the generated interface after
  removal; and
- make README, DocC, package claims, tests, and audit scope agree that
  Objective-C is unsupported.

The removal issue was a native child of epic #8 and a native blocker of #52. It
was deliberately not blocked by then-open #52; the merged nonclosing decision
record was its contract prerequisite, and a reverse native dependency would
have created a cycle.

## Compatibility and migration

Removal is an intentional pre-1.0 source, binary, and wrapper-archive break.
No compatibility or archive-reading promise applies to
`HDXLURITemplate`, `HDXLURIVariableValue`, or their Objective-C selectors.

Swift clients should use `URITemplate` and `URIVariableValue` directly. An
Objective-C application that still needs URI-template behavior should put a
small application-owned Swift boundary around the exact operations it uses
rather than depending on this package to expose a general Objective-C facade.
Persist semantic template strings and application-owned value data instead of
wrapper archives.

## Final evidence

The Swift-only decision record merged in
[PR #82](https://github.com/plx/hdxl-uri-template/pull/82), with explicit
maintainer approval recorded below. Dedicated removal
[issue #81](https://github.com/plx/hdxl-uri-template/issues/81) closed through
[PR #85](https://github.com/plx/hdxl-uri-template/pull/85), merged as
`51f06ea3d2fcb6e9ec478d53fa49af3df92d587a`.

That removal:

- deleted both public wrapper classes, the Objective-C enum exposure, their
  wrapper-only coding and archive surfaces, the interop package target, the
  `.m` fixture, and wrapper-only tests;
- preserved the native Swift association invariants and their tests;
- made the README, CHANGELOG, DocC comments, package manifest, API inventory,
  tests, and audit documentation agree on a Swift-only contract;
- added a public-API validation gate that requires exactly the package and
  external-consumer generated Swift headers and rejects all three former
  Objective-C symbols in every header; and
- passed the full Debug, heavy Debug, and Release suites with both Xcode 26.6 /
  Swift 6.3.3 and Xcode 27 / Swift 6.4, plus hosted heavy-Debug and automated
  review checks on the exact merged head.

Conditional facade
[issue #53](https://github.com/plx/hdxl-uri-template/issues/53) then received
the approved implementation links and rationale and closed with GitHub's native
`not_planned` reason. Public-consumer
[issue #22](https://github.com/plx/hdxl-uri-template/issues/22) remains
mandatory for a real Swift consumer; its `.m` portion is not applicable under
this decision. Release-candidate and audit work must continue to state
explicitly that Objective-C is unsupported.

The API-08 acceptance criteria are therefore satisfied:

- the maintainer-approved decision is durable;
- README, DocC, package claims, tests, and issue dispositions agree;
- all wrapper source, tests, and support claims were deliberately removed; and
- no release describes Objective-C support.

## Reconsideration

Objective-C support may be reconsidered in a new proposal only when it names:

- a concrete current or committed consumer;
- its required parsing, expansion, value, error, and persistence operations;
- its deployment and toolchain matrix; and
- its source, binary, and archive-compatibility horizon.

A future adapter should normally be a separate product or package so that its
Foundation and Clang-facing compatibility contract does not become an
accidental property of the Swift core.

## Approval record

After reviewing the recommendation and its removal scope, the repository
maintainer explicitly approved the Swift-only removal path on July 26, 2026.
