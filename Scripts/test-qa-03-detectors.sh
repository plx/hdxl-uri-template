#!/bin/bash

set -euo pipefail

qa03_seed=${QA03_SEED:-0x4844584C51413033}
qa03_failure_index=37
qa03_temporary_directory=$(mktemp -d)

cleanup() {
  rm -rf "$qa03_temporary_directory"
}
trap cleanup EXIT

qa03_require_failure() {
  local description=$1
  local status=$2
  if [[ $status -eq 0 ]]; then
    echo "error: $description unexpectedly passed" >&2
    exit 1
  fi
}

set +e
QA03_COMMIT="$(git rev-parse HEAD)" \
  xcrun swift run HDXLURITemplateQA03 fuzz \
  --seed "$qa03_seed" \
  --iterations 64 \
  --inject-failure-at "$qa03_failure_index" \
  >"$qa03_temporary_directory/fuzz-failure.log" 2>&1
qa03_fuzz_status=$?
set -e
qa03_require_failure "injected deterministic fuzz case" "$qa03_fuzz_status"

grep -F "seed=$qa03_seed" "$qa03_temporary_directory/fuzz-failure.log"
grep -F "index=$qa03_failure_index" \
  "$qa03_temporary_directory/fuzz-failure.log"
grep -F "case-seed=" "$qa03_temporary_directory/fuzz-failure.log"

set +e
QA03_COMMIT="$(git rev-parse HEAD)" \
  xcrun swift run HDXLURITemplateQA03 fuzz \
  --seed "$qa03_seed" \
  --iterations 64 \
  --replay-index "$qa03_failure_index" \
  --inject-failure-at "$qa03_failure_index" \
  >"$qa03_temporary_directory/fuzz-replay.log" 2>&1
qa03_replay_status=$?
set -e
qa03_require_failure "replayed deterministic fuzz case" "$qa03_replay_status"

grep -F "seed=$qa03_seed" "$qa03_temporary_directory/fuzz-replay.log"
grep -F "index=$qa03_failure_index" \
  "$qa03_temporary_directory/fuzz-replay.log"
grep -F "case-seed=" "$qa03_temporary_directory/fuzz-replay.log"

xcrun swift run HDXLURITemplateQA03 verify-scaling-detector \
  >"$qa03_temporary_directory/scaling-detector.json"
jq -e '
  .passed == false
  and .fittedExponent > 1.999999
  and .fittedExponent < 2.000001
' "$qa03_temporary_directory/scaling-detector.json" >/dev/null

cat >"$qa03_temporary_directory/known-race.swift" <<'SWIFT'
import Dispatch

final class SharedBox: @unchecked Sendable {
  var value = 0
}

let sharedBox = SharedBox()
DispatchQueue.concurrentPerform(iterations: 100_000) { _ in
  sharedBox.value += 1
}
print(sharedBox.value)
SWIFT

xcrun swiftc -sanitize=thread \
  "$qa03_temporary_directory/known-race.swift" \
  -o "$qa03_temporary_directory/known-race"

set +e
TSAN_OPTIONS="halt_on_error=1:exitcode=66" \
  "$qa03_temporary_directory/known-race" \
  >"$qa03_temporary_directory/thread-sanitizer-detector.log" 2>&1
qa03_tsan_status=$?
set -e
qa03_require_failure "known Thread Sanitizer race" "$qa03_tsan_status"
if ! grep -E "WARNING: ThreadSanitizer: (Swift access|data) race" \
  "$qa03_temporary_directory/thread-sanitizer-detector.log"
then
  echo "error: TSan failed without its expected data-race diagnostic" >&2
  cat "$qa03_temporary_directory/thread-sanitizer-detector.log" >&2
  exit 1
fi

echo \
  "QA-03 detector controls passed: seed replay, quadratic rejection, TSan race."
