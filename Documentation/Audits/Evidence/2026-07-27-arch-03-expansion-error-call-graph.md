# ARCH-03 expansion error call graph

Tracking issue: [#37](https://github.com/plx/hdxl-uri-template/issues/37)

## Decision

URI-template value escaping is total for every valid Swift `String`. Text,
list, and association expansion therefore remain nonthrowing below the
semantic value boundary.

The only supported value-expansion failure is applying a prefix modifier to a
list or association. One internal `URIVariableValue.ExpansionError` case
carries the variable name, operator, prefix length, and value flavor. Typed
throws propagate exactly that category to `evaluateAsString(parameters:)`,
which converts it into the documented public `URITemplate.EvaluationError`.

`evaluate(parameters:)` retains its separate, post-expansion URL-construction
failure. No controlled failure was replaced with an assertion, precondition,
or trap.

## Revisions

- Before inventory:
  `d3cb1b52b46180f559fedbd03af4fdc09f3f9999`
- Narrowed implementation:
  `82f1db4b3fa1a21684b47fc79225b07037be019e`

## Removed unreachable errors

No production expression constructed any of these cases. Each case described
a failure of `String.escaped(forValueExpansionType:)` or a total wrapper around
it, while the current escaping implementation returns `String` directly.

| Removed declaration | Cases | Why unreachable |
| --- | ---: | --- |
| `URIVariableTextValue.ExpansionError` | 3 | Text, variable-name, and combined value escaping are nonthrowing. |
| `URIVariableListValue.ExpansionError` | 2 | Element and variable-name escaping are nonthrowing. |
| `URIVariableAssociationValue.ExpansionError` | 2 | Association key and value escaping are nonthrowing. |
| **Total** | **7** | No throw site existed at the before revision. |

Their payload-retaining `LocalizedError` helpers were deleted with the
unconstructable enums. The test-only construction of three text-error cases
was also removed; manufacturing an unreachable case did not exercise a
supported behavior.

## Removed throwing declarations

The following 12 leaf declarations now return `String` directly:

| Value layer | Nonthrowing declarations | Reason |
| --- | --- | --- |
| Text | `escapedContents`; both `expansion` overloads | Each path delegates to total string escaping and formatting. |
| List | both `expansion` overloads; `explodedRepresentation`; `explodedExpansion`; `unexplodedExpansion` | Mapping, escaping, and joining cannot fail. |
| Association | both `expansion` overloads; `explodedExpansion`; `unexplodedExpansion` | Validated ordered pairs are mapped, escaped, and joined without a failing operation. |

`ExpansionThrowingBoundaryTests` is a compile-time contract for all 12
signatures. It also requires each retained internal propagation function to
use typed `throws(URIVariableValue.ExpansionError)`.

## Retained throwing graph

```text
URITemplate.evaluateAsString(parameters:)              public throws
  -> URITemplateExpressionComponent.evaluate           typed ExpansionError
    -> URITemplateVariable.evaluateIfDefined/evaluate  typed ExpansionError
      -> URIVariableValue.evaluate                      typed ExpansionError
        -> text/list/association expansion leaves      nonthrowing

URITemplate.evaluate(parameters:)                      public throws
  -> evaluateAsString(parameters:)                     expansion failure
  -> URL(string:)                                      distinct invalidURL failure
```

`URIVariableValue.evaluate` rejects a runtime list or association paired with
a parsed prefix modifier. Its single error case stores the prefix code-point
count directly, so an impossible unmodified/explode error state cannot be
constructed. The public wrapper maps that typed case once into
`.prefixModifierNotApplicable`.

## Behavioral coverage

The existing composite-prefix matrix covers:

- all eight RFC expression operators;
- nonempty and empty lists;
- nonempty and empty associations; and
- both public evaluation entry points.

That is 64 public rejection combinations. Scalar prefixes, undefined values,
and empty composites without a prefix retain their successful behavior. The
complete 270-case pinned conformance runner remains green, and URL rejection
is exercised independently.

The implementation revision was tested with:

```console
swift test --enable-code-coverage
```

All 203 Debug tests passed. The generated LLVM report recorded:

| Source | Lines | Functions | Regions |
| --- | ---: | ---: | ---: |
| `URIVariableValue+Evaluation.swift` | 57/57 (100%) | 6/6 (100%) | 16/16 (100%) |
| `URITemplateVariable+Evaluation.swift` | 36/36 (100%) | 4/4 (100%) | 11/11 (100%) |
| `URITemplateExpressionComponent+Evaluation.swift` | 18/18 (100%) | 1/1 (100%) | 7/7 (100%) |
| `URITemplate+Evaluation.swift` | 155/158 (98.1%) | 16/17 (94.1%) | 42/45 (93.3%) |

Line counts show the internal composite-prefix throw executed 95 times, the
public expansion catch executed 79 times, and the distinct invalid-URL throw
executed 8 times. The difference between internal and public counts comes from
direct internal boundary tests.

Reproduce the line counts with the code-coverage path printed by
`swift test --show-codecov-path` and:

```console
xcrun llvm-cov show \
  .build/arm64-apple-macosx/debug/HDXLURITemplatePackageTests.xctest/Contents/MacOS/HDXLURITemplatePackageTests \
  -instr-profile=.build/arm64-apple-macosx/debug/codecov/default.profdata \
  -show-line-counts-or-regions \
  Sources/HDXLURITemplate/URIVariableValue+Evaluation.swift
```
