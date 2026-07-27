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
scratch=$(/usr/bin/mktemp -d "$scratch_root/hdxl-arch02-gate.XXXXXX")

cleanup() {
  case "$scratch" in
    "$scratch_root"/hdxl-arch02-gate.*)
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

cd "$repository_root"
xcrun swift Scripts/check-cross-module-inlining.swift >/dev/null

fixture="$scratch/Forbidden.swift"
/usr/bin/printf '%s\n' \
  '@inlinable' \
  '@usableFromInline' \
  '@inline(__always)' \
  '@_alwaysEmitIntoClient' \
  'internal func forbidden() {}' \
  >"$fixture"

if ARCH02_SOURCE_ROOT="$scratch" \
  xcrun swift Scripts/check-cross-module-inlining.swift \
  >"$scratch/standard-output.txt" \
  2>"$scratch/standard-error.txt"
then
  printf '%s\n' \
    'error: the ARCH-02 gate accepted forbidden annotations' >&2
  exit 1
fi

for annotation in \
  '@inlinable' \
  '@usableFromInline' \
  '@inline(__always)' \
  '@_alwaysEmitIntoClient'
do
  /usr/bin/grep -F "$annotation" "$scratch/standard-error.txt" >/dev/null
done

/bin/rm "$fixture"
/usr/bin/printf '%s\n' 'internal func allowed() {}' >"$scratch/Allowed.swift"
ARCH02_SOURCE_ROOT="$scratch" \
  xcrun swift Scripts/check-cross-module-inlining.swift >/dev/null

printf '%s\n' \
  'Cross-module inlining detector accepted clean source and rejected all forbidden annotations.'
