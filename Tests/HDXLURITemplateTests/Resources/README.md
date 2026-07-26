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

The upstream files are licensed under Apache License 2.0. The
[repository-wide third-party notice](../../../THIRD_PARTY_NOTICES.md) records
the upstream copyright notice and the full license is reproduced in
[`LICENSES/Apache-2.0.txt`](../../../LICENSES/Apache-2.0.txt). Do not insert
notices into these byte-faithful JSON files.

## Updating the snapshot

Choose and review a new immutable upstream revision, then replace all four
files together:

```sh
fixture_checkout="$(mktemp -d)"
fixture_commit=4171dac22aa67fc710b3f6df308a50bd08552986
git clone https://github.com/uri-templates/uritemplate-test.git "$fixture_checkout"
git -C "$fixture_checkout" checkout --detach "$fixture_commit"

# Review all upstream licensing material at the selected commit.
git -C "$fixture_checkout" ls-tree -r --name-only HEAD |
  grep -E '(^|/)(LICENSE|NOTICE)(\.|$)'
git -C "$fixture_checkout" grep -n -i -E \
  'copyright|license|notice' HEAD -- README.md

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
  fixture_name="$(basename "$fixture")"
  cmp "$fixture_checkout/$fixture_name" "$fixture"
  shasum -a 256 "$fixture"
  wc -c "$fixture"
  jq '[.[] | .testcases | length] | add' "$fixture"
done

swift test --filter pinnedFixture
swift test --filter pinnedSpecExamplesIncludeApostropheExample
swift test
```

Update this document, the root
[`THIRD_PARTY_NOTICES.md`](../../../THIRD_PARTY_NOTICES.md), and the
fixture-count tests in the same fixture-only change. Record the new upstream
commit, explain count or content changes, and update reproduced license or
notice files if the upstream terms changed.
