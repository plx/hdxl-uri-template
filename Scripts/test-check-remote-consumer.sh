#!/bin/sh

set -eu

test_script_directory=${0%/*}
consumer_script="$test_script_directory/check-remote-consumer.sh"

expect_rejection() {
  label=$1
  shift

  if "$consumer_script" "$@" >/dev/null 2>&1; then
    printf 'error: remote-consumer guard accepted %s\n' "$label" >&2
    exit 1
  fi
}

sh -n "$consumer_script"
expect_rejection "a missing SHA"
expect_rejection "an abbreviated SHA" "dea681e"
expect_rejection \
  "a non-hexadecimal SHA" \
  "000000000000000000000000000000000000000g"
expect_rejection \
  "an uppercase SHA" \
  "DEA681EA83187EA32691F55F5F272FFC02D0E5FF"

printf 'remote-consumer guard regression checks passed\n'
