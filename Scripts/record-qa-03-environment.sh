#!/bin/bash

set -euo pipefail

if [[ $# -ne 5 ]]; then
  echo \
    "usage: $0 ARTIFACT_DIRECTORY EXPECTED_SHA PROFILE SEED ITERATIONS" \
    >&2
  exit 64
fi

qa03_artifact_directory=$1
qa03_expected_sha=$2
qa03_profile=$3
qa03_seed=$4
qa03_iterations=$5
qa03_actual_sha=$(git rev-parse HEAD)
qa03_swift_version=$(xcrun swift --version)

if [[ ! "$qa03_expected_sha" =~ ^[0-9a-f]{40}$ ]]; then
  echo "error: expected SHA must be a full lowercase 40-character SHA" >&2
  exit 65
fi

if [[ "$qa03_actual_sha" != "$qa03_expected_sha" ]]; then
  echo \
    "error: checked out $qa03_actual_sha, expected $qa03_expected_sha" \
    >&2
  exit 66
fi

if ! grep -Eq 'Swift version 6\.3([.[:space:]]|$)' \
  <<<"$qa03_swift_version"
then
  echo "error: QA-03 requires the supported Swift 6.3 toolchain" >&2
  echo "$qa03_swift_version" >&2
  exit 67
fi

mkdir -p "$qa03_artifact_directory"
cp Hardening/QA03/baselines.json \
  "$qa03_artifact_directory/scaling-baselines.json"

{
  printf 'schema-version: 1\n'
  printf 'commit: %s\n' "$qa03_actual_sha"
  printf 'profile: %s\n' "$qa03_profile"
  printf 'seed: %s\n' "$qa03_seed"
  printf 'fuzz-iterations: %s\n' "$qa03_iterations"
  printf 'runner-os: %s\n' "${RUNNER_OS:-local}"
  printf 'runner-architecture: %s\n' "${RUNNER_ARCH:-$(uname -m)}"
  printf 'runner-image-os: %s\n' "${ImageOS:-local}"
  printf 'runner-image-version: %s\n' "${ImageVersion:-local}"
  printf 'hardware-model: %s\n' "$(sysctl -n hw.model 2>/dev/null || true)"
  printf 'logical-cpus: %s\n' "$(sysctl -n hw.logicalcpu 2>/dev/null || true)"
  printf 'physical-cpus: %s\n' "$(sysctl -n hw.physicalcpu 2>/dev/null || true)"
  printf 'memory-bytes: %s\n' "$(sysctl -n hw.memsize 2>/dev/null || true)"
  printf 'baseline-sha256: '
  shasum -a 256 Hardening/QA03/baselines.json | awk '{print $1}'
  printf '\n--- sw_vers ---\n'
  sw_vers
  printf '\n--- xcodebuild -version ---\n'
  xcodebuild -version
  printf '\n--- swift --version ---\n'
  printf '%s\n' "$qa03_swift_version"
  printf '\n--- uname -a ---\n'
  uname -a
} >"$qa03_artifact_directory/environment.txt"
