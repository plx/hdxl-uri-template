#!/bin/sh

set -eu

warning_guard_script_directory=${0%/*}
warning_guard_script="$warning_guard_script_directory/run-without-warnings.sh"

expect_status() {
  warning_guard_expected_status=$1
  shift

  warning_guard_observed_status=0
  "$@" >/dev/null 2>&1 || warning_guard_observed_status=$?
  if [ "$warning_guard_observed_status" -ne "$warning_guard_expected_status" ]; then
    printf \
      'error: expected status %s but observed %s for %s\n' \
      "$warning_guard_expected_status" \
      "$warning_guard_observed_status" \
      "$*" \
      >&2
    exit 1
  fi
}

expect_status 64 "$warning_guard_script"
expect_status 0 "$warning_guard_script" sh -c 'printf "clean output\n"'
expect_status 1 "$warning_guard_script" sh -c 'printf "warning: synthetic\n"'
expect_status 1 "$warning_guard_script" sh -c 'printf "file: warning: synthetic\n" >&2'
expect_status 7 "$warning_guard_script" sh -c 'printf "warning: child failure\n"; exit 7'

printf 'warning guard regression checks passed\n'
