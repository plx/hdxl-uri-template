# API-03: reparsing and compiled-cache benchmark

Status: final clean Release measurement accepted; no compiled cache
recommended.

## Research question

Does a separately versioned, disposable compiled sidecar provide enough
end-to-end startup benefit to justify a new design ticket, after integrity,
source correspondence, rejection, and fallback costs are included?

The durable representation remains API-02's exact validated source string.
The benchmark must not weaken that contract or construct public templates from
decoded private storage.

## Compared operations

The primary balanced comparison measures:

1. direct parsing of in-memory authoritative source strings with
   `URITemplate.init(parsing:)`;
2. JSON decoding of API-02's semantic `[URITemplate]` representation;
3. binary-property-list decoding of the same semantic representation; and
4. validation and decoding of the benchmark-only compiled sidecar.

The compiled hit yields a separately named prototype value. It does not yield
a public `URITemplate`, because the production module intentionally has no
non-parsing initializer. Its timing is an optimistic lower bound. Correctness
tests project parsed internal components into the prototype only from the test
target and compare exact source, variables, and pinned expansions.

Separate rejection measurements cover unsupported versions, truncation,
corrupt integrity, stale authoritative sources, source/payload mismatch, and
structurally invalid payloads. Every rejected sidecar reparses the separately
supplied authoritative sources exactly once.

## Deterministic workloads

The fixed generator seed is `0x4844_584C_4150_4903`. SHA-256 digests use
length-prefixed UTF-8 source bytes; Swift's randomized `Hasher` is never used
for corpus identity.

Balanced collections contain 1, 10, 100, 1,000, and 10,000 templates. Every
complete ten-entry block contains:

- two literal-only templates, one ASCII and one Unicode;
- eight expression templates covering simple, reserved, fragment, label, path
  segment, path parameter, query, and query-continuation operators;
- short and long variable lists;
- scalar prefix and explode modifiers; and
- all-unique sources for the one- and ten-entry workloads so the ten-entry
  collection retains all ten literal/operator categories; collections of 100
  or more use exactly 25% repeated occurrences and 75% unique sources, with
  duplicates kept inside the same archetype category.

Maximally repeated and all-unique sensitivity collections are measured at
1,000 and 10,000 entries. The maximally repeated collections retain one source
for each of the ten archetypes and repeat those ten sources; this preserves the
operator and literal mixture rather than reducing the workload to one
archetype. Every generated source is publicly parsed before timing.

## Correctness gate

Timing is invalid unless all of these checks pass first:

- all 234 positive cases from the four pinned suites parse, expand, and project
  to the same prototype components;
- generated category counts, source digests, and collection sizes match their
  checked-in contract;
- direct, JSON, property-list, and prototype paths produce the same stable
  source-and-variable digest;
- a valid sidecar hit invokes no fallback parser;
- every rejection class invokes fallback exactly once and returns the same
  public parse result;
- an invalid authoritative fallback source returns a controlled parse error;
- encoded sizes include every byte required by each operation; and
- the four pinned fixture files and their provenance remain unchanged.

The checked-in driver runs the focused Release test gate in its own SwiftPM
scratch directory before building the measurement executable. It also verifies
the byte count and SHA-256 pin for each of the four fixture files and the
checked-in provenance README. The sanitized test-and-fixture log is retained
and hashed in the environment record.

No correctness traversal is inside a timed interval. Each timed result is
consumed into a stable SHA-256 digest to prevent optimizer removal.

## Persisted-input and size accounting

Fresh-process direct parsing and semantic JSON decoding read the same semantic
JSON array. The direct lane decodes it as `[String]` and then invokes the public
parser; the semantic lane decodes it as `[URITemplate]`, whose API-02
implementation invokes the same parser. Binary-property-list decoding reads
only its property-list representation.

The compiled sidecar is not authoritative. Its fresh-process hit and rejection
lanes therefore read both the semantic JSON source array and the selected
sidecar. Reported compiled and fallback byte sizes are the sum of those two
files, including the intentionally duplicated source strings embedded in the
sidecar. No lane reads another strategy's input file inside its timed interval.
Each child loads and validates a small, source-free workload descriptor before
the operation timer begins. Generated authoritative sources are not retained in
the fresh child unless the selected lane reads and decodes them.

## Warm protocol

The Release executable is built once with stable Xcode and invoked directly,
never through `swift run`.

