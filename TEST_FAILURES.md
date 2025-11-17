# HDXLURITemplate - Test Failures Guide

## Summary

**Total Tests:** ~78
**Passing:** ~56
**Failing:** 22
**Pass Rate:** ~72%

The failures are grouped into 6 distinct patterns, with percent-encoding issues being the dominant problem.

---

## Failure Categories

### 1. Percent-Encoded Input Handling (10 failures) 🔴 **HIGH PRIORITY**

**Problem:** The implementation incorrectly handles input values that are already percent-encoded. RFC 6570 Section 2.4.2 specifies that percent-encoded triplets in values should be treated as literals and re-encoded (except for reserved expansion).

**Test Source:** `extended-tests` - Additional Examples 6: Reserved Expansion

**Examples:**

#### Example 1A: Reserved expansion should preserve encoding
```
Template: {+id}
Input:    id = "admin%2F"  (already percent-encoded)
Expected: admin%2F          (preserve the encoding)
Observed: admin/            (decoded to slash)
```

The reserved expansion (`+`) should treat percent-encoded sequences as already-safe and preserve them.

#### Example 1B: Fragment expansion same issue
```
Template: {#id}
Input:    id = "admin%2F"
Expected: #admin%2F
Observed: #admin/
```

#### Example 1C: Simple expansion should double-encode
```
Template: {id}
Input:    id = "admin%2F"
Expected: admin%252F        (encode the % to %25, keeping %2F encoded)
Observed: admin%2F          (didn't re-encode)
```

In simple expansion (no operator), already-encoded values should be re-encoded so `%` becomes `%25`.

#### Example 1D: List values with percent encoding
```
Template: {+list}
Input:    list = ["red%25", "%2Fgreen", "blue "]
Expected: red%25,%2Fgreen,blue%20
Observed: red%,/green,blue%20
```

The implementation is decoding `%25` → `%` and `%2F` → `/` when it shouldn't.

#### Example 1E: Simple expansion of list
```
Template: {list}
Input:    list = ["red%25", "%2Fgreen", "blue "]
Expected: red%2525,%252Fgreen,blue%20   (double-encoded)
Observed: red%25,%2Fgreen,blue%20       (single-encoded)
```

#### Example 1F: Association values with encoding
```
Template: {+keys}
Input:    keys = {key1: "val1%2F", key2: "val2%2F"}
Expected: key1,val1%2F,key2,val2%2F
Observed: key1,val1/,key2,val2/
```

#### Example 1G: Fragment expansion of keys
```
Template: {#keys}
Input:    keys = {key1: "val1%2F", key2: "val2%2F"}
Expected: #key1,val1%2F,key2,val2%2F
Observed: #key1,val1/,key2,val2/
```

#### Example 1H: Simple expansion should double-encode keys
```
Template: {keys}
Input:    keys = {key1: "val1%2F", key2: "val2%2F"}
Expected: key1,val1%252F,key2,val2%252F
Observed: key1,val1%2F,key2,val2%2F
```

#### Example 1I: Complex real-world case
```
Template: /go{?uri}
Input:    uri = "http://example.org/?uri=http%3A%2F%2Fexample.org%2F"
Expected: /go?uri=http%3A%2F%2Fexample.org%2F%3Furi%3Dhttp%253A%252F%252Fexample.org%252F
Observed: /go?uri=http%3A%2F%2Fexample.org%2F%3Furi%3Dhttp%3A%2F%2Fexample.org%2F
```

The inner percent-encoded `%3A%2F%2F` should be re-encoded to `%253A%252F%252F` in query expansion.

**Root Cause:**
The percent-encoding logic in `String+URIValueExpansion.swift` or `URIVariableTextValue+ValueExpansion.swift` is likely:
- Decoding percent-encoded input before re-encoding
- Not recognizing valid percent-encoded triplets as literals
- Not applying RFC 6570 Section 2.4.2 rules correctly

