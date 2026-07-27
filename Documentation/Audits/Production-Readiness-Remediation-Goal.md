# Production-Readiness Remediation Goal

## Copy-paste goal

After PR
[#54](https://github.com/plx/hdxl-uri-template/pull/54) has merged, start a
new Codex session from a clean, current `master` checkout and submit:

```text
/goal Complete the work in `Documentation/Audits/Production-Readiness-Remediation-Goal.md`.
```

This is an execution goal, not a request to edit or summarize this document.
The goal remains active until the terminal completion criteria below are met.
Do not mark it complete merely because every remaining issue has an open pull
request, every leaf implementation appears finished, or a release candidate
exists.

This runbook is structurally adapted from the
[Agentic Navigation Guide production-readiness goal](https://github.com/plx/agentic-navigation-guide/blob/main/audits/production-readiness-remediation-goal.md).
The repository, Swift, issue-graph, gate, and publication rules in this
document are the controlling project-specific version.

## Required outcome

Complete the production-readiness program rooted at
[#5](https://github.com/plx/hdxl-uri-template/issues/5), including every
current or subsequently discovered issue in its native sub-issue and dependency
universe.

Execute the program end to end as an ordered sequence of small, reviewable pull
requests:

- work on exactly one selected issue at a time;
- use intentional, shallow PR stacks when selected work truly requires an open
  prerequisite PR;
- keep independent work in separate stacks based on current `master`;
- merge every stack in dependency order;
- close every ordinary leaf and gate through its own merged PR, with only the
  documented conditional #53 `not_planned` exception;
- prepare one immutable `0.x` candidate through
  [#43](https://github.com/plx/hdxl-uri-template/issues/43);
- complete the independent audit in
  [#44](https://github.com/plx/hdxl-uri-template/issues/44); and
- close the top-level program only when the audit evidence supports an
  unconditional production-suitability verdict within the documented support
  boundary.

Do not broaden an issue merely because adjacent cleanup is convenient. The
program does not expand platform support, add URI dereferencing policy, or make
arbitrary expanded URIs safe for application use.

Actual publication is intentionally outside this goal. The current issue tree
prepares and audits a candidate but does not authorize a version tag, GitHub
Release, package-registry publication, Swift Package Index submission, or
public announcement. Those irreversible or externally visible actions require
a separate, explicit maintainer checkpoint and, when appropriate, a dedicated
publication issue.

## Scope and authority

Invoking this goal authorizes the normal repository and GitHub work needed to
complete the program:

- inspect and modify files in this repository;
- run local and GitHub-hosted validation;
- create issue-specific branches, commits, and draft PRs;
- update a PR in response to review or CI;
- create self-contained program issues for genuinely new findings;
- maintain required semantic labels, stable identifiers, native parents,
  blockers, and sub-issue relationships for new or changed program work;
- reopen a gate whose evidence has been invalidated, as described below;
- apply the narrowly defined `not_planned` disposition to conditional issue
  #53 only when the Objective-C removal branch below has fully satisfied its
  prerequisites;
- merge an ordinary remediation or evidence PR after every prerequisite,
  required review, and required check is satisfied; and
- delete a merged ticket branch when no descendant stack still needs it.

That authority does **not** permit:

- bypassing branch protection, required reviews, or required checks;
- force-merging, using administrator overrides, or weakening a gate merely to
  make progress;
- directly closing any program issue with the issue API, CLI, or UI, except
  for the narrowly authorized conditional #53 `not_planned` disposition;
- claiming a platform, toolchain, sanitizer, consumer, or performance result
  that was not actually run;
- inventing legal, employer-ownership, credential, protected-setting, or human
  approval evidence;
- exposing credentials or committing sensitive templates, values, URLs, or
  audit evidence;
- publishing a tag, GitHub Release, registry artifact, or external listing;
- changing the repository's private/public visibility;
- writing to a repository or service outside `plx/hdxl-uri-template`; or
- broadening the documented Swift 6.3 and Apple OS 26+ support contract.

Do not stop simply because the program spans many turns or context
compactions. Persist through ordinary implementation, CI, review, merge, and
stack maintenance. Stop and request user direction only at a defined approval
checkpoint or a genuine unresolved blocker.

## Preconditions

Before selecting the first remediation issue:

1. Confirm PR
   [#54](https://github.com/plx/hdxl-uri-template/pull/54) has merged into
   `master`. It installs the durable audit documents and program index. Do not
   build remediation branches on the unmerged audit branch.
2. Start from a clean checkout of current remote `master`. Preserve unrelated
   user changes and use a separate worktree when necessary.
3. Confirm:
   - `gh auth status`;
   - repository identity `plx/hdxl-uri-template`;
   - default branch `master`;
   - the current remote `master` SHA; and
   - sufficient write access for branches, PRs, issues, labels, and native
     relationships.
4. Read all required guidance listed below.
5. Recursively enumerate the native program graph rooted at #5, including:
   - topic epics #6 through #11;
   - every native child of those epics;
   - final audit issue #44;
   - every native blocked-by relationship; and
   - any later issue added to the program.
   As installed by PR #54, the sanity-check totals are seven epics, 42 leaf
   tickets, and 49 program issues. Recompute live state rather than treating
   those historical totals as a completion rule.
6. Confirm every program issue has exactly one `priority:*` label, exactly one
   `type:*` label, at least one `domain:*` label, and at least one
   `component:*` label. Confirm all leaf stable identifiers are present and
   unique.
7. Confirm the graph is acyclic and that the committed remediation index
   agrees with the live native relationships. Native GitHub relationships are
   authoritative, but unexplained drift is a defect to investigate, not a
   reason to silently rewrite the index.
8. Search open PRs for existing closing claims on program issues. Do not open
   a duplicate PR for already-claimed work. In particular, do not assume
   historical PR #1 belongs to this program merely because it remains open.
9. Record repository visibility, tags, and GitHub Releases. At the PR #54
   baseline the repository is private and has no tags or releases; changing
   those facts is outside this goal.

Use GitHub's current supported REST or GraphQL APIs for native sub-issues and
issue dependencies. Do not rely only on checkboxes or prose in issue bodies.

If PR #54 is not merged, GitHub authentication is unavailable, the native graph
cannot be read reliably, or the graph contains a cycle, report that condition
and wait. Do not substitute a hand-written issue order that ignores the live
graph.

### Bootstrap baseline cautions

These are known properties of the audited baseline, not excuses to absorb work
into the wrong ticket:

- `Package.swift` still declares Swift tools 6.2 until PKG-01/#15 lands.
- `HEAVY_DEBUG` does not compile until QA-01/#14 lands.
- No checked-in work selector exists.
- The initial `just test-all` recipe does not run a heavy-debug test lane.
- The audit host's Swift 6.4/macOS 27 results do not establish the required
  Swift 6.3/macOS 26 release baseline.
- The repository is private and has no published version.

Resolve each property only through its owning issue or a correctly attached new
issue.

## Required guidance

At the beginning of the goal, read:

1. any root or nested `AGENTS.md`, `CLAUDE.md`, contributor, security, support,
   or release instructions that exist on current `master`;
2. the baseline
   [pre-release due-diligence audit](./2026-07-25-pre-release-due-diligence.md);
3. the
   [production-readiness remediation index](./Production-Readiness-Remediation-Index.md);
4. the
   [post-remediation production-readiness audit playbook](./Post-Remediation-Production-Readiness-Audit.md);
5. top-level epic
   [#5](https://github.com/plx/hdxl-uri-template/issues/5);
6. the six topic epics
   [#6](https://github.com/plx/hdxl-uri-template/issues/6) through
   [#11](https://github.com/plx/hdxl-uri-template/issues/11);
7. current `Package.swift`, `justfile`, README, workflows, and any checked-in
   package, test, benchmark, consumer, or release harnesses; and
8. the complete body, comments, native blockers, native parents/children,
   linked PRs, and relevant prior art for the issue selected in the current
   loop.

For RFC conformance work, also read the relevant text of
[RFC 6570](https://www.rfc-editor.org/rfc/rfc6570.html), applicable verified
errata, and the provenance record for the pinned
[`uri-templates/uritemplate-test`](https://github.com/uri-templates/uritemplate-test)
revision. The RFC and verified errata are normative; the shared suite is a
critical oracle but does not silently override contrary normative text.

Shared guidance can evolve during this goal. Re-read the selected ticket and
relevant guidance after:

- context compaction;
- handoff to a new session or agent;
- a material review change;
- a merge or rebase that changes the selected branch;
- a changed public-contract decision; or
- any change to the native dependency graph.

Do not rely on remembered acceptance criteria.

Apply instructions in this order:

1. current user, system, developer, and repository safety instructions;
2. the selected issue's required behavior, acceptance criteria, and explicit
   exclusions;
3. repository contributor and release conventions;
4. this goal and the live work-selection protocol below;
5. the remediation index and final audit playbook;
6. the historical due-diligence report; and
7. historical specifications or prior-art PRs.

When sources appear to conflict, inspect current implementation, tests, issue
history, and recorded decisions. Resolve the conflict explicitly in the PR or
ask the user when it would materially change the public contract. Do not choose
the interpretation that merely makes the ticket easiest to close.

The 2026-07-25 audit is immutable historical evidence about revision
`a20b80ec0b95cb662d26cbdc6578a7aa9d9cfab9`. It is not a substitute for
inspecting current `master`.

## Fixed project decisions

The following decisions are settled inputs. Do not reopen them inside an
unrelated ticket:

- Swift tools version 6.3 is the supported package baseline.
- Swift language mode remains version 6.
- Supported deployment targets are version 26 and later for every Apple
  platform declared in `Package.swift`.
- Older Apple platforms, older Swift toolchains, Linux, Windows, and other
  non-Apple platforms are out of scope.
- Public `Comparable` conformances on `URITemplate`, `URIVariableValue`, and
  `URIVariableValueType` will be removed.
- `URITemplate.Codable` uses one validated semantic template-source string and
  decodes through the parser.
- The private parsed AST is not a public persistence or interchange format.
- A separate opaque compiled cache is considered only if API-03 demonstrates a
  material end-to-end benefit under its predeclared decision rule.
- The first candidate is a `0.x` version. A stable `1.0` waits for the public
  contracts and final gates to settle.
- The approved bounded decisions select Swift-only Objective-C removal,
  removal of `URIVariableValue` and `URIVariableValueType` coding conformances,
  and structured public parse diagnostics. Their decision records govern
  subsequent work.

## Live work-selection protocol

This repository does not currently depend on a checked-in selector. The active
agent must derive the next issue deterministically from the live native GitHub
graph.

### Define the workflow universe

The workflow universe is:

- top-level epic #5;
- every issue recursively attached as a native sub-issue of #5 or one of its
  descendants;
- every later finding deliberately attached to that hierarchy; and
- any gate reopened because later work invalidated its evidence.

An issue mentioned only in prose is not automatically part of the program.
Attach genuine new program work through the correct native parent and
dependencies before relying on it for scheduling.

### Reconcile claims before choosing work

For every open issue in the workflow universe, determine whether an open PR
already contains a closing reference for it.

- A valid claim is an open PR targeting `master` whose
  `closingIssuesReferences` contains exactly that selected program issue.
- A preparatory PR using only `Refs #N` is not a closing claim.
- A PR against another base is not a valid workflow claim.
- A merged PR counts as landed work only after GitHub closes the issue and the
  closing relationship is visible.
- A closed, unmerged, or superseded PR does not claim the issue.

If a claimed PR needs review, CI, restacking, or corrections, service that PR
before starting overlapping work. Do not create a duplicate implementation.

### Service the claimed-PR queue

Before selecting unclaimed work, classify every valid claimed PR:

- **Actionable:** the active agent can review it, answer requested changes,
  correct it, restack it, rerun a failed required check, or merge it now.
- **Merge-ready:** all prerequisites are closed, the final diff is approved and
  green, and repository policy permits the active agent to merge it. Treat this
  as actionable.
- **Dependency-waiting:** the selected issue has an open native blocker. If
  that blocker is claimed, service the blocker first. If it is unclaimed,
  reconcile whether the dependent claim and stack are valid before doing more
  work on the dependent PR.
- **Externally waiting:** it is waiting only on running CI, a required human or
  owner decision, an unavailable environment, or another event the active
  agent cannot safely advance now.

Exclude dependency-waiting claims from the actionable queue. Topologically sort
the remaining actionable claims by native dependency order, so a claim can
never rank ahead of its claimed prerequisite. Break ties by the selected
issue's priority (`P0` through `P3`) and then by ascending issue number. Service
the first claim before computing an unclaimed ready set. Continue until it
either merges, becomes dependency-waiting or externally waiting, or reaches a
stable state with no safe current action. Work on only that claimed issue
during the service pass.

Dependency-waiting and externally waiting claims do not block independent
ready work. Reclassify all claims at the beginning of every selection loop so
a newly actionable or merge-ready PR cannot be starved by a stream of new
issues. If a claim lacks a valid priority label or has conflicting priority
labels, stop and repair the graph metadata rather than guessing its queue
position.

### Compute the ready set

Classify an open leaf as **hard-ready** when all of the following are true:

- it belongs to the workflow universe;
- every native blocker is closed;
- it has no unresolved contract checkpoint that prevents implementation;
- it has no valid open closing PR; and
- current `master` contains the prerequisites needed to satisfy it.

Classify an open leaf as **stack-ready** only when:

- every native blocker is either closed or claimed by a valid open closing PR;
- at least one blocker is claimed rather than closed;
- the selected implementation genuinely needs an unmerged blocker's code;
- the required predecessor heads form one compatible ancestry;
- selecting it creates at most one unmerged descendant above its predecessor;
- no unresolved contract checkpoint prevents implementation; and
- the issue itself has no valid open closing PR.

An open prerequisite PR is not a closed blocker. Stack-ready status permits
implementation and a draft PR, never an out-of-order merge.

An issue with native sub-issues is **gate-ready** only when every required child
and blocker is actually closed. Topic epics, #43, #44, and #5 cannot use
stack-ready coverage.

### Select deterministically

Combine hard-ready and stack-ready leaves with gate-ready issues, then sort by:

1. `priority:P0`;
2. `priority:P1`;
3. `priority:P2`;
4. `priority:P3`;
5. hard-ready or gate-ready before stack-ready at the same priority; and then
6. ascending GitHub issue number.

Select the first issue.

Do not change priority, parents, or dependencies merely to obtain a preferred
selection. A relationship change requires evidence that the graph was wrong,
an update to every affected issue body, and a corresponding remediation-index
update.

### Interpret the result

- **Claim selected:** Service only the first actionable claimed PR.
- **Selected:** No claim is currently actionable; work only on the selected
  unclaimed issue.
- **Waiting:** No claim is actionable and no unclaimed issue is ready, but open
  issues or dependency-waiting or externally waiting claims remain. Finish or
  await review, CI, merge, restacking, a decision checkpoint, or the actual
  blocker. Do not manufacture readiness.
- **Gate-ready:** A topic epic, candidate, audit, or top-level issue is selected
  because all prerequisites are closed. Follow the gate rules below.
- **Complete candidate:** No open issue remains below #5, no program PR or
  stack remains open, and #5 itself is ready for its final evidence PR. Run
  the terminal cross-checks before closing it.

If pagination, rate limits, permissions, or API changes make the ready set
uncertain, fail closed and diagnose the query. Do not guess.

## Non-negotiable workflow rules

1. **The live native graph chooses work.** Do not choose a more attractive
   issue manually and do not evade priority or dependencies.
2. **One issue is actively implemented at a time.** Stable draft PRs may await
   review, but subagents must not each implement a different workflow issue.
   Subagents may perform bounded research, reproduce a defect, or independently
   review the selected issue.
3. **One closing PR closes exactly one program issue.** Split combined fixes
   unless the selected ticket itself requires inseparable work.
4. **Every program PR targets `master`.** A branch may be based on an open
   prerequisite branch, but the GitHub PR base remains `master`.
5. **GitHub closes issues through merged PRs.** Never use `gh issue close`, an
   issue-state mutation that sets `closed`, or the UI close action for a
   workflow issue, except for the narrowly defined conditional #53
   `not_planned` disposition below.
6. **Open PR coverage is not landed work.** It may sequence dependent
   implementation, but never satisfies a gate or permits an out-of-order merge.
7. **Behavioral tests prove the defect.** Add a focused regression that fails
   for the intended reason before the fix and passes afterward.
8. **Nonbehavioral work has objective before/after evidence.** API removals,
   decisions, documentation, workflows, provenance, and research use the
   evidence form named by their tickets rather than artificial unit tests.
9. **Do not weaken evidence.** Never delete or relax a test, dependency,
   acceptance criterion, fixture, label, branch rule, or audit gate merely to
   obtain a green result.
10. **Do not edit upstream conformance fixtures to fit the implementation.**
    Preserve pinned upstream bytes and represent project-owned interpretations
    as separate, cited tests.
11. **Keep contracts aligned.** Update authoritative documentation in the
    selected ticket when required. Do not make premature global promises that
    belong to a later documentation ticket, but do not leave already
    authoritative text false.
12. **No silent scope absorption.** New independently actionable defects
    receive self-contained issues and correct native metadata unless they are
    strictly necessary to satisfy the selected ticket's existing acceptance
    criteria.
13. **Preserve the support boundary.** Do not add a broad toolchain/platform
    matrix or infer support from an incidental successful build.
14. **No publication by implication.** A passing audit or completed goal is
    not permission to tag or release.

For this goal, the no-direct-close rule is strict: every ordinary leaf, topic
epic, candidate gate, audit gate, and top-level program issue closes through a
dedicated merged PR. Conditional Objective-C implementation issue #53 is the
sole exception and only on the removal path defined below. Reopening
invalidated evidence is permitted only where this runbook requires it.
Reopening is not completion; the issue must later close again through another
dedicated PR.

## Pull-request stack contract

The program is a collection of small, default-branch-targeted ancestry stacks,
not one giant PR and not a 42-branch chain. Git ancestry may stack on a
predecessor head; the GitHub PR base may not.

### Starting a branch

- If the selected issue does not need changes from an open prerequisite PR,
  create its branch from current remote `master`. This starts a new stack.
- If the selected issue is ready for implementation and truly requires an
  unmerged prerequisite's code, branch from the exact head of the nearest
  prerequisite PR. Record the full ancestry.
- If the issue can be implemented and tested against current `master`, prefer
  a new stack from `master` even when independent PRs are open.
- Use an issue-specific branch name such as
  `agent/conf-05-reserved-character-set` or
  `agent/issue-26-reserved-expansion`.
- Never reuse a branch from a merged, closed, or abandoned ticket.

Every PR must use `master` as its GitHub base. A dependent PR may temporarily
show ancestor commits in its diff; its Stack section must make that explicit.

Keep at most one unmerged descendant above a predecessor PR. Before preparing a
third level, merge and restack from the bottom so every open diff remains
reviewable.

### Stack metadata

Every stacked PR body must identify:

- the immediate predecessor PR, or `none`;
- all earlier PRs whose commits are present;
- the required merge order;
- whether its tests require the predecessor's code; and
- the exact full commit or branch from which it was created.

Use ordinary references such as `Refs #N` for related program issues. Only the
selected issue receives a closing keyword.

### Merge order

- Merge from the bottom of a stack upward.
- Never merge a dependent PR while a semantic prerequisite issue is open.
- Require the predecessor PR to be merged, not merely approved or green.
- After each predecessor merge, update the next PR on current `master`, remove
  already-landed ancestor commits from its diff, resolve conflicts, and rerun
  every affected check.
- If history rewriting is necessary, use `--force-with-lease` only on the
  goal's own verified ticket branch after confirming no other work depends on
  its unpublished head. Never use an unguarded force push.
- Re-verify the child PR's base, diff, closing reference, checks, and review
  state after any rebase or branch update.
- Merge an independent stack whenever it is approved and green. Do not retain
  a deep global stack merely for the appearance of continuous sequencing.

Topic epics, release-candidate preparation, the independent audit, and the
top-level program gate never stack on merely covered requirements. Begin their
closing evidence only after every native prerequisite is actually closed.

## The one-issue loop

Repeat this loop until the terminal criteria are satisfied.

### 1. Reconcile local and live state

Before selecting or resuming work:

```sh
git fetch --prune origin
git status --short --branch
git rev-parse HEAD
git rev-parse origin/master
gh auth status
```

Then:

- inspect all open program PRs, reviews, and checks;
- refresh the native sub-issue and blocked-by graph;
- verify the current branch belongs to the issue being serviced;
- finish any review or CI correction already in active progress; and
- compute the ready set using the protocol above.

If an issue already has implementation in progress, verify whether GitHub has
indexed the intended closing PR. Repair PR metadata or wait for indexing rather
than opening a duplicate.

### 2. Establish the selected ticket contract

Read the complete issue and linked guidance. Create a private working checklist
that maps:

- every acceptance criterion to a code, test, documentation, or evidence
  change;
- every required validation command to a planned run;
- every native blocker to a closed issue or named stack predecessor;
- every non-goal to a scope boundary;
- every public-contract choice to an already recorded decision or explicit
  checkpoint; and
- every artifact promised by the issue to its final repository path.

Inspect current source and tests rather than assuming the baseline audit still
describes `master`. Search for overlapping open PRs and prior art linked from
the issue.

### 3. Capture the before state

Before implementation:

- reproduce the defect or missing control on the appropriate vulnerable
  revision when the ticket requires it;
- add or design a regression that fails for the intended reason;
- record the exact command, exit status, and concise result;
- distinguish environmental failure from proof of the defect; and
- explain when red-before-fix testing is genuinely inapplicable.

Use ticket-appropriate evidence for nonbehavioral work:

- a symbol-graph or API diff;
- a compiler, documentation, or formatter failure;
- a broken external-consumer build;
- a deliberately failing workflow gate;
- a fixture hash/count or missing-provenance check;
- a benchmark baseline;
- a source scan; or
- a durable decision analysis.

Do not mutate the immutable candidate or the only implementation worktree to
manufacture pre-fix evidence. Use a disposable secondary worktree or another
reversible, isolated method.

### 4. Implement only the selected issue

Make the smallest complete change that satisfies the ticket. Preserve unrelated
user work. Follow the repository's current formatting and architecture. Keep
public-input failure controlled and diagnostics bounded and nonsensitive.

When implementation reveals a separate defect:

1. determine whether it is strictly necessary for the selected acceptance
   criteria;
2. if independent, create a self-contained issue containing:
   - a stable backlog identifier;
   - reproduction and audit evidence;
   - impact and priority;
   - required behavior and implementation direction;
   - pre-fix regression or equivalent evidence;
   - validation and acceptance criteria;
   - explicit exclusions;
   - exactly one priority and type label;
   - at least one domain and component label;
   - the correct native parent; and
   - every semantic native blocker;
3. update the remediation index in the same maintenance boundary;
4. ensure the new graph remains acyclic; and
5. return to the live work-selection protocol after the selected ticket
   reaches a stable PR boundary.

Do not hide substantive audit findings inside an unrelated PR.

### 5. Validate before opening the PR

Run every command required by the selected ticket and the relevant
repository-wide checks.

The ordinary Swift baseline is:

```sh
swift package resolve
swift build
swift test
swift build -c release
swift test -c release
git diff --check
```

After QA-01 has repaired `HEAVY_DEBUG`, also run:

```sh
swift test -Xswiftc -DHEAVY_DEBUG
```

After the repository's aggregate recipes and CI contract are finalized, run
their current documented equivalents, including `just build-all` and
`just test-all` when those remain supported.

Run additional checks whenever the ticket or changed surface requires them:

- the complete four-file shared conformance corpus;
- fixture counts, hashes, and provenance checks;
- Address Sanitizer;
- Thread Sanitizer;
- deterministic and coverage-guided fuzzing;
- shared-template concurrency stress;
- representative and adversarial Release benchmarks;
- public Swift consumer compilation;
- a real `.m` Objective-C consumer if support is retained;
- JSON and property-list coding tests;
- DocC and documentation example compilation;
- formatting/lint policy;
- symbol-graph or API-digester comparison; and
- consolidated compile-only smoke tests for every declared Apple 26 platform.

Before QA-01 lands, a pre-existing heavy-debug failure must be linked to that
ticket and shown not to have worsened; it is not a pass. Before QA-02 and QA-03
land, missing CI or hardening automation must likewise be reported honestly.
Once a gate exists and applies to the selected change, it is required.

Do not claim Swift 6.3, macOS 26, another Apple platform, sanitizer, or
Objective-C evidence from an environment that did not run it. Use the intended
CI/release environment or report the limitation and wait when the ticket cannot
be completed without it.

Inspect the final diff for unrelated changes, generated artifacts, secrets,
debugging output, edited upstream fixtures, stale documentation, and accidental
public API changes.

### 6. Commit and open one draft PR

Commit only the selected issue's files. Push its issue-specific branch and open
a draft PR targeting `master`.

Use the stable backlog identifier in the title, for example:

```text
CONF-05: Correct reserved expansion character handling
```

For an ordinary implementation or closing evidence PR, use this body:

```markdown
Closes #<selected-issue>

## Scope

<What this ticket changes and why>

## Ticket contract

<How the implementation maps to required behavior and exclusions>

## Stack

- Immediate predecessor: <PR URL or none>
- Earlier included PRs: <URLs or none>
- Required merge order: <bottom to top>
- Branch point: <full commit SHA>
- Requires predecessor code for tests: <yes/no>

## Before evidence

<Command and concise failing result, or ticket-appropriate reason not applicable>

## Validation

- `<command>` — <result>

## Acceptance criteria

<Map every criterion to evidence in this PR>

## Residual risks

<None, or explicit limitations and follow-up issue links>
```

The PR body must contain exactly one GitHub closing keyword for exactly the
selected program issue. Do not place `Closes`, `Fixes`, `Resolves`, or another
closing keyword for a program issue in:

- the PR title;
- a commit message;
- a comment;
- a review;
- stack metadata; or
- an external repository.

Use `Refs #N` for all nonclosing relationships. Candidate and audit preparation
PRs follow the special rules below.

### 7. Verify GitHub's closing relationship

After opening or editing the PR, wait for GitHub indexing and run:

```sh
gh pr view <pr-number> \
  --json baseRefName,headRefName,closingIssuesReferences,isDraft,state
```

Require:

- state `OPEN`;
- base `master`;
- draft status until the PR is ready for review; and
- exactly one `closingIssuesReferences` entry, equal to the selected issue.

Also confirm the selected issue remains open. The PR claims work; it does not
complete it.

For a nonclosing candidate-preparation or audit-in-progress PR, require zero
program closing references.

If any assertion fails, correct the PR before continuing. Do not close the
issue manually as a substitute.

### 8. Complete review and CI

Monitor every required check. Read all review comments and inline threads,
implement actionable corrections, rerun affected validation, and keep the PR
body and stack metadata current.

Mark the PR ready only when:

- its final diff is limited to the selected ticket;
- every stack predecessor has merged;
- it has been updated on current `master` so no ancestor-only change remains in
  its diff;
- every acceptance criterion has evidence;
- local and required hosted checks pass;
- the closing relationship remains exact; and
- every unresolved review concern is fixed or answered with concrete evidence.

Do not dismiss a failing check as flaky without reproduction and evidence. A
required check that cannot run because of account billing, credentials, runner
capacity, or protected settings is not green. Resolve it or request owner
action.

If repository policy requires no human approval, routine remediation PRs may
merge after a separate agent or fresh session independently reviews the final
diff, ticket contract, tests, and residual risks and finds no unresolved
blocker. Material public-contract, legal, candidate-freeze, audit, and
publication decisions still require their explicit checkpoints.

### 9. Merge safely

Merge an ordinary in-repository PR only when:

- every semantic and stack predecessor has merged;
- branch protection and required approvals are satisfied;
- every required check is green on the final head;
- the PR still targets `master`;
- the closing reference still names exactly one selected issue; and
- no decision, candidate, audit, or publication checkpoint applies.

Use the repository's configured merge method. Never use an administrator
bypass.

After merge:

1. poll GitHub for a bounded period to allow closing-reference and timeline
   indexing;
2. verify GitHub automatically changed the selected issue to closed;
3. inspect the issue's closing PR relationship or timeline;
4. if the relationship remains absent after bounded refetching, do **not**
   close the issue manually—report the failure and request user direction;
5. update and revalidate the next descendant PR, if one exists;
6. remove the merged branch when no descendant needs it;
7. refresh the native graph and remediation index; and
8. return to work selection.

An open PR, a merged commit, a checked checkbox, or passing tests are not
completion if the selected issue remains open.

## Decision and administrative checkpoints

The live graph determines readiness, but it does not supply maintainer
judgment, legal confirmation, protected settings, credentials, or independent
audit authority.

### Public-contract decisions

The following issues require a concrete recommendation and an explicit
maintainer decision before their selected outcome merges:

- [#49](https://github.com/plx/hdxl-uri-template/issues/49) (`API-05`):
  structured public parse/validation diagnostics and the disposition of
  `DataValidationError`;
- [#50](https://github.com/plx/hdxl-uri-template/issues/50) (`API-06`):
  retain and define or remove `URIVariableValue.Codable`; and
- [#52](https://github.com/plx/hdxl-uri-template/issues/52) (`API-08`):
  retain and complete or deliberately remove Objective-C support.

Research current consumers, implementation cost, compatibility, and ticket
criteria. Present one recommended outcome with tradeoffs. Do not select the
easiest implementation by default.

API-01's `Comparable` removal and API-02's semantic-string template coding are
already settled and do not require reapproval.

### Research outcome

Issue [#47](https://github.com/plx/hdxl-uri-template/issues/47) (`API-03`) is
successful even when it concludes that no compiled cache should exist. Follow
its predeclared benchmark method and decision threshold. Changing the threshold
after seeing results requires maintainer approval.

### Legal and ownership evidence

Issue [#17](https://github.com/plx/hdxl-uri-template/issues/17) (`DOC-05`) may
require employer, author, or legal confirmation about recreated private work.
An agent may inventory and explain evidence but must not invent ownership,
permission, or legal advice. Pause for the real confirmation when repository
evidence is insufficient.

### Repository and workflow settings

Workflow hardening, branch protection, secret configuration, private reporting,
and release environments may require owner-only settings. Inspect what current
credentials actually expose. Ask the owner to perform or authorize protected
changes; never claim an unavailable setting was verified.

### Release-candidate decision

Issue [#43](https://github.com/plx/hdxl-uri-template/issues/43) (`DOC-06`)
requires explicit maintainer approval of:

- the proposed `0.x` version;
- the compatibility policy;
- accepted residual risks;
- the exact immutable candidate SHA; and
- the decision to submit that candidate to the independent audit.

This checkpoint freezes a candidate. It does not authorize publication.

### Independent audit

The implementation sequence must not author its own final verdict. Issue #44
requires a fresh checkout and an audit context independent of the mutable
remediation sequence. At least one auditor must not be the primary remediation
author. If that is impractical, a second maintainer must independently inspect
the complete evidence and sign the result. The active implementation context
hands off the immutable candidate and evidence; it does not predetermine or
self-approve the verdict.

The #44 report PR may not merge or close #44 until both maintainer approval and
independent-auditor or independent-reviewer sign-off are recorded in the report
or PR. One person may not fill both roles merely by starting a fresh session.
If the required people are unavailable, stop at this checkpoint and request
their participation.

A checkpoint is not permission to abandon the goal. Once the decision or owner
action is recorded, resume the same ticket loop and live graph.

## Conditional Objective-C branch

API-08/#52 is the binding retain/remove decision.

If Objective-C support is retained:

- API-09/#53 must implement safe parsing, expansion, diagnostics, values, and
  applicable coding behavior;
- QA-04/#22 must compile and run a real `.m` consumer;
- README and DocC work must document selectors, Swift names, nullability,
  `NSError`, value, and archive behavior; and
- AUDIT-01/#44 must exercise the generated Objective-C interface and real
  consumer.

Issue #53 closes normally through its dedicated implementation PR.

If Objective-C support is removed:

1. Merge a reviewed, nonclosing decision-record PR using `Refs #52`. It records
   the removal contract, creates a separate self-contained removal
   implementation issue under epic #8, and updates the native graph.
2. Make the removal issue cover all wrappers, tests, archive surfaces, and
   support claims, and make every dependent gate wait for it. The merged #52
   decision record is its contract prerequisite; do not create a native cycle
   by blocking the removal issue on the still-open final #52 gate.
3. Merge the removal implementation and real public Swift consumer work.
4. Verify README, DocC, package claims, generated interfaces, and audit scope
   all state that Objective-C is unsupported.
5. Apply GitHub's native `not_planned` disposition to #53 with a comment linking
   the merged nonclosing #52 decision record and removal PR. This exceptional
   disposition may occur while #52 itself remains open; #53's native dependency
   on #52 governs retained-facade implementation, not the reviewed removal
   disposition.
6. Create a final decision/evidence PR containing `Closes #52` and prove every
   #52 acceptance criterion, including the #53 disposition and complete removal
   state.

That #53 disposition is the sole exception to the one-issue/one-closing-PR and
no-direct-close rules. It is valid only because the retained-facade
implementation becomes deliberately inapplicable after the reviewed removal
path lands. Do not use this exception for any other leaf, gate, research
outcome, or deferred work.

On the removal path, QA-04/#22 still closes through a merged PR that provides
the public Swift consumer fixture and records the `.m` portion as not
applicable with a link to #52.

In either branch, HARD-02/#28 remains mandatory because Swift association
values must preserve their own invariants.

## Topic-epic gate rules

Issues #6 through #11 are evidence gates, not implementation shortcuts. A topic
epic becomes selectable only after every native child and blocker is closed.
On the completed Objective-C removal path, #53's authorized `not_planned`
disposition counts as closed for epic #8 only when it links the merged
nonclosing #52 decision record and removal implementation evidence.

When a topic epic is selected:

1. re-read its definition of done;
2. verify every child closed through the intended merged PR, except for the
   narrowly authorized and fully evidenced #53 disposition above;
3. rerun the aggregate checks named by the epic;
4. inspect current source and documentation for regressions or unrepresented
   work;
5. resolve or create issues for every substantive gap; and
6. create a dedicated evidence PR that closes only that epic.

If the epic does not name another repository artifact, add:

```text
Documentation/Audits/Evidence/<YYYY-MM-DD>-epic-<number>-completion.md
```

The record must contain:

- exact `master` commit;
- child issues and closing PRs;
- each epic acceptance criterion mapped to evidence;
- commands, environments, and artifact links;
- residual risks and their owners;
- newly created issue links, if any; and
- an explicit pass/fail conclusion.

Do not open an empty or no-op PR merely to obtain a closing relationship.

If later work invalidates a closed topic epic, reopen it, attach the new issue
through the correct native parent and dependencies, and block downstream
candidate/audit work. After remediation, rerun the gate and close it again
through a new evidence PR.

## Release-candidate gate #43

Issue #43 prepares but does not publish the first `0.x` candidate.

Begin candidate work only when the live graph selects #43 and every native
blocker is actually closed.

Direct blocker closure alone is not enough to freeze a candidate that is known
to precede later candidate-affecting work. In the ordinary program flow:

- topic epics #6 through #10 must already have passed and closed; and
- every #11 child other than #43 must already be closed.

The later #11 and #5 closing records and the #44 audit report must be
evidence-only relative to the candidate. If #43 appears selectable while an
open program issue can still alter package source, tests, manifest, workflows,
public contracts, or release documentation, treat the candidate gate as not
ready and repair the missing native scheduling relationship and index
rationale. Do not knowingly freeze a candidate that planned work will
invalidate.

### Freeze procedure

1. Confirm all candidate-affecting source, tests, package metadata, API
   decisions, workflows, user documentation, notices, and release controls have
   merged.
2. Run the candidate checklist and required clean-consumer verification.
3. Obtain the explicit release-candidate decision above.
4. Identify the exact current `master` commit as the immutable candidate.
5. Create a dedicated evidence/release-note PR that records the candidate SHA,
   proposed version, compatibility policy, artifacts, and rollback plan and
   contains `Closes #43`.

The closing PR must be evidence-only relative to the candidate. If candidate-
affecting changes are still needed, use a preparatory PR containing only
`Refs #43`, merge and validate it, and freeze a new current `master` commit
before creating the closing evidence PR.

The candidate remains untagged.

After #43 closes, no candidate-affecting change may land before #44 completes.
If one becomes necessary:

- stop the audit;
- reopen #43 and every affected topic epic;
- create and complete the required remediation issue;
- freeze a new candidate;
- rerun the affected gates; and
- begin a fresh independent audit.

The old evidence does not authorize the changed candidate.

## Independent audit gate #44

Run #44 against the exact immutable candidate using the committed
[audit playbook](./Post-Remediation-Production-Readiness-Audit.md).

The audit must:

- use a fresh checkout and Swift 6.3/Apple 26 release environment;
- preserve the complete evidence bundle;
- classify every checklist item as pass, fail, or justified not applicable;
- trace every original finding and remediation issue;
- avoid fixing the candidate inside the audit changeset;
- issue the playbook's explicit verdict and residual-risk register; and
- record both maintainer approval and independent-auditor or
  independent-reviewer sign-off before its report PR merges.

An audit-in-progress report PR uses only `Refs #44`.

A complete, reproducible report for any of the playbook's three verdicts is a
completed execution of the current audit run. After the required sign-offs, its
dedicated report PR contains `Closes #44`. A constrained-preview or
not-production-suitable verdict closes that audit run but does not satisfy this
goal's final audit gate.

When the verdict is constrained or no-go:

1. Finish the signed report and create a self-contained linked issue for every
   actionable finding, satisfying #44's finding-traceability criteria. Do not
   yet attach those issues as native blockers or sub-issues, and do not reopen
   #43, an epic, or another native blocker of #44.
2. Merge the report PR with `Closes #44`, then verify that GitHub records #44
   as closed by that PR.
3. Immediately reopen #44 with a comment linking the completed nonpassing run,
   its exact candidate, the finding issues, and the requirement for a new
   candidate. Do this before any other selection pass so #5 cannot become
   gate-ready. This reopening is required workflow state, not completion by
   direct issue manipulation.
4. Attach the finding issues to the correct topic epics and native
   dependencies, reopen every invalidated epic and #43, and verify the graph
   and remediation index include them.
5. Remediate through the ordinary one-issue loop, freeze a new candidate, and
   repeat the independent audit.

The audit report itself may merge after the candidate as non-candidate-affecting
evidence while continuing to name the exact earlier candidate SHA.

Only an unconditional production-suitable report may leave #44 closed and
permit #5 to become gate-ready. A nonpassing report that closed #44 but was not
reopened is a graph inconsistency: reopen it before selecting any other work.

## Final program gate #5

Issue #5 is last.

Begin its final evidence only when:

- topic epics #6 through #11 are closed;
- candidate gate #43 is closed for the audited candidate;
- audit gate #44 is closed by an unconditional production-suitable report;
- every native descendant and later program finding is closed;
- no remediation PR or intentional stack remains open; and
- the live graph and committed index agree.

Create a dedicated final program evidence record, normally:

```text
Documentation/Audits/Evidence/<YYYY-MM-DD>-program-5-completion.md
```

Map every top-level definition-of-done item to:

- closing issues and PRs;
- the exact audited candidate;
- final audit and evidence bundle;
- current clean-checkout validation;
- accepted residual risks and owners; and
- the explicit publication boundary.

The PR closes only #5. Do not close #5 merely because every child checkbox
appears checked or because an untagged `0.x` candidate exists.

## Publication boundary after completion

Completion of #5 means the candidate has passed the defined production-
readiness program. It does not mean the package has been published.

The final response must state:

- the exact audited candidate SHA;
- the proposed version;
- that no tag or GitHub Release was created by this goal;
- any time-sensitive evidence that should be refreshed before publication; and
- the explicit next checkpoint for a maintainer who wants to publish.

If the user later authorizes publication, use a separate issue or goal that
revalidates the candidate, presents tag/artifact/checksum details, obtains
explicit approval for the irreversible action, publishes without moving the
audited tag, and verifies a clean remote consumer.

## Continuity across turns and compaction

GitHub and committed files are the durable source of truth. Never rely only on
conversation memory or an untracked note.

At every handoff or resumed turn:

1. re-read this goal and the relevant audit guidance;
2. inspect `git status`, current branch, upstream, and worktree ownership;
3. inspect the selected issue and current PR;
4. record in the goal progress update:
   - selected issue and stable ID;
   - branch and PR URL;
   - stack predecessor;
   - before-evidence status;
   - final validation status;
   - review and CI status;
   - dependency changes; and
   - next action;
5. verify every fact against GitHub; and
6. continue the current one-issue loop before selecting more work.

Keep unfinished implementation on a named, pushed issue branch or in a clearly
reported local worktree. Do not leave critical progress only in temporary
files.

After a merge, compaction, dependency change, or contract decision, recompute
the ready set. Never reuse an old work order without checking the native graph.

## Stop and ask conditions

Pause for user direction when:

- PR #54 has not merged;
- the selected ticket contains materially different valid public-contract
  outcomes and no decision has been recorded;
- legal, employer-ownership, version, residual-risk, or Objective-C policy
  approval is required;
- satisfying the ticket requires destructive migration or external state not
  authorized here;
- branch protection, required review, or a required failing check cannot be
  satisfied without an override;
- the native graph cannot be reconciled safely or changing it would materially
  alter program scope;
- a required credential, platform, hardware environment, repository setting,
  or owner is unavailable;
- the release candidate would need to change after its freeze;
- the audit is not independent enough to support its verdict;
- the user requests an actual tag, GitHub Release, registry publication, or
  external listing; or
- a new finding requires expanding the program beyond the documented support
  boundary.

Do not ask merely because:

- a ticket is difficult;
- a stack needs rebasing;
- CI takes time;
- a known issue has a large acceptance checklist;
- the program spans many turns; or
- the independent audit discovers ordinary in-scope remediation work.

## Terminal completion criteria

Mark the goal complete only when all of the following are true:

- PR #54 and this goal document are present on `master`;
- every issue in the live native program universe, including newly discovered
  findings, topic epics #6 through #11, candidate gate #43, audit gate #44, and
  top-level epic #5, is closed or, only for #53 on the completed Objective-C
  removal path, carries the documented `not_planned` disposition;
- each ordinary issue timeline shows closure by its dedicated merged PR rather
  than a direct state change, and any #53 exception links the merged decision
  and removal evidence;
- no remediation PR, claimed issue, or intentional stack remains open;
- no program branch remains unless repository policy deliberately retains it;
- the native graph is acyclic and contains no open blocker, child, or hidden
  unindexed program issue;
- the remediation index agrees with the final live graph;
- every behavioral defect has durable red-before-fix evidence and a permanent
  regression;
- every nonbehavioral ticket has its required objective evidence;
- all six topic-epic evidence records pass;
- #43 identifies one immutable, untagged `0.x` candidate and complete evidence
  bundle;
- #44 records an unconditional production-suitable verdict for that exact
  candidate;
- a clean checkout passes the final required Swift 6.3, debug, release,
  `HEAVY_DEBUG`, complete conformance, public-consumer, sanitizer, fuzz,
  concurrency, performance, documentation, platform-compilation, and release
  verification defined by the audit;
- accepted residual risks have explicit owners, scope, and review dates;
- #5 closes through its final evidence PR; and
- the final response provides issue, PR, audit, candidate, artifact, and
  validation links sufficient for another maintainer to reproduce the result.

An open PR is not completion. A constrained-preview or no-go audit is not
completion. A prepared candidate while #44 or #5 remains open is not
completion. Publication is not a terminal criterion and must not occur under
this goal.
