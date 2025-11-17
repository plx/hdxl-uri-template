# HDXLURITemplate - Test Failures Guide

## Summary

**Total Tests:** 78
**Passing:** 78 ✅
**Failing:** 0
**Pass Rate:** 100% 🎉

All tests are now passing!

---

## Recently Fixed Issues

### ✅ Percent-Encoded Variable Names (FIXED - Current Session)

**Problem:** When a variable **name** (not value) contains percent-encoded characters, those characters were being double-encoded.

**Example:**
```
Template: /lookup{?Stra%C3%9Fe}
Input:    Variable name "Stra%C3%9Fe" with value "Grüner Weg"
Before:   /lookup?Stra%25C3%259Fe=Gr%C3%BCner%20Weg ❌
Fixed!    /lookup?Stra%C3%9Fe=Gr%C3%BCner%20Weg ✅
```

**Root Cause:**
The `escapedVariableName` method was calling `rawValue.escaped(forValueExpansionType:)` which re-encoded the percent characters in variable names. Per RFC 6570 Section 2.3, percent-encoded triplets in variable names are "considered an essential part of the variable name and are not decoded during processing."

**Fix Applied:**
Changed `URITemplateVariableName+TextVariableNameExpansion.swift:28` to return `rawValue` directly instead of encoding it:
```swift
-    guard let escapedName = rawValue.escaped(forValueExpansionType: expansionType) else {
-      return .failure
-    }
-    return .escaped(escapedName)
+    // Per RFC 6570 Section 2.3:
+    // Variable names can only contain ALPHA, DIGIT, "_", and pct-encoded triplets.
+    // All these characters are safe in URIs. Percent-encoded triplets in variable
+    // names are considered essential and must not be re-encoded (per RFC 6570 Section 2.3).
+    // Therefore, variable names should be used as-is without additional encoding.
+    return .escaped(rawValue)
```

**Rationale:**
Variable names (per RFC 6570 Section 2.3) can only contain:
- ALPHA (a-z, A-Z)
- DIGIT (0-9)
- Underscore (_)
- Percent-encoded triplets (%XX)

All these characters are safe in URIs and don't require additional encoding. The percent-encoded triplets are validated during parsing and are part of the variable name itself.

**Location:** `Sources/HDXLURITemplate/Detail/ValueExpansion/URITemplateVariableName+TextVariableNameExpansion.swift:28`

---

### ✅ Prefix Modifier with Special Characters (FIXED - Current Session)

**Problem:** When using a prefix modifier (`:N`) to truncate a value containing `/` characters, the `/` was not being percent-encoded in path segment expansion.

**Example:**
```
Template: {/list*,path:4}
Input:    path = "/foo/bar"
Expected: /red/green/blue/%2Ffoo
Fixed!   Previously: /red/green/blue//foo
```

**Root Cause:**
The `pathSegmentAllowedCharacterSet` incorrectly included `/` as an allowed character. Per RFC 6570, `/` should only be used as a separator between path segments, not within values.

**Fix Applied:**
Removed `/` from the `pathSegmentAllowedCharacterSet` in `CharacterSet+URIValueExpansion.swift:86`:
```swift
-internal let pathSegmentAllowedCharacterSet: CharacterSet = labelAllowedCharacterSet.union(
-  CharacterSet(charactersIn: "/")
-)
+internal let pathSegmentAllowedCharacterSet: CharacterSet = labelAllowedCharacterSet
```

**Location:** `Sources/HDXLURITemplate/Detail/ValueExpansion/CharacterSet+URIValueExpansion.swift:86`

---

## Test Execution Details

**Command:** `swift test`

**Current Status:**
```
✅ Test run with 78 tests in 0 suites passed after ~2 seconds.
```

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