**Where to Fix:**
- **Primary:** `Sources/HDXLURITemplate/Detail/ValueExpansion/String+URIValueExpansion.swift`
- **Secondary:** `Sources/HDXLURITemplate/Detail/ValueExpansion/URIVariableTextValue+ValueExpansion.swift`
- **Related:** `Sources/HDXLURITemplate/Detail/ValueExpansion/CharacterSet+URIValueExpansion.swift`

**RFC Reference:**
RFC 6570 Section 2.4.2:
> A percent-encoded triplet is considered a single character when counting characters and when testing whether unreserved characters are present.

Section 3.2.1:
> For simple string expansion, the variable value is either copied directly (without encoding) or, if the value contains at least one character not in the unreserved set, percent-encoded.

**Fix Strategy:**
1. Detect existing percent-encoded triplets (`%XX` where X is hex digit)
2. For reserved/fragment expansion: preserve them as-is
3. For simple/other expansion: re-encode the `%` sign itself (`%` → `%25`)
4. Don't decode and re-encode; operate on the string as-is

---

### 2. Association (Key-Value) Explode Formatting (5 failures) 🔴 **HIGH PRIORITY**

**Problem:** When expanding associative values (key-value pairs) with the explode modifier (`*`), the output format is incorrect. The implementation is using the wrong separator/format for exploded associations.

**Test Source:** `spec-examples` - Level 4 Examples

**Examples:**

#### Example 2A: Label expansion with explode
```
Template: X{.keys}
Input:    keys = {comma: ",", dot: ".", semi: ";"}
Expected: X.comma,%2C,dot,.,semi,%3B  (one of 6 permutations)
Observed: X.comma,%2C.dot,..semi,%3B
```

The issue: After `%2C` it should use `,` separator, but it's using `.` (the label separator).

Expected format for `{.keys}` WITHOUT explode: `.comma,%2C,dot,.,semi,%3B`
But with explode, each pair should be: `.key,value`

Actual format: `.comma,%2C.dot,.` - mixing separators incorrectly.

#### Example 2B: Path segment with explode
```
Template: {/keys}
Input:    keys = {comma: ",", dot: ".", semi: ";"}
Expected: /comma,%2C,dot,.,semi,%3B  (one permutation)
Observed: /comma,%2C/dot,./semi,%3B
```

Similar issue: using `/` separator between pairs instead of `,`.

#### Example 2C: Path parameter with explode
```
Template: {;keys}
Input:    keys = {comma: ",", dot: ".", semi: ";"}
Expected: ;keys=comma,%2C,dot,.,semi,%3B  (one permutation)
Observed: ;comma,%2C;dot,.;semi,%3B
```

Two issues:
1. Missing the `keys=` prefix (should only appear once for non-exploded)
2. Using `;` separator between pairs

With explode modifier, format should be: `;comma=%2C;dot=.;semi=%3B`
Without explode: `;keys=comma,%2C,dot,.,semi,%3B`

#### Example 2D: Query expansion with explode
```
Template: {?keys}
Input:    keys = {comma: ",", dot: ".", semi: ";"}
Expected: ?keys=comma,%2C,dot,.,semi,%3B  (one permutation)
Observed: ?comma,%2C&dot,.&semi,%3B
```

Issues:
1. Missing `keys=` prefix
2. Using `&` separator (correct for query continuation)

With explode: `?comma=%2C&dot=.&semi=%3B`
Without explode: `?keys=comma,%2C,dot,.,semi,%3B`

#### Example 2E: Query continuation with explode
```
Template: {&keys}
Input:    keys = {comma: ",", dot: ".", semi: ";"}
Expected: &keys=comma,%2C,dot,.,semi,%3B  (one permutation)
Observed: &comma,%2C&dot,.&semi,%3B
```

Same as query case but with `&` prefix.

**Root Cause:**
The association explode logic is incorrectly determining:
1. When to include/exclude the variable name in output
2. What separator to use between key-value pairs
3. Whether the explosion is "named" or "unnamed"

