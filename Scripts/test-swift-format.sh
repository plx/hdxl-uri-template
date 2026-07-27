#!/bin/sh

set -eu

script_directory=$(
  unset CDPATH
  cd -- "$(dirname -- "$0")"
  pwd
)
repository_root=$(
  unset CDPATH
  cd -- "$script_directory/.."
  pwd
)
scratch_root=${TMPDIR:-/tmp}
scratch_root=${scratch_root%/}
scratch=$(/usr/bin/mktemp -d "$scratch_root/hdxl-swift-format.XXXXXX")

cleanup() {
  case "$scratch" in
    "$scratch_root"/hdxl-swift-format.*)
      if [ -d "$scratch" ]; then
        /bin/rm -R "$scratch"
      fi
      ;;
  esac
}
trap cleanup 0
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

formatter="$repository_root/Scripts/swift-format.sh"
unformatted="$scratch/Unformatted.swift"

/usr/bin/printf '%s\n' \
  'struct Unformatted { let value:Int }' \
  >"$unformatted"

if "$formatter" lint "$unformatted" >"$scratch/unformatted-lint.log" 2>&1
then
  /usr/bin/printf '%s\n' \
    'error: the formatting gate accepted a deliberately unformatted file' >&2
  exit 1
fi

"$formatter" format "$unformatted"
"$formatter" lint "$unformatted"

first_hash=$(
  /usr/bin/shasum -a 256 "$unformatted" |
    /usr/bin/awk '{ print $1 }'
)
"$formatter" format "$unformatted"
second_hash=$(
  /usr/bin/shasum -a 256 "$unformatted" |
    /usr/bin/awk '{ print $1 }'
)

if [ "$first_hash" != "$second_hash" ]; then
  /usr/bin/printf '%s\n' \
    'error: a second formatting pass changed an already-formatted file' >&2
  exit 1
fi

fixture_repository="$scratch/repository"
/bin/mkdir -p \
  "$fixture_repository/.build" \
  "$fixture_repository/Benchmarks" \
  "$fixture_repository/Hardening" \
  "$fixture_repository/Scripts" \
  "$fixture_repository/Sources" \
  "$fixture_repository/Tests/Vendored"
/bin/cp "$repository_root/.swift-format" "$fixture_repository/.swift-format"
/bin/cp "$formatter" "$fixture_repository/Scripts/swift-format.sh"
/usr/bin/printf '%s\n' \
  'let packageName = "format-fixture"' \
  >"$fixture_repository/Package.swift"
/usr/bin/printf '%s\n' \
  'let  ignored=true' \
  >"$fixture_repository/.build/Ignored.swift"
/usr/bin/printf '%s\n' \
  '{"spacing" : "must remain byte-for-byte stable"}' \
  >"$fixture_repository/Tests/Vendored/fixture.json"

build_hash_before=$(
  /usr/bin/shasum -a 256 "$fixture_repository/.build/Ignored.swift" |
    /usr/bin/awk '{ print $1 }'
)
fixture_hash_before=$(
  /usr/bin/shasum -a 256 "$fixture_repository/Tests/Vendored/fixture.json" |
    /usr/bin/awk '{ print $1 }'
)

"$fixture_repository/Scripts/swift-format.sh" lint
"$fixture_repository/Scripts/swift-format.sh" format

build_hash_after=$(
  /usr/bin/shasum -a 256 "$fixture_repository/.build/Ignored.swift" |
    /usr/bin/awk '{ print $1 }'
)
fixture_hash_after=$(
  /usr/bin/shasum -a 256 "$fixture_repository/Tests/Vendored/fixture.json" |
    /usr/bin/awk '{ print $1 }'
)

if [ "$build_hash_before" != "$build_hash_after" ]; then
  /usr/bin/printf '%s\n' \
    'error: the formatter rewrote excluded .build output' >&2
  exit 1
fi
if [ "$fixture_hash_before" != "$fixture_hash_after" ]; then
  /usr/bin/printf '%s\n' \
    'error: the formatter rewrote an excluded JSON fixture' >&2
  exit 1
fi

/usr/bin/printf '%s\n' \
  'swift-format detector rejected drift, proved idempotence, and preserved excluded build output and JSON fixtures.'
