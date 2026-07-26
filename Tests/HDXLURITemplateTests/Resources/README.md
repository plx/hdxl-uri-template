# `uritemplate-test` fixture snapshot

The four JSON suites in this directory are copied byte-for-byte from the
official [`uri-templates/uritemplate-test`](https://github.com/uri-templates/uritemplate-test)
repository at immutable commit
[`4171dac22aa67fc710b3f6df308a50bd08552986`](https://github.com/uri-templates/uritemplate-test/commit/4171dac22aa67fc710b3f6df308a50bd08552986).
They must not be edited locally. Project-owned interpretations and regression
tests belong in separate Swift test files.

| File | Cases | Bytes | SHA-256 |
| --- | ---: | ---: | --- |
| `spec-examples.json` | 64 | 6,650 | `9148100604d25beb4fcc56b9d3a3ed6a0067d5f042bd472918030aff808f77be` |
| `spec-examples-by-section.json` | 117 | 14,594 | `0122630fddc249595045baef5122ccf41343c052d8524074920c9dc7bcd99543` |
| `extended-tests.json` | 53 | 7,426 | `547c6d6669132a62ea002791cbefed43251c7fe2ad82f8725d930d401e5acd23` |
| `negative-tests.json` | 36 | 2,516 | `7f4bd7def905c492b40fae92b6a51665489539dd773db464022a52eb37907e81` |

The upstream files are licensed under Apache License 2.0. Repository-wide
third-party notice and standards attribution are tracked by DOC-04
([issue #42](https://github.com/plx/hdxl-uri-template/issues/42)); do not insert
notices into these byte-faithful JSON files.

## Updating the snapshot

Choose and review a new immutable upstream revision, then replace all four
files together:

```sh
fixture_checkout="$(mktemp -d)"
fixture_commit=4171dac22aa67fc710b3f6df308a50bd08552986
git clone https://github.com/uri-templates/uritemplate-test.git "$fixture_checkout"
git -C "$fixture_checkout" checkout --detach "$fixture_commit"

for fixture in \
  spec-examples.json \
  spec-examples-by-section.json \
  extended-tests.json \
  negative-tests.json
do
  cp "$fixture_checkout/$fixture" \
    "Tests/HDXLURITemplateTests/Resources/$fixture"
done
```

Recompute and review the snapshot metadata:

```sh
for fixture in Tests/HDXLURITemplateTests/Resources/*.json
do
  shasum -a 256 "$fixture"
  wc -c "$fixture"
  jq '[.[] | .testcases | length] | add' "$fixture"
done

swift test --filter pinnedFixture
swift test --filter pinnedSpecExamplesIncludeApostropheExample
```

Update this document and the fixture-count tests in the same fixture-only
change. Record the new upstream commit, explain count or content changes, and
keep license/provenance review coordinated with DOC-04.
