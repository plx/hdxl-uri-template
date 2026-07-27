# Release checklist

This is the required process for an HDXLURITemplate release. It prepares,
audits, publishes, and, when necessary, withdraws one immutable candidate.

Completing a checklist item is evidence, not publication authority. Do not
create a tag, GitHub Release, registry artifact, or public production claim
until the maintainer explicitly approves the exact version and audited
candidate.

## 1. Establish the candidate

- [ ] Select a proposed Semantic Versioning `0.x` version.
- [ ] Record the full 40-character candidate commit SHA.
- [ ] Confirm the checkout is clean and `origin/master` resolves to that SHA.
- [ ] Confirm no tag or GitHub Release already uses the proposed version.
- [ ] Freeze code changes. Any code or documentation change creates a new
      candidate SHA and restarts candidate validation.
- [ ] Record candidate owner, preparation time in UTC, support boundary, and
      intended release notes.

Capture:

```sh
candidate_sha="$(git rev-parse HEAD)"
test "$(git rev-parse --abbrev-ref HEAD)" = master
test -z "$(git status --porcelain)"
git remote -v
git log -1 --show-signature --format=fuller "$candidate_sha"
git tag --points-at "$candidate_sha"
gh release view "PROPOSED_VERSION"
```

The final command is expected to fail before a new release. An existing tag or
release is a blocker, not something to overwrite.

## 2. Build, test, and conformance

- [ ] Confirm Xcode 26.6, Swift 6.3, Swift language mode 6, and Apple 26 SDKs.
- [ ] Run `just build-all` from a clean build state.
- [ ] Run `just test-all`.
- [ ] Confirm Debug, Release, and `HEAVY_DEBUG` passed.
- [ ] Confirm all 270 pinned RFC 6570 cases ran with no skip, quarantine, or
      expected-failure exception.
- [ ] Run `just check-pinned-fixtures` and record all counts, bytes, and hashes.
- [ ] Confirm every declared Apple 26 platform compiled in Core CI.
- [ ] Confirm the required Core CI aggregate is green on the exact candidate.
- [ ] Preserve hosted run URLs and machine-readable test results.

## 3. Hardening and performance

- [ ] Dispatch Recurring Hardening with the exact candidate SHA, `candidate`
      profile, recorded seed, at least 1,000,000 fuzz cases, and
      `failure_probe=false`.
- [ ] Confirm Address Sanitizer passed.
- [ ] Confirm Thread Sanitizer and all concurrency phases passed.
- [ ] Confirm deterministic fuzz completed its exact budget.
- [ ] Confirm Release scaling passed every frozen workload.
- [ ] Confirm detector controls passed.
- [ ] Download or durably reference every artifact before retention expires.
- [ ] Compare performance with the accepted baseline and explain material
      regressions.

Follow
[QA-03 Recurring Hardening](../Hardening/QA-03-Recurring-Hardening.md);
another commit's run is not reusable.

## 4. Public contract review

- [ ] Run `just check-public-api`.
- [ ] Build and run a fresh remote consumer pinned by full revision SHA.
- [ ] Review the public symbol graph and documentation.
- [ ] Review the `URITemplate` persistence format and the current
      `URIVariableValue` `Codable` decision.
- [ ] Confirm default error diagnostics remain bounded and privacy-safe.
- [ ] Confirm the generated Objective-C header contains none of the removed
      wrapper classes, enum, or selectors.
- [ ] Confirm README and API examples compile from synchronized sources.
- [ ] Record every intentional breaking change and migration in the changelog
      and release notes.

## 5. License, provenance, and package contents

- [ ] Review `LICENSE`, `THIRD_PARTY_NOTICES.md`, and every file in `LICENSES/`.
- [ ] Confirm copyright holder and year.
- [ ] Confirm every copied fixture matches its recorded upstream commit and
      digest.
- [ ] Review upstream license and notice changes since the pinned snapshot.
- [ ] Confirm publication-rights evidence remains current.
- [ ] Confirm the source archive contains `README.md`, `LICENSE`,
      `THIRD_PARTY_NOTICES.md`, `SECURITY.md`, `CONTRIBUTING.md`,
      `CHANGELOG.md`, and required reproduced licenses.
