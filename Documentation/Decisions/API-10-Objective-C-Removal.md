# API-10 Objective-C removal evidence

Status: implemented for the initial Swift-only `0.x` contract

Decision: [API-08 Objective-C support decision](./API-08-Objective-C-Support.md)

Tracking issue: [#81](https://github.com/plx/hdxl-uri-template/issues/81)

## Outcome

The unsupported pre-release Objective-C facade has been removed. The package
now exposes only its native Swift contract and no longer contains:

- the `HDXLURITemplate` or `HDXLURIVariableValue` wrapper classes;
- Objective-C exposure of `HDXLURIVariableValueType`;
- wrapper-only `NSCopying`, `NSCoding`, or `NSSecureCoding` behavior;
- the `HDXLURITemplateObjCInterop` SwiftPM target or its `.m` and public-header
  fixture; or
- wrapper-specific unit tests and archive proxies.

No native Swift template, value, association-invariant, Codable, expansion, or
error contract was removed.

## Generated-interface comparison

Both snapshots were produced with Xcode 26.6 (`17F113`), Swift 6.3.3, and the
SwiftBuild backend from the package state before and after this removal.

At the base commit `732a4ee6bfc02591ce6feb96b1e9b87ea3a3e2b1`, the canonical generated
`HDXLURITemplate-Swift.h` was 463 lines and 18,631 bytes, with SHA-256:

```text
1ec893f8463967bd966d1d4d9c2d33d919813e79f6d9bbd1c6577cf7a30b282e
```

It exposed:

```text
380:@interface HDXLURITemplate : NSObject <NSCopying, NSSecureCoding>
404:typedef SWIFT_ENUM_NAMED(uint8_t, HDXLURIVariableValueType, ...)
415:@interface HDXLURIVariableValue : NSObject <NSCopying, NSSecureCoding>
```

After removal, the canonical generated header is 382 lines and 12,881 bytes,
with SHA-256:

```text
505cbc5e8c6bde432c06adbcd8502390c01e1ac966143de696c98aa076103b33
```

It contains none of these exact forbidden markers:

```text
@interface HDXLURITemplate :
@interface HDXLURIVariableValue :
HDXLURIVariableValueType
```

`Scripts/check-public-api.swift` now builds through SwiftBuild, requires exactly
the two canonical generated headers from the package and external-consumer
builds, and fails if any forbidden marker reappears. The three markers live in
`Documentation/API/HDXLURITemplate.public-api.json` so the absence requirement
is reviewable and versioned.

## Removed implementation and fixtures

Production wrapper sources:

```text
Sources/HDXLURITemplate/ObjC/HDXLURITemplate.swift
Sources/HDXLURITemplate/ObjC/HDXLURIVariableValue.swift
```

Package fixture:

```text
Tests/HDXLURITemplateObjCInterop/HDXLURITemplateObjCInterop.m
Tests/HDXLURITemplateObjCInterop/include/HDXLURITemplateObjCInterop.h
```

Wrapper-only test files:

```text
Tests/HDXLURITemplateTests/DoubleCoverage/ObjCAssociationInvariantTests.swift
Tests/HDXLURITemplateTests/DoubleCoverage/ObjCDoubleCoverageTests.swift
```

Wrapper calls and archive tests were also removed from shared test files. The
Swift association tests remain and continue to cover unique-key validation,
duplicate rejection, insertion ordering, dictionary ordering, JSON and
property-list decoding, round trips, expansion, large inputs, and privacy-safe
bridged errors.

## Compatibility and migration

The removed facade had no supported release or identified consumer, and the
initial public contract is explicitly Swift-only. Code based on a pre-release
snapshot must migrate as follows:

- replace `HDXLURITemplate` construction and inspection with
  `URITemplate.init(parsing:)`, `templateRepresentation`, and `variableNames`;
- replace wrapper values with `URIVariableValue.undefined`, `text(_:)`,
  `list(_:)`, and the `association` factories;
- inspect native values through `URIVariableValue.valueType` and the
  `is…Value` properties; and
- replace wrapper archives with the documented native Swift Codable formats.

Archives of `HDXLURITemplate` and `HDXLURIVariableValue` are unsupported and
are not migrated or decoded by this package. An Objective-C application that
needs URI-template behavior must own an application-specific Swift bridge.

## Validation

The complete matrix passed locally on July 26, 2026:

```text
Xcode 26.6 / Swift 6.3.3
  just test-all
  Debug, HEAVY_DEBUG, Release: pass
  generated-header absence contract: pass (2 headers)

Xcode 27.0 beta / Swift 6.4
  just test-all
  Debug, HEAVY_DEBUG, Release: pass
  generated-header absence contract: pass (2 headers)
```

Additional inventory checks confirmed that the dumped package contains no
`HDXLURITemplateObjCInterop` target, `Sources` and `Tests` contain no `.m`,
`.mm`, or `.h` file, and production/test sources contain no `@objc` exposure.
