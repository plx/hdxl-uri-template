#!/bin/sh

set -u

if [ "$#" -eq 0 ]; then
  printf 'usage: %s command [argument ...]\n' "${0##*/}" >&2
  exit 64
fi

warning_guard_log_file=$(
  mktemp "${TMPDIR:-/tmp}/hdxl-uri-template-warning-check.XXXXXX"
) || {
  printf 'error: unable to create warning-check log\n' >&2
  exit 1
}

trap 'rm -f "$warning_guard_log_file"' 0
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

"$@" >"$warning_guard_log_file" 2>&1
warning_guard_command_status=$?

cat "$warning_guard_log_file"
warning_guard_cat_status=$?
if [ "$warning_guard_cat_status" -ne 0 ]; then
  printf 'error: unable to reproduce warning-check output\n' >&2
  exit 1
fi

if [ "$warning_guard_command_status" -ne 0 ]; then
  exit "$warning_guard_command_status"
fi

# Deliberately fail closed on warning-shaped text from either output stream.
# Test-authored output containing the same shape is therefore also rejected.
warning_guard_pattern='(^[[:space:]]*warning:|:[[:space:]]+warning:)'
LC_ALL=C grep -Eq "$warning_guard_pattern" "$warning_guard_log_file"
warning_guard_grep_status=$?

case "$warning_guard_grep_status" in
  0)
    printf '\nerror: successful command emitted warning diagnostics:\n' >&2
    LC_ALL=C grep -En "$warning_guard_pattern" "$warning_guard_log_file" >&2
    exit 1
    ;;
  1)
    exit 0
    ;;
  *)
    printf 'error: unable to inspect command output for warnings\n' >&2
    exit 1
    ;;
esac
