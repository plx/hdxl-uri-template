#!/bin/sh

set -eu

if [ "$#" -ne 1 ]; then
  printf 'usage: %s FULL_40_CHARACTER_SHA\n' "$0" >&2
  exit 64
fi

target_sha=$1
case "$target_sha" in
  *[!0-9a-f]*)
    printf 'error: expected one full lowercase 40-character SHA\n' >&2
    exit 64
    ;;
esac
if [ "${#target_sha}" -ne 40 ]; then
  printf 'error: expected one full lowercase 40-character SHA\n' >&2
  exit 64
fi

repository_url=${HDXL_REMOTE_CONSUMER_URL:-https://github.com/plx/hdxl-uri-template.git}
scratch_root=${TMPDIR:-/tmp}
scratch_root=${scratch_root%/}
scratch=$(/usr/bin/mktemp -d "$scratch_root/hdxl-remote-consumer.XXXXXX")

cleanup() {
  case "$scratch" in
    "$scratch_root"/hdxl-remote-consumer.*)
      if [ -d "$scratch" ]; then
        /bin/rm -Rf "$scratch"
      fi
      ;;
  esac
}
trap cleanup 0
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

/bin/mkdir -p "$scratch/Sources/CandidateConsumer"

/usr/bin/printf '%s\n' \
  '// swift-tools-version: 6.3' \
  '' \
  'import PackageDescription' \
  '' \
  'let package = Package(' \
  '  name: "CandidateConsumer",' \
  '  platforms: [.macOS(.v26)],' \
  '  dependencies: [' \
  '    .package(' \
  "      url: \"$repository_url\"," \
  "      revision: \"$target_sha\"" \
  '    )' \
  '  ],' \
  '  targets: [' \
  '    .executableTarget(' \
  '      name: "CandidateConsumer",' \
  '      dependencies: [' \
  '        .product(' \
  '          name: "HDXLURITemplate",' \
  '          package: "hdxl-uri-template"' \
  '        )' \
  '      ]' \
  '    )' \
  '  ]' \
  ')' \
  >"$scratch/Package.swift"

/usr/bin/printf '%s\n' \
  'import Foundation' \
  'import HDXLURITemplate' \
  '' \
  'let template = try URITemplate(parsing: "/users/{id}{?fields*}")' \
  'let parameters: [String: URIVariableValue] = [' \
  '  "id": .text("42"),' \
  '  "fields": .list(["name", "email"]),' \
  ']' \
  'let output = try template.evaluateAsString(parameters: parameters)' \
  'precondition(output == "/users/42?fields=name&fields=email")' \
  'precondition(template.variableNames == Set(["id", "fields"]))' \
  'let data = try JSONEncoder().encode(template)' \
  'let decoded = try JSONDecoder().decode(URITemplate.self, from: data)' \
  'precondition(decoded == template)' \
  'precondition(parameters["id"]?.textValue == "42")' \
  'print("candidate consumer passed: \(output)")' \
  >"$scratch/Sources/CandidateConsumer/main.swift"

cd "$scratch"
xcrun swift package resolve

if ! jq -e \
  --arg target_sha "$target_sha" \
  '.pins[] |
    select(.identity == "hdxl-uri-template") |
    .state.revision == $target_sha' \
  Package.resolved >/dev/null
then
  printf 'error: Package.resolved did not pin the requested revision\n' >&2
  exit 1
fi

xcrun swift run -c release CandidateConsumer
printf 'remote consumer resolved and ran exact revision %s\n' "$target_sha"
