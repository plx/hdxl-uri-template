# ``HDXLURITemplate``

Parse and expand strict RFC 6570 URI templates with immutable, `Sendable`
Swift values.

## Overview

HDXLURITemplate implements RFC 6570 Level 4. Parse source once with
``URITemplate/init(parsing:)``, construct runtime parameters with
``URIVariableValue``, and then expand to either a string or a Foundation URL.

The package preserves the exact accepted template source. Parsing is strict,
ordered lists and associations retain their order, association keys are
unique, and structured errors separate safe default diagnostics from explicit
recovery context.

> Important: The initial package contract is Swift-only. Objective-C wrappers,
> generated selectors, and wrapper archives are unsupported. Add an
> application-owned Swift boundary if an Objective-C target needs to call the
> package.

## Topics

### Essentials

- <doc:Parsing-Templates>
- <doc:Expanding-Templates>
- <doc:Modeling-Variable-Values>
- <doc:Operators-and-Modifiers>
- <doc:Handling-Errors-and-Diagnostics>
- <doc:Persistence-and-Codable>
- <doc:Concurrency-Performance-and-Input-Limits>

### Core Types

- ``URITemplate``
- ``URIVariableValue``
- ``URIVariableValueType``

### Structured Errors

- ``URITemplate/ParseError``
- ``URITemplate/EvaluationError``
- ``URIVariableValue/AssociationError``