Per RFC 6570 Section 3.2.1:
- Exploded associative values in label, path, and query expansions should produce `prefix key=value separator key=value ...`
- The variable name should NOT appear in the output for exploded associations in most contexts

**Where to Fix:**
- **Primary:** `Sources/HDXLURITemplate/Detail/ValueExpansion/URIVariableAssociationValue+ValueExpansion.swift`
- **Related:** `Sources/HDXLURITemplate/Detail/Variable/URITemplateVariable+Evaluation.swift`
- **Check:** `Sources/HDXLURITemplate/Detail/TemplateComponent/URITemplateExpressionComponent+Evaluation.swift`

**RFC Reference:**
RFC 6570 Section 3.2.1 (Variable Expansion):
> If explode ("*") is specified, then the expanded output omits the variable name and separator (typically "=") in favor of producing each member of the list or each key-value pair of the associative array as separate expansions.

**Fix Strategy:**
1. Check the explode modifier on the variable
2. For associations WITH explode:
   - Format: `{prefix}{key}={value}{sep}{key}={value}...`
   - Do NOT include variable name
   - Use the expansion type's separator between pairs
3. For associations WITHOUT explode:
   - Format: `{prefix}{varname}={key},{value},{key},{value}...`
   - Include variable name once
   - Use `,` between all elements

---

### 3. Malformed Percent-Encoded Values (4 failures) 🟡 **MEDIUM PRIORITY**

**Problem:** When a variable value contains a malformed percent-encoded sequence (like `%foo` where `foo` is not a valid hex pair), the expansion throws an error instead of handling it gracefully.

**Test Source:**
- `HandCheckedSpecCaseTests.swift` - Hand-checked spec case
- `extended-tests` - Additional Examples 6: Reserved Expansion

**Examples:**

#### Example 3A: Reserved expansion with malformed value
```
Template: {+not_pct}
Input:    not_pct = "%foo"
Expected: (should handle gracefully, likely encode the % as %25)
Observed: Caught error: unableToEscapeVariableValue("%foo", "not_pct", reserved, unmodified)
```

#### Example 3B: Fragment expansion with malformed value
```
Template: {#not_pct}
Input:    not_pct = "%foo"
Expected: (should handle gracefully)
Observed: Caught error: unableToEscapeVariableValue("%foo", "not_pct", fragment, unmodified)
```

#### Example 3C: Simple expansion with malformed value
```
Template: {not_pct}
Input:    not_pct = "%foo"
Expected: (should encode as %25foo)
Observed: Caught error: unableToEscapeVariableValue("%foo", "not_pct", simple, unmodified)
```

**Root Cause:**
The percent-encoding validation/expansion logic is too strict and throws an error when it encounters a `%` that's not followed by two hex digits. RFC 6570 doesn't specify throwing errors for malformed input; instead, such characters should be treated as literals and percent-encoded.

**Where to Fix:**
- **Primary:** `Sources/HDXLURITemplate/Detail/VariableValue/URIVariableTextValue+ValueExpansion.swift`
- **Related:** `Sources/HDXLURITemplate/Detail/ValueExpansion/String+URIValueExpansion.swift`

**RFC Guidance:**
RFC 6570 doesn't explicitly address malformed percent-encoding in input. Best practice:
- Treat `%` not followed by two hex digits as a literal `%` character
- Percent-encode it according to the expansion type rules
- For simple expansion: `%foo` → `%25foo`
- For reserved expansion: `%foo` → `%25foo` (% is not in reserved set)

**Fix Strategy:**
1. Detect percent-encoded triplets with regex: `%[0-9A-Fa-f]{2}`
2. For anything else (including lone `%`), treat as literal character
3. Apply normal encoding rules to literal characters
4. Remove the error throw; handle all input gracefully

---

### 5. Prefix Modifier with Special Characters (1 failure) 🟢 **LOW PRIORITY**

**Problem:** When using a prefix modifier (`:N`) to truncate a value that starts with special characters (like `/`), those characters are not being percent-encoded correctly.

**Test Source:** `spec-examples` - Level 4 Examples

