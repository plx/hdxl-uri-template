# API-03 raw benchmark evidence

This directory retains the accepted full benchmark run for commit
`d4434e2ab7114168e0508f8d9ee2a9a9c2611ef9`. The run began at
`2026-07-26T18:46:52Z`, ended at `2026-07-26T19:09:22Z`, and passed both the
pre-timing correctness gate and the post-run evidence validators.

The evidence set contains:

- `environment.json`;
- `correctness-validation.txt`;
- `corpus-manifest.json`;
- `raw-warm.jsonl`;
- `raw-fresh-process.jsonl`;
- `raw-memory.jsonl`;
- `summary.csv`;
- `release-swiftc-invocations.txt`; and
- `evidence-sha256.txt`, which hashes the eight generated artifacts above.

Every file records or is tied to the exact benchmark commit, deterministic
corpus digest, stable Xcode/Swift toolchain, and actual runtime OS. Raw samples
are retained without outlier deletion. The environment record contains the
sanitized correctness-validation log's command, status, completion time, and
SHA-256.

Full mode retains:

- 30 warm samples for each of 36 primary and 18 rejection configurations;
- 30 fresh-process samples for the same 54 configurations;
- one `/usr/bin/time -lp` memory record for every retained fresh process; and
- 108 summary rows, split evenly between warm and fresh-process evidence.

Primary configurations cover all nine deterministic corpora. Rejection
configurations cover all nine fault classes at balanced sizes 1,000 and 10,000.
The manifest contains all nine corpus identities. Warm rows report five
independent process clusters with six batches apiece; fresh rows report 30
independent processes with one operation sample apiece. The coarse
`/usr/bin/time` real-seconds text in memory records is diagnostic only;
high-resolution launch-to-exit latency lives in the paired fresh record.

The accepted run contains exactly 1,620 warm, 1,620 fresh-process, and 1,620
memory records, plus 108 summary rows. All retained warm batches are at least
200 ms. The largest relative MAD was 1.1677% for warm evidence and 4.3572% for
fresh-process evidence, below the frozen 5% and 10% rerun thresholds. The
environment record consequently reports `evidenceValidationStatus: "passed"`
and zero noise-threshold violations.

On the balanced 1,000/10,000-template workloads, the prototype cache was
3.2–3.8 times slower than direct parsing, used 3.73×/4.18× the encoded bytes,
and increased peak process memory. The predeclared decision therefore remains
no cache and no follow-up design issue; see
[`../../../Decisions/API-03-Compiled-Cache.md`](../../../Decisions/API-03-Compiled-Cache.md).
The intervals describe this single prewarmed host, not cross-machine or
cold-disk variation.

Two Xcode Allocations recording attempts failed before user code and produced
only incomplete, non-exportable bundles. No trace is included and no
allocation-count claim is made. The commands, failure, and partial-bundle
hashes are recorded in the benchmark report; the accepted decision uses the
uninstrumented timings and paired process-level memory records in this
directory.

The SHA-256 manifest intentionally excludes itself and this explanatory
README. Verify it from this directory with:

```sh
shasum -a 256 -c evidence-sha256.txt
```

Quick mode times only balanced size 100 and retains one sample for each of the
four primary and nine rejection lanes. Its 13 warm, 13 fresh, and 13 memory
records are a harness smoke test, not decision evidence.

Run a noise-policy retry into a different directory so both raw runs survive.
`--replace` is intended only for disposable quick output.
