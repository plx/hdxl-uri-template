# DOC-05 publication-rights and provenance record

Status: final; maintainer authorization and the license identity were confirmed
on July 26, 2026.

Approver: repository maintainer.

Tracking issue:
[#17](https://github.com/plx/hdxl-uri-template/issues/17).

## Scope

This record covers the project-authored recreation of earlier private
Objective-C work and the maintainer's authority to publish it under the
repository's MIT license.

Third-party fixture and standards-derived material have a separate file-level
inventory and license record in `THIRD_PARTY_NOTICES.md` and `LICENSES/`.
Issue [#42](https://github.com/plx/hdxl-uri-template/issues/42) and merged pull
request [#72](https://github.com/plx/hdxl-uri-template/pull/72) own that
diligence.

This record is factual release governance, not legal advice.

## Public-safe maintainer confirmation

On July 26, 2026, the repository maintainer confirmed that:

- the maintainer is authorized by all relevant authors, employers, and
  rightsholders to publish the recreated private implementation under the
  repository's MIT license;
- the repository contains no confidential or proprietary third-party code from
  that earlier private work; and
- publication rights and necessary attribution have been reviewed.

The same statement is recorded publicly on issue #17. No confidential
contracts, correspondence, supporting evidence, or legal advice are included
in the issue or repository.

## Public artifacts reviewed

- `README.md` describes the package as a port of a private Objective-C
  implementation without claiming that private source was published.
- `LICENSE` contains the project MIT terms and currently identifies
  `Copyright (c) 2026 plx`.
- `THIRD_PARTY_NOTICES.md` separates project-authored MIT material from
  Apache-2.0 fixture material and applicable IETF Trust terms.
- `LICENSES/Apache-2.0.txt` and `LICENSES/IETF-Revised-BSD.txt` preserve the
  relevant third-party terms.
- The pinned fixture inventory records origin, immutable revision, files,
  hashes, and update procedure.

## License identity

On July 26, 2026, the maintainer selected `plx` as the intended copyright
holder name and 2026 as the intended copyright year. The root license therefore
states:

```text
Copyright (c) 2026 plx
```

## Completion and release boundary

DOC-05 has no recorded publication-rights or provenance blocker. A future
ownership concern must reopen release review and may require advice from the
relevant rightsholder or qualified professional.

Completing DOC-05 does not publish a tag, GitHub Release, package-registry
version, Swift Package Index entry, or other external listing. Publication
remains a separate explicit maintainer action outside the production-readiness
remediation goal.