The four primary operations run against all nine primary and sensitivity
collections. The nine rejection/fallback operations run against the balanced
1,000- and 10,000-template collections. For each retained configuration:

1. prepare the corpus and encoded data outside the timed interval;
2. execute five untimed single-operation priming calls;
3. double a fixed repetition count on the warmed path until one batch lasts at
   least 200 ms;
4. execute five untimed calibrated warm-up batches;
5. if any candidate retained batch falls below 200 ms, discard that
   configuration's candidates, double the repetition count, and repeat the
   five warm-up batches;
6. retain six batches in each of five fresh worker processes; and
7. preserve all 30 raw samples without outlier deletion.

The primary and rejection configurations are combined and shuffled once per
worker with the fixed seed and worker index. Samples record integer
nanoseconds, repetitions, template operations, encoded bytes, corpus digest,
and result digest. The driver rejects any retained warm batch below 200 ms and
requires process indices 0 through 4 with exactly six batches each.

## Fresh-process and memory protocol

Fresh-process evidence uses the same configuration scope as the warm protocol:
all nine collections for the four primary operations, and balanced 1,000 and
10,000 for the nine rejection/fallback operations. It uses 30 new child
processes per configuration after three untimed launches that warm the
filesystem and dynamic-loader caches. This is not a cold-disk claim.
All configurations are prewarmed before retention. The 30 retained process
indices form 30 rounds, with one child per configuration in each round and a
fixed-seed configuration shuffle recomputed per round. Samples for one lane are
therefore not collected as one contiguous time block.

The child operation timer includes persisted-input reads, decoding or parsing,
sidecar validation or fallback, and result-digest consumption. The coordinator
records launch-to-exit wall time separately.

For balanced 1,000- and 10,000-template collections, at least five retained
samples per operation run under:

```sh
/usr/bin/time -lp <release-binary> single-shot ...
```

Raw maximum-resident-set-size and peak-memory-footprint values are retained.
The raw `/usr/bin/time` `real` text is also retained as a coarse seconds string;
its 10 ms display resolution is not an independent latency measure.
Allocation traces are separate diagnostic runs under stable Xcode's
`xctrace` Allocations template; instrumented timings never enter the primary
latency comparison.

## Statistics and noise policy

Every configuration reports raw samples, median, nearest-rank p95, minimum,
maximum, interquartile range, median absolute deviation, relative MAD,
templates per second, nanoseconds per template, encoded bytes, and bytes per
template.

The p95 index is `ceil(0.95 × sampleCount) - 1` after sorting. Deterministic
10,000-resample bootstrap intervals cover median latency and speedup ratios.
Warm intervals use hierarchical resampling of the five independent worker
process clusters and then their six batches; warm speedup resampling pairs the
selected process index across lanes and draws batches independently within
each selected process. Five top-level clusters make percentile intervals
necessarily coarse. Fresh-process latency and launch intervals use ordinary
iid resampling of the 30 independent child processes.

Summary rows record independent process count and minimum/maximum batches per
process. Process indices must be unique within one benchmark campaign; evidence
from separate campaigns with reset process indices must never be concatenated.

A warm relative MAD above 5% or fresh-process relative MAD above 10% requires a
complete rerun after quieting the host. Both runs remain evidence. Persistent
noise is inconclusive and cannot justify a cache.

## Required environment record

The evidence records:

- benchmark commit and clean-worktree state;
- Release compiler flags and binary SHA-256;
- Mac model, chip, core count, and memory, without serial number, UUID, user
  name, or other device identifiers;
- actual macOS version and build;
- Xcode and exact Swift 6.3 versions;
- AC-power and thermal state;
- before/after timestamps;
- the pre-timing validation command, status, completion time, sanitized-log
  name, and SHA-256; and
- the evidence-validator result and number of configurations over the frozen
  noise thresholds.

The current host runs macOS 27.0. Results from it do not establish a macOS 26
runtime result.

## Raw evidence

Compact JSON Lines samples, an environment record, corpus manifest, and summary
CSV belong under `Documentation/Benchmarks/Data/API-03/`. Large Instruments
traces may be attached separately, but their SHA-256 values and export commands
must be recorded here. The sanitized pre-timing gate is retained in
`correctness-validation.txt`. The three sanitized Release `swiftc` invocations
for the production library, benchmark support, and runner are retained in
`release-swiftc-invocations.txt`; checkout and scratch paths are replaced with
stable placeholders, and both files' SHA-256 values are recorded in the
environment file.

