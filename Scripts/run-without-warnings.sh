#!/bin/sh

set -u

if [ "$#" -eq 0 ]; then
  printf 'usage: %s command [argument ...]\n' "${0##*/}" >&2
  exit 64
fi

qa05_log_file=$(
  mktemp "${TMPDIR:-/tmp}/hdxl-uri-template-warning-check.XXXXXX"
) || {
  printf 'error: unable to create warning-check log\n' >&2
  exit 1
}

trap 'rm -f "$qa05_log_file"' 0
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

"$@" >"$qa05_log_file" 2>&1
qa05_command_status=$?

cat "$qa05_log_file"
qa05_cat_status=$?
if [ "$qa05_cat_status" -ne 0 ]; then
  printf 'error: unable to reproduce warning-check output\n' >&2
  exit 1
fi

if [ "$qa05_command_status" -ne 0 ]; then
  exit "$qa05_command_status"
fi

# Deliberately fail closed on warning-shaped text from either output stream.
# Test-authored output containing the same shape is therefore also rejected.
qa05_warning_pattern='(^[[:space:]]*warning:|:[[:space:]]+warning:)'
LC_ALL=C grep -Eq "$qa05_warning_pattern" "$qa05_log_file"
qa05_grep_status=$?

case "$qa05_grep_status" in
  0)
    printf '\nerror: successful command emitted warning diagnostics:\n' >&2
    LC_ALL=C grep -En "$qa05_warning_pattern" "$qa05_log_file" >&2
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
