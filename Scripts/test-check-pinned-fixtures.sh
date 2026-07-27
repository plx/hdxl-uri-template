#!/bin/sh

set -eu

fixture_guard_test_script_directory=${0%/*}
fixture_guard_test_repository_root=$(
  cd "$fixture_guard_test_script_directory/.." &&
    pwd
)
fixture_guard_test_source_directory="$fixture_guard_test_repository_root/Tests/HDXLURITemplateTests/Resources"
fixture_guard_test_directory=$(
  mktemp -d "${TMPDIR:-/tmp}/hdxl-uri-template-fixture-guard.XXXXXX"
)

trap 'rm -rf "$fixture_guard_test_directory"' 0
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

for fixture_guard_test_name in \
  spec-examples \
  spec-examples-by-section \
  extended-tests \
  negative-tests
do
  cp \
    "$fixture_guard_test_source_directory/$fixture_guard_test_name.json" \
    "$fixture_guard_test_directory/$fixture_guard_test_name.json"
done

fixture_guard_test_script="$fixture_guard_test_script_directory/check-pinned-fixtures.sh"
"$fixture_guard_test_script" "$fixture_guard_test_directory" >/dev/null

printf '\n' >>"$fixture_guard_test_directory/extended-tests.json"
if "$fixture_guard_test_script" "$fixture_guard_test_directory" >/dev/null 2>&1
then
  printf 'error: modified pinned fixture passed the guard\n' >&2
  exit 1
fi

cp \
  "$fixture_guard_test_source_directory/extended-tests.json" \
  "$fixture_guard_test_directory/extended-tests.json"
rm "$fixture_guard_test_directory/negative-tests.json"
if "$fixture_guard_test_script" "$fixture_guard_test_directory" >/dev/null 2>&1
then
  printf 'error: missing pinned fixture passed the guard\n' >&2
  exit 1
fi

printf 'pinned fixture guard regression checks passed\n'
