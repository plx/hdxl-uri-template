# DOC-02 supported public documentation and DocC gate

Date: July 27, 2026

Tracking issue:
[DOC-02/#40](https://github.com/plx/hdxl-uri-template/issues/40)

Baseline revision:
`f393aa31f0d196ad10dbf678d56563f6ca7ba100`

Implementation revision:
`bee30fc06fca722892a9cad5fa9793d1fdf59fef`

## Baseline characterization

The baseline had no DocC catalog or documentation-build command. Its Swift
symbol graph contained 93 supported public declarations. Nineteen lacked a
direct source abstract, including variable-value flavor cases, evaluation
error categories and descriptions, both evaluation entry points, and
Foundation association-error properties. The two synthesized
`RawRepresentable` initializers also required explicit DocC documentation.

The README gate compiled two synchronized examples in a separate consumer
package, but there was no equivalent contract for conceptual documentation,
DocC links, warning cleanliness, parameter/return documentation, or complete
symbol coverage. Some existing type comments also described internal storage
mechanics instead of limiting themselves to externally observable contracts.

## Supported documentation contract

The package now has a DocC landing page and focused guides for:

- strict parsing and exact source preservation;
- string expansion versus Foundation URL construction and application safety;
- undefined, text, list, and ordered unique-key association values;
- every RFC 6570 operator, explode and prefix modifiers, Unicode, and
  percent-encoded input;
- structured errors, Foundation bridging, privacy-safe default diagnostics,
  and sensitive recovery context;
- semantic `URITemplate.Codable`, the runtime-only variable-value model, and
  application-owned persistence DTOs; and
- `Sendable` use, reuse and performance characteristics, and application-owned
  input and output limits.

The landing page makes the settled Swift-only contract explicit. Objective-C
wrappers, selectors, and wrapper archives remain unsupported. Public source
comments now document the previously uncovered declarations and avoid
promising internal parser or value-storage representation.

## Compiled examples and coverage gate

`Scripts/check-docc.swift` enforces the catalog from a fresh temporary build:

1. every authored catalog page must begin with a level-one title followed by a
   prose abstract;
2. exactly six Swift code blocks must each match one external-consumer source
   file byte-for-byte;
3. the package is built with tests before SwiftPM emits a public-only symbol
   graph for `HDXLURITemplate`;
4. only that library graph is supplied to DocC;
5. DocC runs with diagnostics as errors, analysis, inherited documentation,
   parameter/return validation, documentation coverage, and GitHub source
   links; and
6. every symbol or module entry in `documentation-coverage.json` must have an
   abstract.

The six examples comprise the two existing README examples plus four DocC
examples for operators/modifiers, structured diagnostics, persistence, and
concurrency/input limits. `just check-docc` depends on the existing public API
gate, so all six examples compile and run as a package consumer without
`@testable` in both Debug and Release before DocC conversion runs.

The implementation revision produced this coverage:

| DocC category | Documented | Result |
| --- | ---: | ---: |
| Types | 8/8 | 100% |
| Members | 85/85 | 100% |
| Module/global landing | 1/1 | 100% |

The 94 DocC coverage entries represent all 93 supported public declarations
plus the documented module landing page. The conversion emitted no warnings,
link failures, or other diagnostics. The separate authored-page check covers
all ten catalog Markdown pages, including the seven conceptual guides.

## Failure-oriented detector

`Scripts/test-check-docc.sh` first accepts the clean catalog, then proves that
the checks fail for four temporary mutations:

- a DocC code block that no longer matches its compiled source;
- a landing-page topic reference to a nonexistent article; and
- a conceptual article with its abstract removed; and
- an external-consumer example calling a nonexistent public API.

The mutations and builds stay in validated temporary directories and do not
alter tracked source. Core CI runs both the positive gate and these negative
controls in its Swift 6.3 Debug lane.

## Validation record

Validation used Xcode 26.6 and Apple Swift 6.3.3:

```sh
just check-docc
just test-check-docc
just test-all
xcrun swift-format lint --strict <all changed Swift files>
sh -n Scripts/test-check-docc.sh
git diff --check
```

Results:

- the public API gate built and ran the separate consumer in Debug and Release,
  checked the public symbol graph, and verified three generated
  Objective-C-header absence surfaces;
- the DocC gate synchronized all six compiled examples and documented every
  supported declaration without warnings or unresolved links;
- all four deliberately broken documentation/consumer controls were rejected;
- Debug passed 204 tests;
- `HEAVY_DEBUG` and Release each passed 205 tests;
- the complete pinned conformance runner passed all 270 cases in every lane;
  and
- strict Swift formatting, shell syntax, Justfile parsing, and whitespace
  checks passed.
