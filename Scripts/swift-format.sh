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
configuration="$repository_root/.swift-format"
operation=${1:-lint}

if [ "$#" -gt 0 ]; then
  shift
fi

if [ ! -f "$configuration" ]; then
  printf 'error: missing swift-format configuration: %s\n' "$configuration" >&2
  exit 1
fi

if [ "$#" -eq 0 ]; then
  set -- \
    Package.swift \
    Benchmarks \
    Hardening \
    Scripts \
    Sources \
    Tests
fi

cd "$repository_root"

case "$operation" in
  lint)
    exec xcrun swift-format lint \
      --configuration "$configuration" \
      --recursive \
      --parallel \
      --strict \
      "$@"
    ;;
  format)
    exec xcrun swift-format format \
      --configuration "$configuration" \
      --recursive \
      --parallel \
      --in-place \
      "$@"
    ;;
  *)
    printf 'usage: %s [lint|format] [path ...]\n' "$0" >&2
    exit 64
    ;;
esac
