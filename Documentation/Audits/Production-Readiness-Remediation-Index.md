# Production-Readiness Remediation Index

This document is the durable navigation index for the production-readiness
program created from the 2026-07-25 due-diligence audit of HDXLURITemplate.

The current program comprises **seven epics and 43 leaf tickets**: the original
GitHub issues [#5](https://github.com/plx/hdxl-uri-template/issues/5) through
[#53](https://github.com/plx/hdxl-uri-template/issues/53), plus later finding
[#55](https://github.com/plx/hdxl-uri-template/issues/55). Each leaf has a
stable backlog identifier, such as `CONF-05` or `API-02`, in addition to its
GitHub issue number. The stable identifier should continue to be used in
remediation notes, audit evidence, and release traceability even if an issue is
transferred or superseded.

The companion documents that define the program's evidence, execution, and
final gate are:

- [Pre-release due-diligence audit](./2026-07-25-pre-release-due-diligence.md)
- [Production-readiness remediation execution goal](./Production-Readiness-Remediation-Goal.md)
- [Post-remediation production-readiness audit playbook](./Post-Remediation-Production-Readiness-Audit.md)

## Source of truth

GitHub's native sub-issue hierarchy and blocked-by/blocking relationships are
authoritative for current membership, state, and scheduling. Issue bodies
explain the local rationale, expected implementation, regression tests, and
acceptance criteria. This index is a committed snapshot that makes the overall
program legible without relying on one web view; it does not override a later
intentional change to a native GitHub relationship.

When this document, an issue body, and a native relationship disagree:

1. verify that the GitHub relationship was changed intentionally;
2. treat the native relationship as controlling the work queue;
3. update this index and affected issue bodies in the same maintenance change;
4. preserve the stable backlog identifier when replacing or superseding an
   issue.

Epics organize work but are not prerequisites of their children. An epic is
complete when its exit criteria and native sub-issues are complete. The
top-level program is complete only after the independent audit has produced an
acceptable verdict for an immutable release-candidate commit.

## Settled scope and product decisions

The following decisions are inputs to the remediation program, not questions
for individual implementation tickets to reopen:

- The supported toolchain baseline is Swift tools version 6.3 with Swift
  language mode 6.
- Supported deployment targets are Apple operating-system versions 26 and
  later for the platforms declared in `Package.swift`.
- Older Apple releases, older Swift toolchains, and non-Apple platforms are
  intentionally out of scope. The CI matrix should remain deliberately small.
- Public `Comparable` conformances on `URITemplate`, `URIVariableValue`, and
  `URIVariableValueType` will be removed.
- `URITemplate.Codable` will encode a validated semantic template string and
  decode through the parser. The private parsed AST is not a public persistence
  format.
- A separate opaque, disposable compiled cache will be designed only if
  `API-03` demonstrates a material benefit. A negative benchmark result is a
  successful resolution.
- Initial publication will use a `0.x` version. A stable `1.0` waits for the
  public contracts and production-readiness gates to settle.
- No release may be represented as production-suitable merely because all
  implementation tickets are closed. `AUDIT-01` must execute the committed
  audit playbook against the exact candidate commit.

The `URIVariableValue` Codable schema, structured diagnostic contract, and
Objective-C support policy remain explicit decision tickets. Their possible
outcomes are bounded by the issue acceptance criteria rather than assumed in
this index.

## Label taxonomy and application rules

The prefixed labels below are the program taxonomy installed in GitHub. The
repository's unprefixed default labels are not substitutes for these semantic
axes.

Every issue in this program should have:

- exactly one `priority:*` label;
- exactly one `type:*` label;
- at least one `domain:*` label describing why the work matters;
- at least one `component:*` label describing where the work lands.

Use multiple domain or component labels only when the acceptance criteria
genuinely span those areas. Do not encode state or dependency order in labels;
use issue state and native relationships.

### Priority

| Label | Meaning | Color |
| --- | --- | --- |
| `priority:P0` | Release blocker; address before any production-oriented preview | `#B60205` |
| `priority:P1` | High priority; required before production evaluation | `#D93F0B` |
| `priority:P2` | Medium priority; required before a stable 1.0 release | `#FBCA04` |
| `priority:P3` | Low-priority hardening or polish | `#FEF2C0` |

Priority is a release-policy classification, not a substitute for dependencies.
Among currently unblocked issues, address P0 before P1, P1 before P2, and P2
before P3 unless batching work prevents avoidable churn.

### Type

| Label | Meaning | Color |
| --- | --- | --- |
| `type:bug` | Confirmed incorrect or unsafe behavior | `#D73A4A` |
| `type:epic` | Tracking issue that organizes a coherent remediation workstream | `#5319E7` |
| `type:task` | Concrete implementation, testing, documentation, or release task | `#1D76DB` |
| `type:decision` | Requires an explicit supported-contract or design decision | `#A371F7` |
| `type:research` | Measurement or investigation needed before choosing an implementation | `#C5DEF5` |

Decision and research issues are complete only when their evidence and
conclusion are committed or otherwise durably recorded. They need not produce a
feature implementation.

### Domain

| Label | Meaning | Color |
| --- | --- | --- |
| `domain:correctness` | RFC semantics, parsing, expansion, or invariant correctness | `#E11D21` |
| `domain:testing` | Test corpus, harnesses, coverage, fuzzing, or validation | `#0E8A16` |
| `domain:performance` | Runtime, allocation, scaling, or benchmark work | `#F9D0C4` |
| `domain:robustness` | Malformed input, traps, invariant preservation, or resilience | `#F97316` |
| `domain:security` | Security, privacy, hostile input, or supply-chain concern | `#B60205` |
| `domain:api` | Public Swift or Objective-C contract and ergonomics | `#0052CC` |
| `domain:architecture` | Internal design, ownership, concurrency, or maintainability | `#7057FF` |
| `domain:documentation` | User, contributor, security, or API documentation | `#0075CA` |
| `domain:release` | Packaging, CI, versioning, and release readiness | `#006B75` |
| `domain:legal` | Licensing, attribution, provenance, or ownership diligence | `#D4C5F9` |

### Component

| Label | Meaning | Color |
| --- | --- | --- |
| `component:expansion` | URI-template evaluation, escaping, and expansion | `#FAD8C7` |
| `component:parser` | URI-template parsing and grammar validation | `#C2E0C6` |
| `component:serialization` | Codable, archives, and cached representations | `#D4C5F9` |
| `component:values` | Variable value model and association/list/text behavior | `#FEF2C0` |
| `component:errors` | Error types, diagnostics, privacy, and bridging | `#F9D0C4` |
| `component:objc` | Objective-C wrappers and generated interface | `#C5DEF5` |
| `component:storage` | `URITemplate` storage, caching, locks, and value semantics | `#BFDADC` |
| `component:test-suite` | Specification fixtures and automated test harnesses | `#BFD4F2` |
| `component:tooling` | Build modes, formatters, scripts, and developer tooling | `#DDEBFF` |
| `component:docs` | README, DocC, policies, audit documents, and guides | `#E6E6E6` |
| `component:package` | Swift package manifest, supported platforms, and products | `#C5DEF5` |
| `component:ci` | GitHub Actions and automated quality gates | `#DDEBFF` |

## Epic inventory

| Issue | Epic | Scope |
| --- | --- | --- |
| [#5](https://github.com/plx/hdxl-uri-template/issues/5) | Bring HDXLURITemplate to production readiness | Top-level program; owns the six topic epics and `AUDIT-01` |
| [#6](https://github.com/plx/hdxl-uri-template/issues/6) | Complete RFC 6570 conformance and shared-suite coverage | `CONF-01` through `CONF-12` |
| [#7](https://github.com/plx/hdxl-uri-template/issues/7) | Harden security, robustness, and adversarial performance | `HARD-01` through `HARD-03` |
| [#8](https://github.com/plx/hdxl-uri-template/issues/8) | Stabilize the public API, serialization, and Objective-C contract | `API-01` through `API-09` |
| [#9](https://github.com/plx/hdxl-uri-template/issues/9) | Simplify internal architecture and maintainability | `ARCH-01` through `ARCH-04` |
| [#10](https://github.com/plx/hdxl-uri-template/issues/10) | Establish continuous verification and repository quality gates | `QA-01` through `QA-06` and `WORKFLOW-01` |
| [#11](https://github.com/plx/hdxl-uri-template/issues/11) | Finish open-source packaging, documentation, and provenance | `PKG-01` and `DOC-01` through `DOC-06` |

## Leaf-ticket inventory

### RFC conformance

| ID | Issue | Priority/type |
| --- | --- | --- |
| `CONF-01` | [#12 — Pin and restore the complete upstream uritemplate-test corpus](https://github.com/plx/hdxl-uri-template/issues/12) | P0 task |
| `CONF-02` | [#13 — Execute all four shared suites with correct positive and negative semantics](https://github.com/plx/hdxl-uri-template/issues/13) | P0 task |
| `CONF-03` | [#18 — Correct literal grammar for apostrophe and tilde](https://github.com/plx/hdxl-uri-template/issues/18) | P0 bug |
| `CONF-04` | [#25 — Percent-encode non-URI Unicode in literal components](https://github.com/plx/hdxl-uri-template/issues/25) | P0 bug |
| `CONF-05` | [#26 — Correct reserved expansion's sub-delimiter character set](https://github.com/plx/hdxl-uri-template/issues/26) | P0 bug |
| `CONF-06` | [#27 — Reject whitespace and empty variable specifications in expressions](https://github.com/plx/hdxl-uri-template/issues/27) | P0 bug |
| `CONF-07` | [#32 — Guarantee exact, valid template-source representation](https://github.com/plx/hdxl-uri-template/issues/32) | P0 bug |
| `CONF-08` | [#29 — Enforce prefix-modifier ABNF lexically](https://github.com/plx/hdxl-uri-template/issues/29) | P0 bug |
| `CONF-09` | [#33 — Fail expansion when a prefix modifier is applied to a composite value](https://github.com/plx/hdxl-uri-template/issues/33) | P0 bug |
| `CONF-10` | [#34 — Count decoded Unicode characters without splitting percent-encoded sequences](https://github.com/plx/hdxl-uri-template/issues/34) | P0 bug |
| `CONF-11` | [#35 — Enforce zero known shared-suite failures](https://github.com/plx/hdxl-uri-template/issues/35) | P0 task |
| `CONF-12` | [#55 — Bootstrap fail-closed known-failure accounting before fixture activation](https://github.com/plx/hdxl-uri-template/issues/55) | P0 task |

### Security, robustness, and performance

| ID | Issue | Priority/type |
| --- | --- | --- |
| `HARD-01` | [#19 — Replace quadratic percent-escape scanning with a linear implementation](https://github.com/plx/hdxl-uri-template/issues/19) | P0 bug |
| `HARD-02` | [#28 — Enforce association invariants without public-input traps](https://github.com/plx/hdxl-uri-template/issues/28) | P0 bug |
| `HARD-03` | [#30 — Redact sensitive template values from default errors](https://github.com/plx/hdxl-uri-template/issues/30) | P1 bug |

### Public API, persistence, and Objective-C

| ID | Issue | Priority/type |
| --- | --- | --- |
| `API-01` | [#45 — Remove inappropriate public Comparable conformances](https://github.com/plx/hdxl-uri-template/issues/45) | P1 task |
| `API-02` | [#46 — Encode URITemplate as a semantic validated template string](https://github.com/plx/hdxl-uri-template/issues/46) | P0 bug |
| `API-03` | [#47 — Benchmark reparsing vs semantic decoding and prototype compiled-cache decoding](https://github.com/plx/hdxl-uri-template/issues/47) | P2 research |
| `API-04` | [#48 — Fix public LocalizedError conformance](https://github.com/plx/hdxl-uri-template/issues/48) | P1 bug |
| `API-05` | [#49 — Define structured public parse and validation diagnostics](https://github.com/plx/hdxl-uri-template/issues/49) | P1 decision |
| `API-06` | [#50 — Define the URIVariableValue Codable contract](https://github.com/plx/hdxl-uri-template/issues/50) | P1 decision |
| `API-07` | [#51 — Add read-only Swift payload inspection for variable values](https://github.com/plx/hdxl-uri-template/issues/51) | P2 task |
| `API-08` | [#52 — Decide and document the Objective-C support policy](https://github.com/plx/hdxl-uri-template/issues/52) | P1 decision |
| `API-09` | [#53 — Complete safe Objective-C parsing, evaluation, and error APIs if retained](https://github.com/plx/hdxl-uri-template/issues/53) | P1 task |

### Architecture and maintainability

| ID | Issue | Priority/type |
| --- | --- | --- |
| `ARCH-01` | [#31 — Replace mutable locked COW storage with immutable parsed storage](https://github.com/plx/hdxl-uri-template/issues/31) | P2 task |
| `ARCH-02` | [#36 — Audit and reduce @inlinable/@usableFromInline exposure](https://github.com/plx/hdxl-uri-template/issues/36) | P2 task |
| `ARCH-03` | [#37 — Remove unreachable expansion error types and simplify throwing boundaries](https://github.com/plx/hdxl-uri-template/issues/37) | P2 task |
| `ARCH-04` | [#38 — Correct or remove the unused RFC ucschar table](https://github.com/plx/hdxl-uri-template/issues/38) | P3 bug |

### Continuous verification and repository quality

| ID | Issue | Priority/type |
| --- | --- | --- |
| `QA-01` | [#14 — Repair and continuously compile the HEAVY_DEBUG configuration](https://github.com/plx/hdxl-uri-template/issues/14) | P1 bug |
| `QA-02` | [#20 — Add a deliberately small Swift 6.3 and Apple OS 26 CI gate](https://github.com/plx/hdxl-uri-template/issues/20) | P0 task |
| `QA-03` | [#21 — Add recurring sanitizer, fuzz, concurrency, and performance regression jobs](https://github.com/plx/hdxl-uri-template/issues/21) | P1 task |
| `QA-04` | [#22 — Add real public Swift and Objective-C consumer fixtures](https://github.com/plx/hdxl-uri-template/issues/22) | P1 task |
| `QA-05` | [#23 — Eliminate test-resource warnings and excessive parameterized-test output](https://github.com/plx/hdxl-uri-template/issues/23) | P2 task |
| `QA-06` | [#24 — Adopt and enforce a repository Swift formatting policy](https://github.com/plx/hdxl-uri-template/issues/24) | P3 task |
| `WORKFLOW-01` | [#16 — Harden GitHub Actions permissions and pin third-party actions immutably](https://github.com/plx/hdxl-uri-template/issues/16) | P1 task |

### Packaging, documentation, provenance, and final audit

| ID | Issue | Priority/type |
| --- | --- | --- |
| `PKG-01` | [#15 — Adopt Swift tools 6.3 and document the intentional Apple OS 26+ floor](https://github.com/plx/hdxl-uri-template/issues/15) | P0 task |
| `DOC-01` | [#39 — Replace the placeholder README with production-oriented user documentation](https://github.com/plx/hdxl-uri-template/issues/39) | P0 task |
| `DOC-02` | [#40 — Add DocC and complete supported public-symbol documentation](https://github.com/plx/hdxl-uri-template/issues/40) | P2 task |
| `DOC-03` | [#41 — Add contribution, security, changelog, and release-process documentation](https://github.com/plx/hdxl-uri-template/issues/41) | P1 task |
| `DOC-04` | [#42 — Add third-party notices and standards-derived-code attribution](https://github.com/plx/hdxl-uri-template/issues/42) | P0 task |
| `DOC-05` | [#17 — Confirm publication rights and provenance for the recreated implementation](https://github.com/plx/hdxl-uri-template/issues/17) | P0 decision |
| `DOC-06` | [#43 — Prepare the first 0.x release candidate and compatibility policy](https://github.com/plx/hdxl-uri-template/issues/43) | P0 task |
| `AUDIT-01` | [#44 — Execute the independent post-remediation production-readiness audit](https://github.com/plx/hdxl-uri-template/issues/44) | P0 task |

## Dependency-respecting burn-down

The phases below are dependency-safe cohorts, not replacements for GitHub's
native graph. Work within a phase can proceed in parallel when native
relationships permit it. Within the unblocked set, priority order still
applies.

### Phase 0: settle unblocked foundations

Start with work that defines the supported environment, validation boundaries,
and early policy decisions:

- `CONF-12` adds strict, issue-linked accounting for the two positive cases
  that become active when the exact fixture snapshot lands. It blocks
  `CONF-01`, changes no production behavior, and is temporary scaffolding for
  the complete `CONF-02` ledger.
- `CONF-01` pins the test oracle after `CONF-12` makes fixture activation
  fail-closed and independently mergeable.
- `QA-01` repairs heavy-debug compilation.
- `PKG-01` establishes Swift 6.3 and the Apple 26 floor.
- `WORKFLOW-01` hardens existing automation.
- `DOC-05` records a public-safe publication-rights decision.
- `HARD-02` establishes nontrapping association invariants.
- `API-01` removes accidental comparison contracts.
- `API-04` fixes Swift/Foundation error bridging.
- `API-08` decides whether Objective-C remains supported.
- `ARCH-04` is independent and may be completed here, although its P3 priority
  permits deferral behind higher-priority unblocked work.

### Phase 1: establish the oracle and primary gate

- Land `CONF-02` after `CONF-01`, adopting and extending `CONF-12`'s temporary
  adapter into the exact nine-case complete-corpus ledger.
- Land `QA-02` after `CONF-02`, `QA-01`, and `PKG-01` so the first required CI
  workflow is green and protects the complete corpus.
- Complete `QA-05` and `DOC-04` after the pinned fixture set is authoritative.

The temporary known-failure ledger in `CONF-02` is scaffolding, not a
conformance claim.

### Phase 2: fix observable correctness and hostile-input behavior

After the complete runner exists, correct the independent parser and expansion
defects in parallel:

- `CONF-03`, `CONF-05`, `CONF-06`, `CONF-08`, and `CONF-09`;
- `HARD-01`, followed by `CONF-10`;
- `CONF-04` after `CONF-03`;
- `HARD-03` after `API-04`;
- `CONF-07` after `CONF-03`, `CONF-06`, and `CONF-08`.

Close this phase with `CONF-11`, which removes every temporary known-failure
entry and requires the complete pinned corpus to pass without exclusions.

### Phase 3: settle public contracts and persistence

- Implement `API-02` against the strict, authoritative template source.
- Resolve `API-05` after `API-04` and the strict parser work establish the
  supported error categories and locations.
- Resolve `API-06` after `HARD-02` and `API-05` establish the invariant and
  diagnostic boundaries that its decoding contract must use.
- Implement `API-07` against the final association and value-Codable model.
- Run `API-03` only after semantic Codable and the corrected parser are stable.
- Follow the Objective-C branch described below for `API-08`, `API-09`, and
  `QA-04`.

Do not introduce a compiled-cache API as part of semantic Codable. If `API-03`
finds a material benefit, create a separately reviewed design ticket.

### Phase 4: simplify internals against stable behavior

- Complete `ARCH-01` after `API-01`, `API-02`, and `CONF-11`.
- Complete `ARCH-02` against the final immutable storage shape.
- Complete `ARCH-03` after `CONF-09` and `API-04` have established the real
  throwing boundary.
- Ensure `ARCH-04` is closed before the architecture epic exits.

Run conformance, public-consumer, concurrency, and performance checks through
these refactors. Architectural cleanup must not redefine settled behavior.

### Phase 5: make verification and documentation durable

- Add `QA-03` after `QA-02`, `HARD-01`, and `HARD-02`.
- Complete `QA-04` after the primary CI gate and Objective-C decision; require
  the retained facade first if Objective-C remains supported.
- Schedule `QA-06` after the largest API/architecture rewrites to avoid mass
  formatting conflicts.
- Complete `DOC-01` after conformance, safe diagnostics, package metadata,
  semantic Codable, public errors, and Objective-C policy are final.
- Complete `DOC-02` against the final public API and real consumer examples.
- Complete `DOC-03` after CI and workflow hardening so documented processes
  match reality.

### Phase 6: prepare an immutable candidate

Use `DOC-06` to choose the initial `0.x` version, identify an immutable
candidate commit, prepare release notes, and assemble evidence. All native
prerequisites must be closed or explicitly dispositioned as accepted residual
risk. Do not publish a tag or release at this stage.

### Phase 7: audit, then decide

Execute `AUDIT-01` against the exact candidate commit using the
[post-remediation playbook](./Post-Remediation-Production-Readiness-Audit.md).
The audit must not fix the candidate in place. A failed gate produces a linked
remediation issue and a new candidate followed by a fresh audit.

Close the top-level epic only when the audit verdict supports the maturity claim
the release will make.

## Conditional Objective-C branch

`API-08` is the policy fork. It must be resolved early enough that consumer
tests and documentation do not target a half-supported facade.

If Objective-C support is retained:

- `API-09` must provide safe parsing, expansion, and error APIs, including the
  applicable Codable/secure-coding and association decisions;
- `QA-04` must compile and run a real `.m` consumer rather than testing wrappers
  only from Swift;
- `DOC-01` and `DOC-02` must document the supported facade and its error,
  nullability, and archive behavior;
- `AUDIT-01` must exercise the generated Objective-C interface and actual
  consumer.

If Objective-C support is removed:

- close `API-09` using the native not-planned/superseded disposition and link
  the removal decision;
- remove the wrappers, misleading support claims, and Objective-C-specific
  archive surface before the public contract is declared;
- keep `QA-04` as a public Swift consumer fixture and mark only the `.m`
  portion not applicable with a link to `API-08`;
- make `DOC-01`, `DOC-02`, and `AUDIT-01` state explicitly that Objective-C is
  unsupported.

In either branch, `HARD-02` remains required because the Swift value model must
preserve its own association invariants.

## Issue and pull-request conventions

### Issues

- Keep one independently verifiable outcome per leaf issue.
- Preserve the stable backlog identifier in the issue body and use it in audit
  traceability.
- Keep audit evidence, required behavior, implementation guidance, pre-fix
  regression expectations, acceptance criteria, dependencies, and out-of-scope
  boundaries in the issue.
- Update native sub-issue and dependency relationships whenever scope changes.
  Updating prose alone is insufficient.
- Use `type:decision` and `type:research` for evidence-producing work. Record
  the conclusion durably and open a separate implementation issue when the
  conclusion requires new work not already represented.
- Do not close an issue because one symptom disappeared. Close it only after
  every acceptance criterion is satisfied or explicitly dispositioned by the
  maintainer.

### Pull requests

- Prefer one leaf issue per pull request. Combine issues only when their changes
  cannot be reviewed or validated independently, and explain the exception.
- Include the stable ID in the title, for example
  `CONF-05: Correct reserved expansion character handling`.
- Use `Closes #<issue>` only when the pull request satisfies the complete issue.
  Use a non-closing reference for partial or preparatory work.
- Name prerequisite issues and confirm their native dependencies are closed.
  A blocked change may be opened as a draft, but should not merge against an
  unsettled contract.
- For behavior fixes, include a focused regression that demonstrably fails
  against the pre-fix revision and passes with the change. Record the pre-fix
  command/output in the pull-request body when a deliberately failing commit
  is not retained.
- For crashes and performance defects, include the safe standalone reproducer
  or baseline measurement plus permanent post-fix regression coverage.
- Do not edit an upstream conformance fixture to make an implementation change
  green. Fixture updates and provenance changes belong in separately reviewable
  work.
- Report exact validation commands and outcomes, including relevant debug,
  release, heavy-debug, sanitizer, consumer, or benchmark runs.
- Keep formatting-only changes separate from behavioral changes unless the
  formatter touches only the edited lines.
- Update public documentation and release notes in the owning documentation
  ticket rather than making inconsistent piecemeal promises.
- After merge, verify automatic issue closure and native dependency unblocking.
  Update the relevant epic only when its exit criteria, not merely its child
  count, are satisfied.

## Program completion

Issue closure is necessary but not sufficient. The release decision requires:

1. all six topic epics to meet their exit criteria;
2. `DOC-06` to identify an immutable release candidate and evidence bundle;
3. `AUDIT-01` to execute the committed playbook against that candidate;
4. every residual risk to have an explicit owner and disposition; and
5. the final verdict to support the exact production-readiness claim made in
   the README and release notes.

If the audit returns no-go, reopen the program through new linked leaf issues,
produce a new candidate, and repeat the audit. Do not reinterpret a failed gate
as documentation-only debt.
