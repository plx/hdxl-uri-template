# API-03 compiled-cache decision

Status: final decision; the predeclared no-cache default is retained.

## Default

Do not add a compiled-template cache API.

API-02's exact validated source string remains the public and durable
representation. A compiled sidecar is disposable and can never be the sole
copy of a template.

## Threshold for reconsideration

A follow-up design issue is justified only if all of the following hold:

1. every correctness, corruption, version, source-mismatch, and fallback check
   passes;
2. the lower confidence bound for the validated sidecar's speedup is at least
   2× for realistic balanced 1,000- and 10,000-template collections;
3. that result holds in both warmed and fresh-process measurements;
4. direct reparsing exceeds the approximately 10 ms startup budget for the
   documented 1,000-template consumer workload, and the sidecar produces a
   meaningful absolute saving; and
5. encoded size, peak memory, fallback latency, and implementation complexity
   remain acceptable.

No threshold may change after final samples are observed. If reparsing remains
within approximately 10 ms, no documented consumer requires a lower budget,
results remain noisy, or only an unsafe or prototype-only path reaches 2×, the
decision remains no cache.

## Prototype boundary

The API-03 sidecar is research code outside `Sources/HDXLURITemplate` and
outside the package's public products. A valid hit returns a benchmark-only
compiled value rather than constructing `URITemplate` from private storage.
A rejected sidecar falls back to public parsing of a separately retained
authoritative source.

Even a positive result authorizes only a new, separately reviewed design issue.
It does not authorize shipping the prototype, reopening semantic `Codable`, or
adding an invariant-bypassing initializer.

## Implementation complexity

At protocol freeze, `wc -l` reports 1,383 physical Swift lines for the compiled
prototype plus stable-digest helper, 4,285 lines for the complete benchmark
support and executable, 1,445 lines for the evidence driver, and 855 lines for
the API-03 regression file. These totals include comments and blank lines, but
they make the review and maintenance surface concrete.

The larger harness is intentionally conservative research infrastructure, not
a proposed production design. Even the 1,383-line cache core is substantial
next to direct use of the existing parser. A future design issue would have to
justify and substantially simplify that validation, integrity, invalidation,
and fallback surface; benchmark speed alone cannot make the prototype
shippable.

## Final result

Do not open a follow-up compiled-cache design issue.

The accepted clean Release run measured commit
`d4434e2ab7114168e0508f8d9ee2a9a9c2611ef9` under Xcode 26.6/Swift 6.3.3.
The complete raw evidence and environment record are retained in
[`../Benchmarks/Data/API-03/`](../Benchmarks/Data/API-03/). The frozen
thresholds resolve as follows:

| Criterion | Accepted evidence | Result |
| --- | --- | --- |
| Correctness, corruption, versioning, source correspondence, and fallback | The pre-timing gate passed all 234 positive pinned cases, all generated-corpus checks, all nine rejection lanes, and exact fixture pins. The post-run evidence validators also passed. | Passes the prerequisite |
| At least 2× lower confidence bound at 1,000 and 10,000 templates | Warm direct/cache speedup was 0.267× [0.265, 0.267] and 0.266× [0.266, 0.268]. Fresh-process speedup was 0.310× [0.306, 0.312] and 0.281× [0.280, 0.283]. Values below 1 mean the cache was slower. | Fails |
| Benefit in both warm and fresh modes | The prototype was about 3.2–3.8 times slower than direct parsing in the four realistic balanced comparisons. Repeated/unique sensitivity collections agreed. | Fails |
| Direct reparse exceeds the approximately 10 ms 1,000-template budget and cache saves meaningful time | Direct reparsing took 4.907 ms warm and 6.546 ms in the fresh child. Fresh launch-to-exit was 15.888 ms only after including fixed process startup; the cache increased it to 30.585 ms. | Fails |
| Acceptable size, memory, fallback, and complexity | The sidecar plus source was 3.73×/4.18× the direct input size at 1,000/10,000 templates. At 10,000, median maximum RSS rose 47.8% and peak footprint 63.5%. Most rejection lanes paid validation plus reparse. The cache core alone is 1,383 physical Swift lines. | Fails |

The sole positive finding is that the versioned, integrity-protected prototype
can reject every modeled invalid sidecar and recover by parsing the separately
retained source. That demonstrates the required safety boundary, not a
performance case for shipping it.

API-02's exact validated source remains the only durable template
representation. Direct parsing remains the implementation default. The
benchmark prototype stays outside `Sources/HDXLURITemplate` and outside the
package's public products; it must not be promoted into production code.
