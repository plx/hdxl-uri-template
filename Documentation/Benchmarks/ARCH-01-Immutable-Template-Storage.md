# ARCH-01: immutable template storage

Tracking issue: [#31](https://github.com/plx/hdxl-uri-template/issues/31)

## Decision

`URITemplate` retains one internal reference allocation, but the referenced
`URITemplateStorage` is now genuinely immutable:

- every stored property is a `let`;
- parsing initializes the exact validated source, parsed components, and
  distinct public variable names together;
- no getter mutates a cache or acquires a lock;
- storage is compiler-checked `Sendable`, without `@unchecked Sendable`;
- no COW uniqueness check, mutator, cache reset, global cache, hidden
  synchronization, or unsafe pointer lifetime exists; and
- equality and hashing continue to use parsed components, while semantic
  `Codable` continues to use the exact source string.

A final immutable class was selected over the default plain-struct direction
because the measured struct candidate made every `URITemplate` six times
larger and materially regressed copies. The reference is an ownership and
copy-size choice, not retained mutable or COW machinery.

## Benchmark method

The permanent `HDXLURITemplateARCH01Benchmark` executable measures:

- parsing without touching `variableNames`, so eager metadata cost remains
  visible;
- repeated copies through a bounded array ring;
- a fixed total of 2,000,000 warm representation, variable-name, and equality
  reads at 1, 2, 4, and 8 workers;
- repeated expansion;
- retained allocator blocks and bytes for 100,000 copies; and
- retained allocator blocks and bytes for 5,000 unique parsed templates.

Every timed workload is warmed before seven raw samples are collected. The
reported value is the median. Stable result digests reject semantic or
nondeterministic drift. The retained-memory figures are point-in-time
`malloc_zone_statistics` deltas while the arrays remain alive; they are useful
for same-process comparison but are not total transient allocation counts.

The executable also reports `MemoryLayout<URITemplate>` size and stride. The
Release executable size is recorded separately with `stat`; it is a whole
benchmark-product comparison, not a library ABI or stripped-client-size
claim.

Environment:

- Apple Silicon `arm64`, 16 logical cores;
- Apple Swift 6.4 (`swiftlang-6.4.0.25.4`, `clang-2100.3.25.1`);
- Release configuration; and
- the same machine, harness, workload, and seven-sample method for both
  revisions.

The before production source was exact merge-base
`9b6a378129de62d7367b89ef18c5f439130a4c4b`. The benchmark target and recipe
were present in the measurement worktree, but no production source change was
present. The after production source and permanent harness were exact commit
`96c48fa99e4d0cf0005119c27766ebb829c7839c`.

Commands:

```console
ARCH01_SWIFT_VERSION='Apple Swift 6.4 (swiftlang-6.4.0.25.4 clang-2100.3.25.1)' \
  just arch-01-benchmark before-locked-reference \
  9b6a378129de62d7367b89ef18c5f439130a4c4b

ARCH01_SWIFT_VERSION='Apple Swift 6.4 (swiftlang-6.4.0.25.4 clang-2100.3.25.1)' \
  just arch-01-benchmark after-immutable-reference \
  96c48fa99e4d0cf0005119c27766ebb829c7839c

stat -f '%z' .build/out/Products/Release/HDXLURITemplateARCH01Benchmark
```

## Results

Median timing:

| Workload | Before ns/op | After ns/op | Change | Before/after |
| --- | ---: | ---: | ---: | ---: |
| Parse | 3,572.021 | 3,774.521 | +5.669% | 0.946x |
| Copy | 5.893 | 5.860 | -0.566% | 1.006x |
| Warm metadata, 1 worker | 35.047 | 15.919 | -54.578% | 2.202x |
| Warm metadata, 2 workers | 142.666 | 7.899 | -94.463% | 18.061x |
| Warm metadata, 4 workers | 204.142 | 4.074 | -98.005% | 50.114x |
| Warm metadata, 8 workers | 208.441 | 2.230 | -98.930% | 93.454x |
| Expansion | 5,292.712 | 5,261.973 | -0.581% | 1.006x |

Retained memory and product size:

| Measurement | Before | After | Change |
| --- | ---: | ---: | ---: |
| `URITemplate` size / stride | 8 / 8 bytes | 8 / 8 bytes | unchanged |
| 100,000-copy blocks / bytes | 1 / 802,816 | 1 / 802,816 | unchanged |
| 5,000-parse blocks | 34,127 | 34,317 | +0.557% |
| 5,000-parse bytes | 2,720,640 | 3,042,752 | +11.840% |
| Release benchmark executable | 820,768 bytes | 807,824 bytes | -1.577% |

The eager variable-name set produces the expected bounded parse and retained
memory cost. In return, all warm reads are immutable and lock-free, sequential
metadata latency falls by more than half, and the prior parallel slowdown is
replaced by near-geometric scaling through eight workers. Copy size, copy
latency, expansion latency, and retained copy memory do not regress.

## Rejected plain-struct candidate

The same harness was run against an intermediate plain immutable struct:

| Measurement | Locked reference | Immutable struct |
| --- | ---: | ---: |
| `URITemplate` size / stride | 8 / 8 bytes | 48 / 48 bytes |
| Copy ns/op | 5.893 | 26.111 |
| 100,000-copy retained bytes | 802,816 | 4,800,512 |
| Parse ns/op | 3,572.021 | 4,064.758 |

Although the struct removed contention, the 4.43x copy-latency regression,
sixfold value-size increase, and roughly 4 MB of additional retained memory
for 100,000 copies were not justified. The selected final immutable reference
delivers the same lock removal without those copy costs.

## Permanent verification

- `just check-immutable-template-storage` rejects lock imports, unfair locks,
  unchecked storage sendability, lazy cache helpers, and COW uniqueness checks.
- Characterization covers empty, literal-only, expression-only, mixed,
  repeated-variable, and Unicode templates across source, names, copies,
  equality, hashing, expansion, and semantic `Codable`.
- A targeted concurrent test repeatedly reads source, names, equality, hash,
  and expansion from one shared template.
- The external public consumer exercises immutable copies and the same
  composite reads without `@testable`.
- The complete QA-03 concurrency runner retains at least 100,000 mixed
  operations per phase for Thread Sanitizer execution.
