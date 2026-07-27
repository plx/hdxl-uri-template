# QA-03 Recurring Hardening

This document defines the reproducible sanitizer, deterministic-fuzz,
concurrency, and adversarial-scaling gate for HDXLURITemplate. The workflow is
expensive by design and therefore runs weekly and by manual dispatch, not for
ordinary pull requests.

The gate is supporting evidence rather than a production-suitability claim. A
release candidate still requires the complete independent
[post-remediation audit](../Audits/Post-Remediation-Production-Readiness-Audit.md),
including its broader coverage-guided fuzz and performance requirements.

## Frozen profiles

Both profiles use Xcode 26.6, Swift 6.3, `macos-26`, the full 40-character
target commit, and the default hexadecimal seed `0x4844584C51413033`.
For local commands, select that toolchain first:

```sh
export DEVELOPER_DIR=/Applications/Xcode_26.6.app/Contents/Developer
xcrun swift --version
```

| Profile | Deterministic fuzz | When to use |
| --- | ---: | --- |
| `scheduled` | 200,000 cases | Weekly drift detection |
| `candidate` | At least 1,000,000 cases | Required for each proposed release-candidate SHA |

The workflow also runs:

- the complete test suite under Address Sanitizer;
- a 20,000-case bounded fuzz subset under Address Sanitizer;
- the complete test suite under Thread Sanitizer;
- three shared-template concurrency phases under Thread Sanitizer, each with
  at least 100,000 mixed operations;
- six Release scaling workloads with five raw samples at every size; and
- negative controls proving that seed replay, the scaling analyzer, and Thread
  Sanitizer detect known failures.

The concurrency phases cover one-worker Swift tasks, core-count Swift tasks,
and native dispatch threads. They compare successful and failing evaluation,
metadata reads, equality, hashing, Codable, independent parsing, and value
operations against the same deterministic digest.

## Deterministic fuzz and replay

The checked runner mixes all four pinned conformance suites with structured
generation, string mutation, malformed near-misses, Unicode, percent
triplets, every operator, modifiers, value shapes, and JSON/property-list
decode probes. It reports the root seed, corpus digest, requested and completed
iterations, counters, duration, and result digest.

Run the scheduled budget locally:

```sh
QA03_COMMIT="$(git rev-parse HEAD)" \
  xcrun swift run -c release HDXLURITemplateQA03 fuzz \
  --seed 0x4844584C51413033 \
  --iterations 200000 \
  --fixtures Tests/HDXLURITemplateTests/Resources
```

Every unexpected failure includes `seed`, `index`, and the derived
`case-seed`. Replay exactly one case without reducing or changing the corpus:

```sh
QA03_COMMIT="$(git rev-parse HEAD)" \
  xcrun swift run -c release HDXLURITemplateQA03 fuzz \
  --seed 0x4844584C51413033 \
  --iterations 200000 \
  --fixtures Tests/HDXLURITemplateTests/Resources \
  --replay-index FAILURE_INDEX
```

This is deterministic bounded fuzzing, not coverage-guided fuzzing. It does not
satisfy the independent audit's coverage-guided duration by itself.

## Concurrency and scaling

Run the unsanitized concurrency stress with at least the host's active core
count:

```sh
QA03_COMMIT="$(git rev-parse HEAD)" \
  xcrun swift run -c release HDXLURITemplateQA03 \
  concurrency --operations 100000
```

The frozen scaling configuration is
[`Hardening/QA03/baselines.json`](../../Hardening/QA03/baselines.json). It was
committed before candidate data is collected. Each workload has four
increasing sizes and fixed repetitions:

- dense valid percent triplets;
- dense malformed percent input;
- long Unicode prefix expansion;
- parser/regex near-misses that fail at the end;
- large list expansion; and
- large association expansion.

After warm-up, the gate rejects any adjacent-size ratio above `3.0` or fitted
log-log exponent above `1.25`. These generous shape thresholds detect a return
to quadratic behavior; they are not absolute latency promises.

```sh
QA03_COMMIT="$(git rev-parse HEAD)" \
  xcrun swift run -c release HDXLURITemplateQA03 scaling \
  --baseline Hardening/QA03/baselines.json \
  --samples 5
```

`verify-scaling-detector` feeds an isolated quadratic equivalent with `4.0`
adjacent ratios and an exponent of `2.0`; the analyzer must reject it.

## Detector controls

Run all negative controls with:

```sh
./Scripts/test-qa-03-detectors.sh
```

The script injects and replays a known deterministic fuzz failure, rejects the
isolated quadratic equivalent, compiles a temporary deliberately racy program
under Thread Sanitizer, requires a race report, and removes the temporary
program. No known race is retained in the package.

For the hosted artifact-on-failure proof, manually dispatch the workflow with
`failure_probe=true`. The detector-control lane writes its provenance and
marker, intentionally exits nonzero, and uploads the artifact with `always()`.
Then dispatch the same target, profile, seed, and iteration budget with
`failure_probe=false`; that exact run must pass before it is accepted as
hardening evidence.

## Hosted candidate procedure

Open **Actions → Recurring Hardening → Run workflow** and provide:

1. the exact full release-candidate SHA in `target_sha`;
2. `candidate` as the profile;
3. the recorded seed;
4. either a blank fuzz count (selects 1,000,000) or a larger count; and
5. `failure_probe=false` for the accepted run.

The validation job rejects abbreviated SHAs, invalid seeds, and candidate
budgets below 1,000,000. Every macOS lane checks out that SHA directly and
verifies `git rev-parse HEAD` before testing. A green run for another commit
cannot be reused.

The accepted workflow run must have a green
`Required recurring hardening gate`. Its 30-day artifacts retain:

- the exact commit, profile, seed, iterations, baseline digest, toolchain, OS,
  kernel, hardware model, CPU counts, architecture, and memory;
- full sanitizer logs and xUnit results;
- fuzz progress, resource statistics, and machine-readable results;
- concurrency operation counts, durations, worker counts, and digests;
- the copied frozen baseline plus raw scaling samples, medians, ratios, fitted
  exponents, and resource statistics; and
- negative-control logs, including controlled-failure evidence when requested.

Record the run URL and artifact names in the release-candidate audit before
their retention window expires.
