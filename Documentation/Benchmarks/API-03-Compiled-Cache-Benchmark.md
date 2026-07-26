# API-03: reparsing and compiled-cache benchmark

Status: protocol frozen before final measurement; results pending.

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

## Interpretation

The decision thresholds were fixed before observing final samples and are
recorded in
[`../Decisions/API-03-Compiled-Cache.md`](../Decisions/API-03-Compiled-Cache.md).
Only validated end-to-end results count toward a positive decision. An
optimistic prototype-only speedup is insufficient.