## Final measurement

The accepted run measured clean commit
`d4434e2ab7114168e0508f8d9ee2a9a9c2611ef9` from
`2026-07-26T18:46:52Z` through `2026-07-26T19:09:22Z`. It used Xcode 26.6
build `17F113`, Apple Swift 6.3.3, and the Release configuration on an Apple
M4 Max Mac with 16 physical/logical cores and 64 GiB of memory. The host was
on AC power with no recorded thermal or performance warning. The actual
runtime was macOS 27.0 build `26A5378n`; this is not a macOS 26 runtime
result.

The pre-timing correctness and fixture gate passed. Post-run validation
accepted exactly 1,620 warm, 1,620 fresh-process, and 1,620 memory records
covering all 54 frozen configurations, plus all 108 summary rows and three
Release compiler invocations. The largest relative MAD was 1.1677% for warm
evidence and 4.3572% for fresh-process evidence, below the frozen 5% and 10%
rerun thresholds. No sample was deleted.

Post-measurement review hardened the harness without rewriting any accepted
artifact: malformed partial warm comparisons now fail with a diagnostic,
elapsed-duration overflow cannot collide with the launch-unavailable sentinel,
fresh launch substitution is staged and validated before append, and full
runs fail before artifact creation unless the recorded Xcode, Swift, and macOS
environment matches the frozen protocol. The reviewed summarizer regenerated
`summary.csv` byte-for-byte from the retained raw files. A disposable quick run
also passed the complete harness validators. These checks validate the
retained evidence; they do not replace or relabel the measured commit.

The following values are milliseconds per operation. Parenthesized values are
nearest-rank p95. A direct-parse speedup below 1 means the prototype sidecar is
slower than direct parsing.

| Mode | Templates | Direct parse | Semantic JSON | Binary plist | Prototype cache | Direct/cache speedup, 95% CI |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Warm | 1,000 | 4.907 (4.969) | 5.166 | 5.682 | 18.406 (18.719) | 0.267× [0.265, 0.267] |
| Fresh process | 1,000 | 6.546 (6.739) | 6.584 | 7.189 | 21.143 (21.551) | 0.310× [0.306, 0.312] |
| Warm | 10,000 | 49.201 (49.963) | 51.819 | 56.804 | 184.718 (187.326) | 0.266× [0.266, 0.268] |
| Fresh process | 10,000 | 54.900 (55.887) | 55.740 | 60.948 | 195.255 (273.151) | 0.281× [0.280, 0.283] |

The optimistic prototype hit was therefore about 3.2–3.8 times slower than
direct parsing for the realistic balanced collections. Fresh launch-to-exit
medians tell the same story: 15.888 ms direct versus 30.585 ms prototype at
1,000 templates, and 64.651 ms versus 205.063 ms at 10,000. The 1,000-template
direct reparse itself remained below the approximately 10 ms consumer budget
in both modes. Although fixed child-process startup raises the full fresh
launch above 10 ms, the sidecar increases rather than reduces that total.

The all-repeated and all-unique 1,000/10,000 sensitivity collections did not
reveal a favorable cache case. Their warm cache speedups were 0.266–0.267× and
their fresh-process speedups were 0.283–0.311×. The all-unique 10,000 warm
interval has an unusually low 0.096× lower bound because one of only five
top-level worker clusters was slow; the predeclared hierarchical interval is
intentionally coarse and was not replaced. Its median still agrees with every
other realistic collection and it cannot support a positive cache claim.

The smallest fresh-process microcases do not change that conclusion. At one
template, the prototype's internal operation timer was 3.409× faster but saved
only 0.698 ms, and launch-to-exit speedup was 1.079×. At ten templates,
operation speedup was 1.937× [1.887, 1.974], below the 2× threshold, with only
1.060× launch speedup. The cache was slower for both warmed microcases and for
every balanced collection from 100 templates upward.

The confidence intervals describe one prewarmed host and do not quantify
cross-machine or cold-disk variation. That limitation cannot reverse this
negative decision: the predeclared balanced-size intervals are narrow and
entirely below 1×.

### Size and peak memory

