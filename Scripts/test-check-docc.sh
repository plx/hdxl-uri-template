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
scratch=$(/usr/bin/mktemp -d "$scratch_root/hdxl-docc-gate.XXXXXX")

cleanup() {
  case "$scratch" in
    "$scratch_root"/hdxl-docc-gate.*)
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

checker="$repository_root/Scripts/check-docc.swift"
catalog_source="$repository_root/Sources/HDXLURITemplate/HDXLURITemplate.docc"
consumer_source="$repository_root/Tests/PublicAPIConsumer"

cd "$repository_root"
xcrun swift "$checker" >/dev/null

drifted_catalog="$scratch/HDXLURITemplate-drifted.docc"
/bin/cp -R "$catalog_source" "$drifted_catalog"
/usr/bin/sed \
  -i '' \
  's/func readmeQuickStart() throws/func doccDriftedQuickStart() throws/' \
  "$drifted_catalog/Expanding-Templates.md"

if HDXL_DOCC_CATALOG_PATH="$drifted_catalog" \
  xcrun swift "$checker" \
  >"$scratch/drift-output.txt" \
  2>&1
then
  /usr/bin/printf '%s\n' \
    'error: the DocC gate accepted an example that drifted from compiled source' \
    >&2
  exit 1
fi
/usr/bin/grep -F \
  'DocC must contain exactly one example matching' \
  "$scratch/drift-output.txt" >/dev/null

broken_link_catalog="$scratch/HDXLURITemplate-broken-link.docc"
/bin/cp -R "$catalog_source" "$broken_link_catalog"
/usr/bin/sed \
  -i '' \
  's/<doc:Parsing-Templates>/<doc:Missing-Article>/' \
  "$broken_link_catalog/HDXLURITemplate.md"

if HDXL_DOCC_CATALOG_PATH="$broken_link_catalog" \
  xcrun swift "$checker" \
  >"$scratch/link-output.txt" \
  2>&1
then
  /usr/bin/printf '%s\n' \
    'error: the DocC gate accepted an unresolved documentation link' >&2
  exit 1
fi
/usr/bin/grep -F \
  'Missing-Article' \
  "$scratch/link-output.txt" >/dev/null

invalid_consumer="$scratch/invalid-consumer"
/bin/cp -R "$consumer_source" "$invalid_consumer"
/usr/bin/sed \
  -i '' \
  "s|path: \"../..\"|path: \"$repository_root\"|" \
  "$invalid_consumer/Package.swift"
/usr/bin/sed \
  -i '' \
  's/URITemplate(parsing: source)/URITemplate.notARealPublicAPI()/' \
  "$invalid_consumer/Sources/HDXLURITemplatePublicAPIConsumer/DocCConcurrencyAndLimits.swift"

if xcrun swift build \
  --package-path "$invalid_consumer" \
  --scratch-path "$scratch/invalid-consumer-build" \
  --build-system swiftbuild \
  >"$scratch/consumer-output.txt" \
  2>&1
then
  /usr/bin/printf '%s\n' \
    'error: the public consumer compiled a deliberately invalid API example' \
    >&2
  exit 1
fi
/usr/bin/grep -F \
  'notARealPublicAPI' \
  "$scratch/consumer-output.txt" >/dev/null

/usr/bin/printf '%s\n' \
  'DocC detector accepted clean documentation and rejected example drift, a broken link, and an invalid public API example.'