- [ ] Confirm `Package.swift` has no local path or development-only dependency.

## 6. Documentation and operations

- [ ] Review the support matrix and pre-release maturity statement.
- [ ] Review security boundaries, private reporting, logging, untrusted input,
      and destination-validation guidance.
- [ ] Review installation, parsing, value flavors, operators, errors,
      concurrency, performance, `Codable`, and Objective-C absence.
- [ ] Confirm `CONTRIBUTING.md`, `SECURITY.md`, `CODE_OF_CONDUCT.md`, and this
      checklist link to one another where applicable.
- [ ] Populate the
      [Canary and Rollback Template](Canary-and-Rollback-Template.md), or record
      that adopter-specific execution is not yet applicable.
- [ ] Draft release notes covering breaking changes, support boundary,
      security-relevant changes, known limitations, license attribution, and
      upgrade/rollback guidance.

## 7. Mandatory independent audit

- [ ] Execute the committed
      [Post-Remediation Production-Readiness Audit](../Audits/Post-Remediation-Production-Readiness-Audit.md)
      from a fresh checkout at the exact candidate SHA.
- [ ] Preserve the complete audit manifest and artifact inventory.
- [ ] Resolve every Blocker and High finding in a new candidate.
- [ ] Record owners, impact, rationale, and review dates for accepted residual
      risks.
- [ ] Obtain the required independent auditor/reviewer sign-off.
- [ ] Obtain explicit maintainer approval of the version, candidate SHA,
      compatibility policy, residual risks, and publication decision.

No participant may infer release approval from a green CI run or from having
prepared the candidate.

## 8. Tag, sign, and publish

Perform this section only after explicit publication approval.

- [ ] Re-fetch `origin` and prove the approved SHA is unchanged.
- [ ] Create an annotated, cryptographically signed tag on the exact audited
      SHA using the approved `MAJOR.MINOR.PATCH` version.
- [ ] Verify the tag signature and target locally and from the remote.
- [ ] Push only that tag.
- [ ] Create the GitHub Release from the signed tag using the reviewed notes.
- [ ] Attach or link evidence checksums and artifacts; do not attach secrets or
      sensitive reports.
- [ ] Verify the generated source archive and its license/notice contents.
- [ ] Resolve, build, and run a clean remote consumer using the released
      Semantic Versioning requirement.
- [ ] Confirm the release, changelog, tag, and candidate SHA all agree.

Command shape:

```sh
version="MAJOR.MINOR.PATCH"
candidate_sha="FULL_40_CHARACTER_SHA"
git fetch --tags origin
test "$(git rev-parse "$candidate_sha")" = "$candidate_sha"
git tag -s "$version" "$candidate_sha" -m "HDXLURITemplate $version"
git tag -v "$version"
test "$(git rev-list -n 1 "$version")" = "$candidate_sha"
git push origin "refs/tags/$version"
gh release create "$version" --verify-tag --notes-file RELEASE_NOTES.md
```

Never move, replace, or silently delete a published version tag.

## 9. Rollback and security response

Before publication, rollback means stopping and selecting a new candidate.
After publication:

- [ ] Stop recommendations and automated adoption of the affected version.
- [ ] Publish a clear advisory or release notice without exposing private
      report content before coordinated disclosure.
- [ ] Tell consumers to pin the last known-good version, disable adoption, or
      remove the dependency when no prior supported version exists.
- [ ] Fix forward in a new patch or minor version according to the `0.x`
      compatibility policy.
- [ ] Repeat the complete candidate and audit process for the fix.
- [ ] Mark an unusable hosted release as withdrawn/yanked where the hosting
      service supports it, while retaining the immutable Git tag for audit.
- [ ] Demonstrate the consuming application's feature-flag or dependency
      rollback using the populated canary plan.
- [ ] Record incident timeline, affected versions, remediation, and follow-up
      work.

## Dry-run record

For a non-release rehearsal, copy this block into the evidence record:

```text
Test commit:
Proposed test version:
Walked by:
Walked at (UTC):
Expected blockers:
Unexpected blockers:
No tag/release created:
Rollback path reviewed:
Final result: DRY RUN ONLY — NOT AUTHORIZED FOR PUBLICATION
```
