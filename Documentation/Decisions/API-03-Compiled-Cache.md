# API-03 compiled-cache decision

Status: default decision recorded before final measurement.

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

Pending reproducible Release measurements on the final post-restack commit.
