# Canary and rollback template

Copy and complete this document for a load-bearing adopter. Until an adopter is
identified, retain it as the generic operational contract and mark execution
not applicable rather than inventing production evidence.

## Identity and ownership

- Package version and exact commit:
- Consuming application and environment:
- Canary owner:
- On-call/escalation owner:
- Planned start and end (UTC):
- Feature flag or dependency switch:
- Last known-good version or removal plan:
- Approval record:

## Trust and input inventory

- Template sources and trust classifications:
- Variable-value sources and trust classifications:
- Allowed URI schemes:
- Allowed hosts/destinations:
- Maximum template length:
- Maximum variable count:
- Maximum text length:
- Maximum list/association size:
- Maximum rendered-output length:
- Redacted golden corpus location and digest:

Never place real secrets, credentials, personal data, or private production
URIs in this document or its evidence.

## Predeclared acceptance thresholds

- Golden-corpus mismatch budget: zero.
- Unexplained shadow mismatch budget: zero.
- Crash, hang, trap, or data-race budget: zero.
- Sensitive-value disclosure budget: zero.
- Unapproved scheme/host/destination changes: zero.
- Parse and expansion error-rate budget:
- p50/p95/p99 latency budgets:
- CPU and memory budgets:
- Minimum observation: seven consecutive days and 1,000,000 representative
  expansions, or a documented alternative approved before observation.

## Rollout

- [ ] Resolve and test the exact approved package version.
- [ ] Run the sanitized golden corpus against expected or incumbent output.
- [ ] Validate schemes, hosts, destinations, and size limits in application
      code.
- [ ] Confirm telemetry records counts and latency without raw templates,
      values, or expanded URIs.
- [ ] Confirm errors use bounded categories and do not log recovery payloads.
- [ ] Start in shadow mode where practical.
- [ ] Increase traffic through predeclared stages:

| Stage    | Traffic or workload | Minimum duration | Approver | Result |
| -------- | ------------------- | ---------------- | -------- | ------ |
| Shadow   |                     |                  |          |        |
| Limited  |                     |                  |          |        |
| Expanded |                     |                  |          |        |
| Full     |                     |                  |          |        |

## Observations

Record:

- parse and expansion success/failure counts;
- golden and shadow mismatches;
- p50, p95, and p99 parse/expansion latency;
- maximum observed template, value, collection, and output sizes;
- CPU and memory change;
- rejected schemes, hosts, and destinations;
- redaction verification;
- crashes, hangs, traps, data races, and watchdog events; and
- operator observations and incident references.

## Rollback drill

- Trigger condition used:
- Decision owner:
- Time from decision to rollback:
- Feature flag, pin, or dependency removal performed:
- Resolution/build/deployment proof:
- Traffic or workload restored:
- Telemetry returned to baseline:
- Follow-up issue:

A rollback is not demonstrated by a written command alone. Exercise the
application-owned switch or dependency change in a safe environment before
production approval.

## Decision

- [ ] Every predeclared threshold passed.
- [ ] Rollback was demonstrated.
- [ ] No sensitive evidence was retained.
- [ ] Owners approve continued adoption.

Result:

- `PASS` — approved for the named application and scope.
- `CONDITIONAL` — state remaining gate and owner.
- `ROLLBACK` — stop adoption and follow the release checklist.

Package-level readiness does not make this decision for a particular consuming
system.
