# HDXLURITemplate - Project Overview

## What This Project Is

HDXLURITemplate is a Swift implementation of RFC 6570 (URI Template), ported from a private Objective-C implementation. URI Templates provide a standardized way to construct URIs with variable substitution and various expansion rules.

**Example:** The template `{+path}/file{.ext}{?query}` with parameters `{path: "/foo/bar", ext: "json", query: "test"}` expands to `/foo/bar/file.json?query=test`.

## Project Status

- **Platform:** Swift 6.0+ (strict language mode)
- **Package:** Swift Package Manager library
- **Supported Platforms:** iOS 26+, macOS 26+, tvOS 26+, watchOS 26+, visionOS 26+, macCatalyst 26+
- **Dependencies:** None (pure Swift implementation)
- **Test Status:** 22 of ~78 tests currently failing (see TEST_FAILURES.md)

## Architecture Overview

### Public API (Consumer-Facing)

The library exposes a minimal public interface:

1. **`URITemplate`** - Main struct for parsed URI templates
   - Parse templates via initializer: `URITemplate("{/path}{?query}")`
   - Evaluate with parameters: `template.evaluate(with: parameters)`
   - Full `Codable` support for serialization

2. **`URIVariableValue`** - Represents substitution values
   - Four types: undefined, text (string), list (array), association (key-value pairs)
   - Convenience initializers for all types
   - Also `Codable`

3. **`URITemplateParseError`** - Parse error reporting

4. **Objective-C Bridge** (`HDXLURITemplate`, `HDXLURIVariableValue`)
   - Legacy interop layer for ObjC codebases

### Internal Implementation

The implementation is organized into logical modules under `Sources/HDXLURITemplate/Detail/`:

#### 1. Parsing Layer (`Detail/Parsing/`)

Converts template strings into internal representation:

- **`URITemplateLiteralComponent+Parsing`** - Parses literal text segments
- **`URITemplateExpressionComponent+Parsing`** - Parses `{...}` expressions
- **`URITemplateVariable+Parsing`** - Parses variable declarations (name + modifiers)
- **`URIValueExpansionType+Parsing`** - Recognizes expansion operators (+, #, ., /, ;, ?, &)
- **`URIValueExpansionModifier+Parsing`** - Handles length/prefix modifiers (`:N`, `*`)
- **Support utilities:** `Scanner+URITemplateParsing`, string decomposition helpers

#### 2. Template Component Types (`Detail/TemplateComponent/`)

Internal representation of parsed templates:

- **`URITemplateComponent`** - Enum: `.literal` | `.expression`
- **`URITemplateLiteralComponent`** - Raw text (no substitution)
- **`URITemplateExpressionComponent`** - Variable expansion block with type + variables
- **`URITemplateExpressionComponent+Evaluation`** - Expression evaluation logic

#### 3. Variable System (`Detail/Variable/`)

Represents variables within expressions:

- **`URITemplateVariable`** - Variable with name + expansion modifier
- **`URITemplateVariableName`** - Validated variable name
- **`URITemplateVariable+Evaluation`** - Variable-level expansion logic

#### 4. Variable Value System (`Detail/VariableValue/`)

Runtime values for substitution:

- **`URIVariableValueType`** - Enum: undefined | text | list | association
- **`URIVariableValueData`** - Internal storage (enum wrapping specific types)
- **`URIVariableTextValue`** - String values
- **`URIVariableListValue`** - Array values
- **`URIVariableAssociationValue`** - Key-value dictionary
- **`URIVariablePairValue`** - Single key-value pair

#### 5. Value Expansion Engine (`Detail/ValueExpansion/`)

Core expansion logic implementing RFC 6570:

- **`URIValueExpansionType`** - 8 expansion types:
  - `.simple` (default): `{var}`
  - `.reserved`: `{+var}` (allows reserved chars)
  - `.fragment`: `{#var}` (fragment identifier)
  - `.label`: `{.var}` (dot-prefixed labels)
  - `.pathSegment`: `{/var}` (path segments)
  - `.pathParameter`: `{;var}` (path-style parameters)
  - `.query`: `{?var}` (query strings)
  - `.queryContinuation`: `{&var}` (query continuation)

- **`URIValueExpansionModifier`** - Expansion modifiers:
  - `.unmodified` (default)
  - `.prefix(N)` (truncate to N chars: `:N`)
  - `.explode` (expand lists/associations: `*`)

- **`String+URIValueExpansion`** - Core percent-encoding logic
- **`CharacterSet+URIValueExpansion`** - Character class definitions per RFC 6570
- **Expansion implementations:** Type-specific logic for text/list/association values

#### 6. Storage and Caching (`Detail/Template/`)

- **`URITemplateStorage`** - Internal class holding parsed components
  - Thread-safe caching with `OSAllocatedUnfairLock`
  - Copy-on-write semantics via struct wrapper

#### 7. Support Utilities (`Detail/Support/`)

- Assertions, error descriptions, regex helpers
- String manipulation (prefix, suffix, substring, last component)
- Codable support via `StandardEnumerationCodingKeys`
- Character set utilities

## Test Structure

Tests are organized into two main categories:

### 1. Specification Tests (`Tests/.../Specification/`)

RFC 6570 compliance validation:

- **`SpecificationTests.swift`** - Main spec test runner
- **`SpecificationParsingTests.swift`** - Template parsing validation
- **Test data files:**
  - `spec-examples.json` - Official RFC examples (Levels 1-4)
  - `spec-examples-by-section.json` - Organized by RFC section
  - `extended-tests.json` - Additional test cases
  - `negative-tests.json` - Error/invalid input tests
- **Support infrastructure:** Test case models, JSON decoding, verification helpers

### 2. Unit Tests (`Tests/.../Detail/`)

Component-level testing (26 test files):

- **TemplateComponent tests** (3 files) - Component types and structure
- **ValueExpansion tests** (5 files) - Expansion logic for each type
- **Variable tests** (2 files) - Variable naming and structure
- **VariableValue tests** (6 files) - Value types and conversions
- **Support tests** (7 files) - String manipulation, utilities
- **Hand-checked cases** - Manually verified edge cases

## Data Flow

### Template Parsing (Initialization)

```
Template String → Scanner
  ↓
Parse Components (literal | expression)
  ↓
For each expression:
  - Parse expansion type (+, #, ., /, ;, ?, &)
  - Parse variable list
  - For each variable:
    * Parse name
    * Parse modifier (:N or *)
  ↓
URITemplateStorage → URITemplate
```

### Template Evaluation (Expansion)

```
URITemplate + [String: URIVariableValue] → evaluate()
  ↓
For each component:
  - Literal → emit as-is
  - Expression → expand()
    * For each variable:
      - Lookup in parameters
      - Apply expansion type rules
      - Apply modifier (prefix/explode)
      - Percent-encode per character set
      - Format per expansion type
    * Join results per expansion type
  ↓
Concatenate all results → URI String
```

## Key Design Patterns

1. **Value Semantics with Internal Caching**
   - Public structs wrap internal classes
   - Thread-safe locks protect cached data
   - Immutable public API

2. **Strong Type Safety**
   - Newtype wrappers for strings (variable names, text values)
   - Exhaustive enum switching
   - Swift 6 strict concurrency mode

3. **RFC 6570 Compliance Focus**
   - 8 expansion types exactly per spec
   - Character sets match ABNF definitions
   - Test suite validates against official examples

4. **Zero Dependencies**
   - Pure Swift implementation
   - Uses only Foundation types (minimal)
   - No external packages

## Build Configuration

Build tasks via `justfile`:

- `just build-debug` - Standard debug build
- `just build-heavy-debug` - Debug with `-DHEAVY_DEBUG` (extra assertions)
- `just build-release` - Optimized release build
- `just test-debug` / `just test-release` - Run tests

Compiler flags:
- Swift 6.0+ language mode (strict)
- `-DHEAVY_DEBUG` enables pedantic runtime checks
- `@usableFromInline` for performance-critical internals

## Known Limitations / Current Issues

See `TEST_FAILURES.md` for detailed breakdown, but high-level issues:

1. **Percent-encoding of already-encoded input** (10 failures)
   - Values like `admin%2F` not handled per RFC rules

2. **Association (key-value) explode formatting** (5 failures)
   - `{.keys*}`, `{/keys*}`, etc. not expanding correctly

3. **Malformed percent-encoded values** (4 failures)
   - Values like `%foo` (incomplete encoding) cause crashes

4. **Empty value formatting** (1 failure)
   - Empty strings in path parameters not formatted correctly

5. **Prefix modifier edge cases** (1 failure)
   - Prefix with special characters in paths

6. **Missing variable handling** (1 failure)
   - Template references undefined variable

## Where to Look for Specific Functionality

| Task | Primary Location | Supporting Files |
|------|------------------|------------------|
| **Parse a template** | `URITemplate.swift` | `Detail/Parsing/*` |
| **Evaluate/expand** | `URITemplate+Evaluation.swift` | `Detail/ValueExpansion/*` |
| **Handle specific expansion type** | `URIValueExpansionType.swift` | Type-specific expansion files |
| **Percent-encoding logic** | `String+URIValueExpansion.swift` | `CharacterSet+URIValueExpansion.swift` |
| **Variable value creation** | `URIVariableValue.swift` | `Detail/VariableValue/*` |
| **Modifier handling (prefix/explode)** | `URIValueExpansionModifier.swift` | Variable/value evaluation files |
| **Character set rules** | `String+RFCConstants.swift` | `CharacterSet+URIValueExpansion.swift` |
| **Error handling** | `URITemplateParseError.swift` | `DataValidationError.swift` |
| **Test running** | `SpecificationTests.swift` | `Resources/*.json` |

## Next Steps for Development

Based on test failures, priority work items:

1. **Fix percent-encoding handling** - Core issue affecting 10+ tests
2. **Fix association explode** - 5 related failures
3. **Handle malformed input gracefully** - 4 crash cases
4. **Edge case fixes** - Empty values, prefix modifiers, missing variables

See `TEST_FAILURES.md` for detailed analysis and suggested approaches.