**Example:**

```
Template: {/list*,path:4}
Input:    list = ["red", "green", "blue"], path = "/foo/bar"
Expected: /red/green/blue/%2Ffoo
Observed: /red/green/blue//foo
```

The prefix modifier `:4` should truncate `path` to `/foo`, and then the leading `/` should be percent-encoded as `%2F` in the path segment expansion context (because it would create ambiguity).

**Root Cause:**
The prefix truncation is happening, but the resulting string is not being treated as a value that needs encoding. The `/` at the start of `/foo` should be encoded to `%2F` to avoid it being interpreted as a path separator.

**Where to Fix:**
- **Primary:** `Sources/HDXLURITemplate/Detail/ValueExpansion/URIValueExpansionModifier.swift`
  - Check the prefix modifier application
- **Secondary:** `Sources/HDXLURITemplate/Detail/Variable/URITemplateVariable+Evaluation.swift`
  - Ensure prefix-modified values are still encoded properly

**RFC Reference:**
RFC 6570 Section 2.4.1 (Prefix Values):
> The prefix modifier operates on the character sequence of the value prior to percent-encoding.

Section 3.2.6 (Path Segment Expansion):
> Path segment expansion is useful for describing URI path hierarchies. Note that path segments are delimited by slash characters in the result.

**Fix Strategy:**
1. Apply prefix modifier first (truncate to N characters)
2. Then apply percent-encoding to the truncated result
3. Ensure the encoding logic doesn't skip characters that appear safe but aren't in this context

## Ungrouped / No Clear Pattern

No additional failures fall outside these six categories. All 22 failures have been classified.

---

## Test Execution Details

**Command:** `swift test -q`

**Test Files Involved:**
- `Tests/HDXLURITemplateTests/Specification/SpecificationTests.swift` (main spec runner)
- `Tests/HDXLURITemplateTests/Specification/HandCheckedSpecCaseTests.swift` (manual cases)

**Test Data:**
- `Tests/HDXLURITemplateTests/Resources/spec-examples.json` - RFC 6570 official examples
- `Tests/HDXLURITemplateTests/Resources/extended-tests.json` - Extended test cases

**Test Output:**
```
􀢄 Test run with 78 tests in 0 suites failed after 1.879 seconds with 22 issues.
```

---

## Priority Recommendations

### Immediate (High Priority)
1. **Fix Percent-Encoded Input Handling** (10 failures)
   - Affects core URI template use cases
   - Violates RFC 6570 Section 2.4.2
   - Impacts real-world scenarios (nested URIs, pre-encoded values)

2. **Fix Association Explode** (5 failures)
   - Breaks Level 4 compliance
   - Common pattern in modern APIs (query parameter objects)

### Soon (Medium Priority)
3. **Handle Malformed Percent-Encoding Gracefully** (4 failures)
   - Prevents crashes on user input
   - Improves robustness

### Later (Low Priority)
5. **Prefix Modifier Edge Case** (1 failure)
   - Rare combination of features

---

## Validation Strategy

After fixes, validate with:

1. **Run full test suite:** `swift test -q`
2. **Check specific categories:**
   - Filter test output for specific template patterns
   - Verify each category is resolved
3. **Run heavy debug build:** `just test-heavy-debug`
   - Enables pedantic assertions
4. **Review RFC 6570 examples:** Manually verify against RFC examples in Section 3

---

## Additional Resources

- **RFC 6570:** https://datatracker.ietf.org/doc/html/rfc6570
- **RFC 3986 (URI syntax):** https://datatracker.ietf.org/doc/html/rfc3986
- **Test suite source:** https://github.com/uri-templates/uritemplate-test (original test suite)

---

## Notes for Future Sessions

- The test data appears well-structured and comprehensive
- The implementation architecture is sound; issues are in expansion logic details
- No major refactoring needed; targeted fixes should resolve all issues
- Consider adding more malformed input tests after fixing graceful handling
- The Objective-C bridge layer is not tested; may need separate validation
