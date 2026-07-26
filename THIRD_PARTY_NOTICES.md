# Third-party notices

Project-authored HDXLURITemplate material is available under the MIT terms in
[`LICENSE`](LICENSE). Those terms remain separate from the third-party terms
recorded here and do not replace them.

This inventory records implementation provenance and redistribution notices.
It is not legal advice.

## `uri-templates/uritemplate-test` fixtures

The following files are unmodified snapshots from the official
[`uri-templates/uritemplate-test`](https://github.com/uri-templates/uritemplate-test)
repository at immutable commit
[`4171dac22aa67fc710b3f6df308a50bd08552986`](https://github.com/uri-templates/uritemplate-test/commit/4171dac22aa67fc710b3f6df308a50bd08552986):

- `Tests/HDXLURITemplateTests/Resources/spec-examples.json`
  - Cases: 64
  - Bytes: 6,650
  - SHA-256:
    `9148100604d25beb4fcc56b9d3a3ed6a0067d5f042bd472918030aff808f77be`
- `Tests/HDXLURITemplateTests/Resources/spec-examples-by-section.json`
  - Cases: 117
  - Bytes: 14,594
  - SHA-256:
    `0122630fddc249595045baef5122ccf41343c052d8524074920c9dc7bcd99543`
- `Tests/HDXLURITemplateTests/Resources/extended-tests.json`
  - Cases: 53
  - Bytes: 7,426
  - SHA-256:
    `547c6d6669132a62ea002791cbefed43251c7fe2ad82f8725d930d401e5acd23`
- `Tests/HDXLURITemplateTests/Resources/negative-tests.json`
  - Cases: 36
  - Bytes: 2,516
  - SHA-256:
    `7f4bd7def905c492b40fae92b6a51665489539dd773db464022a52eb37907e81`

The pinned upstream tree contains a `LICENSE` file and no `NOTICE` file. Its
complete application notice is:

> Copyright 2011- The Authors
>
> Licensed under the Apache License, Version 2.0 (the "License");
> you may not use this file except in compliance with the License.
> You may obtain a copy of the License at
>
>     http://www.apache.org/licenses/LICENSE-2.0
>
> Unless required by applicable law or agreed to in writing, software
> distributed under the License is distributed on an "AS IS" BASIS,
> WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
> See the License for the specific language governing permissions and
> limitations under the License.

The pinned upstream README separately says `Copyright 2011-2012 The Authors`.
Both upstream year forms are recorded here rather than silently choosing one;
neither file names individual copyright holders.

The complete Apache License 2.0 terms are reproduced in
[`LICENSES/Apache-2.0.txt`](LICENSES/Apache-2.0.txt).

The fixtures remain byte-for-byte upstream files. The following Swift tests
also copy or adapt upstream JSON examples or value tables:

- `Tests/HDXLURITemplateTests/Detail/Parsing/URIValueExpansionPrefixGrammarTests.swift`
- `Tests/HDXLURITemplateTests/Detail/Parsing/URITemplateExpressionGrammarTests.swift`
- `Tests/HDXLURITemplateTests/Detail/TemplateComponent/URITemplateLiteralGrammarTests.swift`
- `Tests/HDXLURITemplateTests/Detail/ValueExpansion/URICompositePrefixRejectionTests.swift`
- `Tests/HDXLURITemplateTests/Detail/ValueExpansion/HandCheckedSpecCaseTests.swift`
- `Tests/HDXLURITemplateTests/Detail/ValueExpansion/URITemplateLiteralExpansionTests.swift`
- `Tests/HDXLURITemplateTests/Detail/ValueExpansion/URIVariableListValue+ExpansionTests.swift`
- `Tests/HDXLURITemplateTests/Specification/SpecificationParsingTests.swift`

Those copied examples retain the applicable Apache and RFC notices. The
project-authored loading, decoding, and test-harness logic around them remains
under the project's MIT terms.

### Updating the fixture snapshot

Follow the commands in the
[fixture provenance record](Tests/HDXLURITemplateTests/Resources/README.md).
For every update:

1. Choose and review an immutable upstream commit.
2. Inspect every upstream `LICENSE` and `NOTICE` file, plus README copyright
   and attribution text, at that commit.
3. Replace all four JSON files together without local edits.
4. Compare every local file byte-for-byte with the pinned checkout.
5. Recompute case counts, byte counts, and SHA-256 digests.
6. Update this inventory, the fixture provenance record, and fixture-count
   tests in the same fixture-only change.
7. Update the reproduced license or notice files if upstream terms changed.
8. Run the pinned-fixture and complete conformance tests.

## Standards-derived Code Components

HDXLURITemplate implements
[RFC 6570](https://www.rfc-editor.org/rfc/rfc6570.html). RFC 6570 section 1.5
reproduces and imports core rules from
[RFC 5234](https://www.rfc-editor.org/rfc/rfc5234.html), URI definitions from
[RFC 3986](https://www.rfc-editor.org/rfc/rfc3986.html), and IRI definitions
from [RFC 3987](https://www.rfc-editor.org/rfc/rfc3987.html). The IETF Trust's
[Code Components list](https://trustee.ietf.org/documents/trust-legal-provisions/code-components-list-3/)
expressly includes ABNF definitions and tables of values.

The material categories and repository locations are:

- **URI Template grammar and literal tables.** RFC 6570 sections 2.1-2.3,
  plus verified
  [erratum 6937](https://www.rfc-editor.org/errata/eid6937), supply the
  expression, literal, and variable-name ABNF, scalar boundaries, regex
  inputs, and direct literal-expansion oracles in:
  - `Sources/HDXLURITemplate/Detail/TemplateComponent/URITemplateLiteralComponent.swift`
  - `Sources/HDXLURITemplate/Detail/Variable/URITemplateVariableName.swift`
  - `Tests/HDXLURITemplateTests/Detail/Parsing/URITemplateExpressionGrammarTests.swift`
  - `Tests/HDXLURITemplateTests/Detail/Parsing/URITemplateSourceRepresentationTests.swift`
  - `Tests/HDXLURITemplateTests/Detail/TemplateComponent/URITemplateLiteralGrammarTests.swift`
  - `Tests/HDXLURITemplateTests/Detail/ValueExpansion/URITemplateLiteralExpansionTests.swift`
  - `Tests/HDXLURITemplateTests/Specification/SpecificationParsingTests.swift`
- **Expansion metadata and rules.** RFC 6570 sections 2.2, 2.4.1-2.4.2,
  3.1, and 3.2.1-3.2.9 supply the formal operator and modifier rules,
  operator characters, prefixes, separators, allowed-character rules,
  literal ASCII set, and `1...9999` prefix range in:
  - `Sources/HDXLURITemplate/Detail/Parsing/URIValueExpansionModifier+Parsing.swift`
  - `Sources/HDXLURITemplate/Detail/ValueExpansion/CharacterSet+URIValueExpansion.swift`
  - `Sources/HDXLURITemplate/Detail/ValueExpansion/String+RFCConstants.swift`
  - `Sources/HDXLURITemplate/Detail/ValueExpansion/URITemplateLiteralComponent+ValueExpansion.swift`
  - `Sources/HDXLURITemplate/Detail/ValueExpansion/URITemplateVariableName+TextVariableNameExpansion.swift`
  - `Sources/HDXLURITemplate/Detail/ValueExpansion/URIValueExpansionModifier.swift`
  - `Sources/HDXLURITemplate/Detail/ValueExpansion/URIValueExpansionType.swift`
  - `Tests/HDXLURITemplateTests/Detail/ValueExpansion/URICompositePrefixRejectionTests.swift`
  - `Tests/HDXLURITemplateTests/Detail/ValueExpansion/URIPercentEncodedPrefixDifferentialTests.swift`
  - `Tests/HDXLURITemplateTests/Detail/ValueExpansion/URIPercentEncodedPrefixTests.swift`
  - `Tests/HDXLURITemplateTests/Detail/Parsing/URIValueExpansionPrefixGrammarTests.swift`
  - `Tests/HDXLURITemplateTests/Detail/ValueExpansion/URIVariableListValue+ExpansionTests.swift`
  - `Tests/HDXLURITemplateTests/Detail/ValueExpansion/ReservedCharacterSetTests.swift`
  - `Tests/HDXLURITemplateTests/DoubleCoverage/ParsingAndExpansionDoubleCoverageTests.swift`
- **Core and URI character sets.** RFC 6570 section 1.5 reproduces the
  RFC 5234 `ALPHA`, `DIGIT`, and `HEXDIG` rules and the RFC 3986 hexadecimal,
  percent-encoded, general-delimiter, sub-delimiter, reserved, and unreserved
  definitions in:
  - `Sources/HDXLURITemplate/Detail/ValueExpansion/CharacterSet+URIValueExpansion.swift`
  - `Sources/HDXLURITemplate/Detail/ValueExpansion/String+URIValueExpansion.swift`
  - `Tests/HDXLURITemplateTests/Detail/ValueExpansion/PercentEscapeScannerTests.swift`
  - `Tests/HDXLURITemplateTests/Detail/ValueExpansion/ReservedCharacterSetTests.swift`
  - `Tests/HDXLURITemplateTests/Detail/ValueExpansion/URIPercentEncodedPrefixTests.swift`
- **IRI scalar-range tables.** RFC 6570 section 1.5 reproduces the RFC 3987
  section 2.2 `ucschar` and `iprivate` ranges adapted in:
  - `Sources/HDXLURITemplate/Detail/ValueExpansion/CharacterSet+URIValueExpansion.swift`
  - `Tests/HDXLURITemplateTests/Detail/Support/InfalliblyUnwrapAssumptionTests.swift`
  - `Tests/HDXLURITemplateTests/Detail/TemplateComponent/URITemplateLiteralGrammarTests.swift`
  - `Tests/HDXLURITemplateTests/Detail/ValueExpansion/URIValueExpansionTypeTests.swift`
  - `Tests/HDXLURITemplateTests/DoubleCoverage/ParsingAndExpansionDoubleCoverageTests.swift`
- **Specification example and oracle tables.** RFC 6570 sections 1.2 and
  3.2, together with overlapping Apache-licensed upstream examples, supply
  templates, variable maps, and expected expansions in:
  - `Tests/HDXLURITemplateTests/Detail/ValueExpansion/HandCheckedSpecCaseTests.swift`
  - `Tests/HDXLURITemplateTests/Detail/ValueExpansion/URIVariableListValue+ExpansionTests.swift`
  - `Tests/HDXLURITemplateTests/Specification/SpecificationParsingTests.swift`
- **Audit excerpt.** The pre-release due-diligence report reproduces the
  `gen-delims` and `sub-delims` ABNF appearing in RFC 6570 section 1.5,
  originating in RFC 3986 section 2.2, and attributes that origin inline:
  - `Documentation/Audits/2026-07-25-pre-release-due-diligence.md`

Short RFC references and terminology, plus independently written parser,
expansion, loading, and test-harness logic elsewhere in the repository, are
normative citations or project-authored implementations. They remain under the
project's MIT terms. The inventory above conservatively treats functional
ABNF, tables, and their direct test or regex adaptations as Code Components.
A listed repository location scopes the third-party terms to the described
Code Component, not to the entire file or its surrounding project-authored
logic. This inventory records provenance and does not itself assert behavioral
equivalence to the standard.

### RFC 6570 disposition

The Code Components listed above are derived from IETF RFC 6570,
*URI Template*, March 2012.

RFC 6570 was published in March 2012. Its copyright notice requires extracted
Code Components to include the BSD text in section 4.e of the
[IETF Trust Legal Provisions 4.0](https://trustee.ietf.org/wp-content/uploads/IETF-TLP-4.pdf),
which was effective on the publication date. It also requests attribution to
the IETF and the source RFC.

The RFC 6570 authors are Joe Gregorio, Roy T. Fielding, Marc Hadley,
Mark Nottingham, and David Orchard. The applicable three-clause text, with
the year filled in, is reproduced in
[`LICENSES/IETF-Revised-BSD.txt`](LICENSES/IETF-Revised-BSD.txt).

RFC 6570 and TLP 4.0 call that text the "Simplified BSD License." The IETF
Trust later
[corrected the name](https://trustee.ietf.org/about/announcements/a-clerical-correction-to-the-ietf-trust-legal-provisions-5-0/):
the included non-endorsement clause makes it the three-clause Revised BSD
License. The terms themselves are unchanged by that naming clarification.

### Imported core, URI, and IRI definitions

RFC 6570 section 1.5 reproduces the functional definitions from which these
local tables are adapted and identifies their earlier normative sources. The
repository treats that 2012 reproduction as the immediate Code Component
source under the RFC 6570 BSD terms above, while retaining the original
provenance:

- RFC 5234, *Augmented BNF for Syntax Specifications: ABNF*, by
  Dave Crocker and Paul Overell.
- RFC 3986, *Uniform Resource Identifier (URI): Generic Syntax*, by
  Tim Berners-Lee, Roy T. Fielding, and Larry Masinter.
- RFC 3987, *Internationalized Resource Identifiers (IRIs)*, by
  Martin Duerst and Michel Suignard.

RFC 3986 and RFC 3987 were published in January 2005, and RFC 5234 in January
2008, before the IETF Trust BSD terms applied to their originals. They are
therefore cited as origin and normative authority, not separately described
here as BSD-licensed works. This repository does not rely on applying the
later TLP BSD label retroactively to those originals.

## Distribution

Source or binary distributions that include the fixtures or standards-derived
Code Components must retain this file and the applicable files under
`LICENSES/` in source documentation or other materials provided with the
distribution.
