# API-03 raw benchmark evidence

The final benchmark run writes:

- `environment.json`;
- `correctness-validation.txt`;
- `corpus-manifest.json`;
- `raw-warm.jsonl`;
- `raw-fresh-process.jsonl`;
- `raw-memory.jsonl`; and
- `summary.csv`;
- `release-swiftc-invocations.txt`.

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

Quick mode times only balanced size 100 and retains one sample for each of the
four primary and nine rejection lanes. Its 13 warm, 13 fresh, and 13 memory
records are a harness smoke test, not decision evidence.

Run a noise-policy retry into a different directory so both raw runs survive.
`--replace` is intended only for disposable quick output.
