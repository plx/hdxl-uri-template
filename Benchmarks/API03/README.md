# API-03 compiled-cache research

This directory contains the disposable research harness for API-03. It
compares direct parsing with API-02 semantic JSON and binary-property-list
decoding, plus an optimistic benchmark-only compiled sidecar.

The support and executable targets are deliberately absent from the package's
public products. Nothing here changes `URITemplate`'s semantic-string `Codable`
contract, adds a storage initializer, or exposes a supported cache API.

The compiled sidecar retains:

- an explicit format version;
- the authoritative source strings;
- a typed component payload;
- a SHA-256 integrity value; and
- exact UTF-8 source/payload correspondence checks.

The caller supplies the authoritative source collection separately because the
sidecar is disposable. A rejected cache falls back once through
`URITemplate.init(parsing:)`. A valid prototype hit returns a benchmark-only
compiled value, not a `URITemplate`; it is therefore an optimistic lower bound,
not a shippable implementation.

See
[`Documentation/Benchmarks/API-03-Compiled-Cache-Benchmark.md`](../../Documentation/Benchmarks/API-03-Compiled-Cache-Benchmark.md)
for the frozen measurement protocol and
[`Documentation/Decisions/API-03-Compiled-Cache.md`](../../Documentation/Decisions/API-03-Compiled-Cache.md)
for the predeclared decision rule.

Build and run through the checked-in driver so the stable toolchain, Release
flags, sample counts, persisted-input preparation, raw records, and environment
metadata stay together:

```sh
Scripts/run-api-03-benchmarks.sh --quick --output /tmp/api-03-smoke
Scripts/run-api-03-benchmarks.sh
```

Quick mode is a bounded harness smoke test and cannot support the architecture
decision. Full decision evidence must begin from a clean worktree at the exact
recorded commit. The driver refuses to overwrite an existing evidence set
unless `--replace` is explicit; use a new output directory for noise-policy
reruns so both runs remain available.
