# Security policy

## Supported versions and maturity

HDXLURITemplate is pre-release. There is currently no published version and no
production-suitability promise. The mutable `master` branch is available for
evaluation and receives security fixes on a best-effort basis.

After the first `0.x` release, only the latest published minor line and its
latest patch will receive security fixes. Earlier `0.x` lines may contain
incompatible public API, serialization, or behavior and should be upgraded.
This policy will be reconsidered before `1.0`.

| Version | Security support |
| --- | --- |
| `master` before the first release | Best-effort evaluation support |
| Latest published `0.x` minor and patch | Supported after publication |
| Earlier `0.x` lines | Unsupported |
| Unreleased forks and modified builds | Unsupported by this project |

## Report a vulnerability privately

Do not disclose a suspected vulnerability in a public issue, discussion, pull
request, commit, or test log.

Use GitHub's private vulnerability-reporting form:

1. Open the repository's
   [Security Advisories page](https://github.com/plx/hdxl-uri-template/security/advisories).
2. Select **Report a vulnerability**.
3. Provide a concise impact statement, affected commit or version, minimal
   reproducer, and any suggested mitigation.

Private vulnerability reporting is enabled for this public repository. GitHub
delivers the report only to the reporter, repository administrators, security
managers, and invited advisory collaborators. Do not include production
credentials, real secrets, personal data, or private customer URIs; use
synthetic values.

If GitHub's form is unavailable, open a public issue containing no
vulnerability details and ask the maintainer to confirm the private reporting
route. Do not paste the report into that issue.

## Response and disclosure process

The maintainer aims to:

- acknowledge a new private report within three business days;
- complete an initial severity and scope triage within seven business days;
- request missing reproduction details through the private advisory;
- provide a status update at least every seven days while remediation is
  active; and
- coordinate publication only after a fix and upgrade guidance are ready, or
  after agreeing on another disclosure timeline with the reporter.

Validated reports are developed and reviewed without exposing the report
content. A public advisory and changelog entry will identify affected versions,
impact, remediation, and credits when disclosure is appropriate. Reports that
are not security vulnerabilities are closed privately with a short rationale.

This project does not currently offer a bug bounty or guarantee a particular
release date.

## Security boundary

HDXLURITemplate parses and expands strings. It does not fetch a URI, open a
connection, authorize a request, or decide whether an expanded destination is
safe.

Reports are especially useful for:

- a crash, trap, data race, memory-safety failure, or uncontrolled resource
  use reachable through untrusted templates or values;
- incorrect escaping or expansion that violates the documented RFC 6570
  contract and changes URI structure;
- sensitive template or value disclosure through default error diagnostics;
- malformed `Codable` input bypassing validation or violating value
  invariants; or
- a repository automation or supply-chain weakness that could alter shipped
  source or release evidence.

Reserved and fragment expansion intentionally preserve URI delimiters.
Foundation `URL` construction is not an SSRF, scheme, host, or authorization
policy. Applications must validate destinations and impose their own input and
output limits. These boundaries and safe logging guidance are detailed in the
[README security guidance](README.md#security-boundaries).

For ordinary correctness bugs with no confidentiality or exploitability
concern, use a public GitHub issue and a synthetic reproducer.