At 1,000 templates the sidecar plus authoritative source occupied 282,484
bytes versus 75,701 bytes for direct/semantic JSON, or 3.73× as much. At
10,000 templates it occupied 3,166,503 bytes versus 757,001 bytes, or 4.18× as
much.

The following `/usr/bin/time -lp` results are MiB. Each cell is median (p95)
across the 30 fresh-process samples paired with the latency evidence.

| Templates | Operation | Maximum RSS | Peak memory footprint |
| ---: | --- | ---: | ---: |
| 1,000 | Direct parse | 9.24 (9.39) | 4.34 (4.48) |
| 1,000 | Prototype cache | 9.80 (10.03) | 5.06 (5.28) |
| 10,000 | Direct parse | 20.85 (21.25) | 15.95 (16.34) |
| 10,000 | Prototype cache | 30.82 (32.41) | 26.07 (27.67) |

Against direct parsing, the prototype's median RSS and peak footprint rose by
6.1% and 16.6% at 1,000 templates, then by 47.8% and 63.5% at 10,000. These
figures are process-level peaks, not allocation attribution; instrumented
allocation diagnostics are reported separately below and are excluded from
latency evidence.

### Rejection and fallback

All nine rejection lanes produced their pinned controlled outcomes and the
same final public parse result. The truncated lane rejected before full
sidecar validation and remained near direct parsing: 5.073/6.777 ms warm/fresh
at 1,000 templates and 50.878/56.595 ms at 10,000. The other lanes paid both
validation and reparse costs. Their warm medians ranged from 18.420 to 22.498
ms at 1,000 and 183.339 to 224.857 ms at 10,000; fresh medians ranged from
21.985 to 26.348 ms and 195.231 to 237.188 ms, respectively. Fallback is
correct and deterministic, but it is not a performance advantage.

### Allocation diagnostic attempt

An Allocations trace could not be collected on this host. An exact
`git archive` of measured commit `d4434e2` was built in an external scratch
directory with Xcode 26.6/Swift 6.3.3. The source-equivalent diagnostic binary
was 1,622,176 bytes with SHA-256
`2542644d40099a69e2ef88d91d826f205012e6489b1bd86a0c389fa216ddb8dc`.
After preparing the full deterministic inputs, the direct balanced-10,000
diagnostic was launched with the following sanitized command:

```sh
DEVELOPER_DIR=/Applications/Xcode.app xcrun xctrace record \
  --template Allocations \
  --output <TRACE> \
  --target-stdout <TARGET_OUTPUT> \
  --no-prompt --launch -- \
  <BINARY> single-shot \
  --directory <INPUTS> \
  --workload balanced-10000 \
  --operation direct-parse \
  --commit d4434e2ab7114168e0508f8d9ee2a9a9c2611ef9 \
  --process-index 0 --sample-index 0
```

The recorder printed its launch message but left the child stopped before
user code, emitted no target output, and never finalized the trace. A bounded
retry added `--time-limit 10s` and used process index 1, but it remained stuck
beyond that limit in the same state. Both incomplete bundles failed:

```sh
DEVELOPER_DIR=/Applications/Xcode.app xcrun xctrace export \
  --input <TRACE> --toc
```

The export exited 10 with `Export failed: Document Missing Template Error`.
The unbounded and bounded partial 48,128-byte tar archives had SHA-256 values
`9ca7c7a678a1a9b1d49926dd7fb018c78c233702e3ca38781593d6bd88101e10`
and
`ebac40f9da36c877ea649a62cf23e82a11f6e2dad0d425152df3acfe4b8251fd`,
respectively. They contain no usable template, allocation table, or target
measurement and are not accepted or checked in as evidence. Prototype-cache
tracing was not attempted after the repeated infrastructure-level startup
failure.

No allocation-count or allocated-byte claim is made. The decision rests on
the successful uninstrumented latency evidence and paired `/usr/bin/time -lp`
RSS/peak-footprint evidence. Missing allocation attribution limits diagnostic
detail but cannot turn the measured cache regression into a positive result.

## Interpretation

The decision thresholds were fixed before observing final samples and are
recorded in
[`../Decisions/API-03-Compiled-Cache.md`](../Decisions/API-03-Compiled-Cache.md).
Only validated end-to-end results count toward a positive decision. The
prototype failed the speed, startup-budget, encoded-size, peak-memory, and
complexity criteria. The default remains direct parsing of API-02's exact
validated source, and no follow-up compiled-cache design issue is justified.
