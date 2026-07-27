# Public API contract

Run the checked public API contract with:

```console
just check-public-api
```

The check emits a fresh public symbol graph with the active Swift toolchain and
compares selected conformances and members against
`HDXLURITemplate.public-api.json`. The baseline is intentionally focused: it
protects explicit API decisions without treating every symbol-graph detail as a
permanent compatibility promise.

The same command also builds `Tests/PublicAPIConsumer` as a separate package.
That fixture cannot access `internal` or `package` declarations and verifies
that the retained value contracts remain usable by an external client.

The contract also inspects every `HDXLURITemplate-Swift.h` that the compiler
emits and rejects the removed Objective-C wrapper classes and enum. A missing
canonical generated header fails the check so the absence assertion cannot
silently pass without inspecting the compiler output. The package's initial
supported contract is Swift-only.
