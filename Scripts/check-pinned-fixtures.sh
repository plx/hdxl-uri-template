#!/bin/sh

set -eu

fixture_guard_script_directory=${0%/*}
fixture_guard_repository_root=$(
  cd "$fixture_guard_script_directory/.." &&
    pwd
)
fixture_guard_directory=${1:-"$fixture_guard_repository_root/Tests/HDXLURITemplateTests/Resources"}

check_fixture() {
  fixture_guard_name=$1
  fixture_guard_expected_cases=$2
  fixture_guard_expected_bytes=$3
  fixture_guard_expected_sha256=$4
  fixture_guard_path="$fixture_guard_directory/$fixture_guard_name.json"

  if [ ! -f "$fixture_guard_path" ]; then
    printf 'error: missing pinned fixture %s\n' "$fixture_guard_name.json" >&2
    return 1
  fi

  fixture_guard_actual_cases=$(
    jq '[.[] | .testcases | length] | add' "$fixture_guard_path"
  )
  fixture_guard_actual_bytes=$(
    wc -c <"$fixture_guard_path" |
      tr -d '[:space:]'
  )
  fixture_guard_actual_sha256=$(
    shasum -a 256 "$fixture_guard_path" |
      awk '{ print $1 }'
  )

  if [ "$fixture_guard_actual_cases" -ne "$fixture_guard_expected_cases" ]; then
    printf \
      'error: %s has %s cases; expected %s\n' \
      "$fixture_guard_name.json" \
      "$fixture_guard_actual_cases" \
      "$fixture_guard_expected_cases" \
      >&2
    return 1
  fi

  if [ "$fixture_guard_actual_bytes" -ne "$fixture_guard_expected_bytes" ]; then
    printf \
      'error: %s has %s bytes; expected %s\n' \
      "$fixture_guard_name.json" \
      "$fixture_guard_actual_bytes" \
      "$fixture_guard_expected_bytes" \
      >&2
    return 1
  fi

  if [ "$fixture_guard_actual_sha256" != "$fixture_guard_expected_sha256" ]; then
    printf \
      'error: %s has SHA-256 %s; expected %s\n' \
      "$fixture_guard_name.json" \
      "$fixture_guard_actual_sha256" \
      "$fixture_guard_expected_sha256" \
      >&2
    return 1
  fi

  printf \
    '%s: %s cases, %s bytes, SHA-256 %s\n' \
    "$fixture_guard_name.json" \
    "$fixture_guard_actual_cases" \
    "$fixture_guard_actual_bytes" \
    "$fixture_guard_actual_sha256"
}

check_fixture \
  spec-examples \
  64 \
  6650 \
  9148100604d25beb4fcc56b9d3a3ed6a0067d5f042bd472918030aff808f77be
check_fixture \
  spec-examples-by-section \
  117 \
  14594 \
  0122630fddc249595045baef5122ccf41343c052d8524074920c9dc7bcd99543
check_fixture \
  extended-tests \
  53 \
  7426 \
  547c6d6669132a62ea002791cbefed43251c7fe2ad82f8725d930d401e5acd23
check_fixture \
  negative-tests \
  36 \
  2516 \
  7f4bd7def905c492b40fae92b6a51665489539dd773db464022a52eb37907e81
