#!/bin/sh

set -eu

api03_usage() {
  command_name=$(basename "$0")
  cat <<EOF
Usage: $command_name [--quick] [--output DIRECTORY] [--replace]

Runs the API-03 Release benchmark with stable Xcode. Full mode retains five
workers with six warm samples each and 30 fresh processes per measured
configuration. Rejection lanes use balanced 1,000/10,000 collections. Quick
mode uses balanced 100 and retains one warm and one fresh sample while
preserving calibration and warm-up rules.
EOF
}

api03_fail() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

api03_progress() {
  printf 'API-03: %s\n' "$*" >&2
}

api03_first_line() {
  case "$1" in
    *'
'*)
      printf '%s\n' "${1%%'
'*}"
      ;;
    *)
      printf '%s\n' "$1"
      ;;
  esac
}

api03_after_first_line() {
  case "$1" in
    *'
'*)
      printf '%s\n' "${1#*'
'}"
      ;;
    *)
      printf '\n'
      ;;
  esac
}

api03_sha256_file() {
  api03_sha256_output=$(/usr/bin/shasum -a 256 "$1") || return
  printf '%s\n' "${api03_sha256_output%% *}"
}

api03_sha256_text() {
  api03_sha256_output=$(
    /usr/bin/shasum -a 256 <<EOF
$1
EOF
  ) || return
  printf '%s\n' "${api03_sha256_output%% *}"
}

api03_join_lines() {
  printf '%s\n' "$1" \
    | /usr/bin/awk '
        NR > 1 { printf " | " }
        { printf "%s", $0 }
        END { print "" }
      '
}

api03_script_directory=$(
  unset CDPATH
  cd -- "$(dirname -- "$0")"
  pwd
)
api03_repository_root=$(
  unset CDPATH
  cd -- "$api03_script_directory/.."
  pwd
)
api03_output_directory="$api03_repository_root/Documentation/Benchmarks/Data/API-03"
api03_quick=false
api03_replace=false

while [ "$#" -gt 0 ]; do
  case "$1" in
    --quick)
      api03_quick=true
      shift
      ;;
    --output)
      [ "$#" -ge 2 ] || api03_fail "--output requires a directory"
      api03_output_directory=$2
      shift 2
      ;;
    --replace)
      api03_replace=true
      shift
      ;;
    --help|-h)
      api03_usage
      exit 0
      ;;
    *)
      api03_fail "unknown argument: $1"
      ;;
  esac
done

api03_developer_directory=/Applications/Xcode.app/Contents/Developer
[ -d "$api03_developer_directory" ] \
  || api03_fail "stable Xcode is missing at $api03_developer_directory"

export DEVELOPER_DIR=$api03_developer_directory
export LANG=C
export LC_ALL=C

api03_xcode_output=$(/usr/bin/xcodebuild -version) \
  || api03_fail "could not inspect the stable Xcode version"
api03_xcode_version_line=$(api03_first_line "$api03_xcode_output")
api03_xcode_build_line=$(
  api03_after_first_line "$api03_xcode_output"
)
api03_xcode_version=${api03_xcode_version_line#Xcode }
api03_xcode_build_version=${api03_xcode_build_line#Build version }

api03_swift_output=$(/usr/bin/xcrun swift --version) \
  || api03_fail "could not inspect the stable Swift version"
api03_swift_version=$(api03_first_line "$api03_swift_output")
api03_swift_target=$(
  api03_after_first_line "$api03_swift_output"
)

api03_product_name=$(/usr/bin/sw_vers -productName) \
  || api03_fail "could not inspect the macOS product name"
api03_product_version=$(/usr/bin/sw_vers -productVersion) \
  || api03_fail "could not inspect the macOS product version"
api03_product_build_version=$(/usr/bin/sw_vers -buildVersion) \
  || api03_fail "could not inspect the macOS build version"

# Full evidence is the frozen protocol run. Quick mode remains a portable
# correctness smoke test and records, but does not constrain, its environment.
if [ "$api03_quick" = false ]; then
  [ "$api03_xcode_version" = 26.6 ] \
    || api03_fail "full evidence requires Xcode 26.6; found $api03_xcode_version"
  [ "$api03_xcode_build_version" = 17F113 ] \
    || api03_fail \
      "full evidence requires Xcode build 17F113; found $api03_xcode_build_version"
  case "$api03_swift_version" in
    'Apple Swift version 6.3.3 '*)
      ;;
    *)
      api03_fail \
        "full evidence requires Apple Swift 6.3.3; found $api03_swift_version"
      ;;
  esac
  [ "$api03_product_name" = macOS ] \
    || api03_fail "full evidence requires macOS; found $api03_product_name"
  [ "$api03_product_version" = 27.0 ] \
    || api03_fail \
      "full evidence requires macOS 27.0; found $api03_product_version"
  [ "$api03_product_build_version" = 26A5378n ] \
    || api03_fail \
      "full evidence requires macOS build 26A5378n; found $api03_product_build_version"
fi

api03_environment_file="$api03_output_directory/environment.json"
api03_validation_file="$api03_output_directory/correctness-validation.txt"
api03_manifest_file="$api03_output_directory/corpus-manifest.json"
api03_warm_file="$api03_output_directory/raw-warm.jsonl"
api03_fresh_file="$api03_output_directory/raw-fresh-process.jsonl"
api03_memory_file="$api03_output_directory/raw-memory.jsonl"
api03_summary_file="$api03_output_directory/summary.csv"
api03_swiftc_invocations_file="$api03_output_directory/release-swiftc-invocations.txt"

# Capture source state before creating or truncating any evidence artifact.
api03_started_at=$(/bin/date -u '+%Y-%m-%dT%H:%M:%SZ')
api03_commit=$(
  /usr/bin/git -C "$api03_repository_root" rev-parse HEAD
)
api03_worktree_status=$(
  /usr/bin/git -C "$api03_repository_root" status \
    --porcelain --untracked-files=normal
)
if [ -z "$api03_worktree_status" ]; then
  api03_clean_worktree=true
else
  api03_clean_worktree=false
fi
if [ "$api03_quick" = false ] && [ "$api03_clean_worktree" = false ]; then
  api03_fail "full benchmark evidence requires a clean worktree"
fi

if [ "$api03_replace" = false ]; then
  for api03_artifact in \
    "$api03_environment_file" \
    "$api03_validation_file" \
    "$api03_manifest_file" \
    "$api03_warm_file" \
    "$api03_fresh_file" \
    "$api03_memory_file" \
    "$api03_summary_file" \
    "$api03_swiftc_invocations_file"
  do
    [ ! -e "$api03_artifact" ] \
      || api03_fail "$api03_artifact already exists; pass --replace"
  done
fi

/bin/mkdir -p "$api03_output_directory"
: >"$api03_warm_file"
: >"$api03_fresh_file"
: >"$api03_memory_file"

api03_temp_root=${TMPDIR:-/tmp}
api03_temp_root=${api03_temp_root%/}
api03_scratch=$(
  /usr/bin/mktemp -d "$api03_temp_root/hdxl-api03.XXXXXX"
)

api03_cleanup() {
  case "$api03_scratch" in
    "$api03_temp_root"/hdxl-api03.*)
      if [ -d "$api03_scratch" ]; then
        /bin/rm -R "$api03_scratch"
      fi
      ;;
  esac
}
trap api03_cleanup 0
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

api03_check_fixture() {
  api03_fixture_path=$1
  api03_fixture_expected_bytes=$2
  api03_fixture_expected_sha256=$3
  api03_fixture_actual_bytes=$(
    /usr/bin/wc -c <"$api03_repository_root/$api03_fixture_path"
  )
  api03_fixture_actual_sha256=$(
    api03_sha256_file "$api03_repository_root/$api03_fixture_path"
  )
  printf \
    'fixture %s bytes=%s sha256=%s\n' \
    "$api03_fixture_path" \
    "$api03_fixture_actual_bytes" \
    "$api03_fixture_actual_sha256"
  [ "$api03_fixture_actual_bytes" -eq "$api03_fixture_expected_bytes" ] \
    || return 1
  [ "$api03_fixture_actual_sha256" = "$api03_fixture_expected_sha256" ] \
    || return 1
}

api03_run_correctness_validation() {
  printf '%s\n' \
    'API-03 pre-timing correctness validation' \
    'toolchain: /Applications/Xcode.app' \
    'configuration: release' \
    'filter: api03|codableReferenceSuitePartitionsAreComplete|everyPositivePinnedExampleRetainsSourceAndSemantics|pinnedFixtureCaseCounts|pinnedSpecExamplesIncludeApostropheExample'
  api03_check_fixture \
    Tests/HDXLURITemplateTests/Resources/spec-examples.json \
    6650 \
    9148100604d25beb4fcc56b9d3a3ed6a0067d5f042bd472918030aff808f77be \
    || return 1
  api03_check_fixture \
    Tests/HDXLURITemplateTests/Resources/spec-examples-by-section.json \
    14594 \
    0122630fddc249595045baef5122ccf41343c052d8524074920c9dc7bcd99543 \
    || return 1
  api03_check_fixture \
    Tests/HDXLURITemplateTests/Resources/extended-tests.json \
    7426 \
    547c6d6669132a62ea002791cbefed43251c7fe2ad82f8725d930d401e5acd23 \
    || return 1
  api03_check_fixture \
    Tests/HDXLURITemplateTests/Resources/negative-tests.json \
    2516 \
    7f4bd7def905c492b40fae92b6a51665489539dd773db464022a52eb37907e81 \
    || return 1
  api03_check_fixture \
    Tests/HDXLURITemplateTests/Resources/README.md \
    2894 \
    3370b5691bc3b33fd2a4c0b64091f142daa90904b04ba440fe189394ef72583a \
    || return 1
  (
    cd "$api03_repository_root"
    /usr/bin/xcrun swift test \
      -c release \
      --filter \
      'api03|codableReferenceSuitePartitionsAreComplete|everyPositivePinnedExampleRetainsSourceAndSemantics|pinnedFixtureCaseCounts|pinnedSpecExamplesIncludeApostropheExample' \
      --scratch-path "$api03_scratch/validation-build"
  )
}

api03_progress "running the correctness and pinned-fixture gate before timing"
api03_validation_raw="$api03_scratch/correctness-validation.raw.txt"
api03_validation_status=0
api03_run_correctness_validation \
  >"$api03_validation_raw" 2>&1 \
  || api03_validation_status=$?
/usr/bin/awk \
  -v repository="$api03_repository_root" \
  -v scratch="$api03_scratch" '
    function replaceLiteral(value, needle, replacement, position) {
      while ((position = index(value, needle)) != 0) {
        value = substr(value, 1, position - 1) replacement \
          substr(value, position + length(needle))
      }
      return value
    }
    {
      line = replaceLiteral($0, repository, "<REPOSITORY_ROOT>")
      line = replaceLiteral(line, scratch, "<SCRATCH>")
      print line
    }
  ' "$api03_validation_raw" >"$api03_validation_file"
if [ "$api03_validation_status" -ne 0 ]; then
  /bin/cat "$api03_validation_file" >&2
  api03_fail "pre-timing correctness validation failed"
fi
api03_validation_sha256=$(
  api03_sha256_file "$api03_validation_file"
)
api03_validation_completed_at=$(
  /bin/date -u '+%Y-%m-%dT%H:%M:%SZ'
)

api03_mode=full
api03_worker_count=5
api03_warm_samples=6
api03_fresh_samples=30
api03_fresh_workloads='
balanced-1
balanced-10
balanced-100
balanced-1000
balanced-10000
all-repeated-1000
all-unique-1000
all-repeated-10000
all-unique-10000
'

if [ "$api03_quick" = true ]; then
  api03_mode=quick
  api03_worker_count=1
  api03_warm_samples=1
  api03_fresh_samples=1
  api03_fresh_workloads='balanced-100'
fi

api03_primary_operations='
direct-parse
semantic-json
semantic-binary-property-list
prototype-cache
'
api03_fallback_workloads='
balanced-1000
balanced-10000
'
api03_fallback_operations='
prototype-cache-truncated-fallback
prototype-cache-corrupt-fallback
prototype-cache-wrong-version-fallback
prototype-cache-stale-fallback
prototype-cache-source-mismatch-fallback
prototype-cache-unknown-operator-fallback
prototype-cache-unknown-modifier-fallback
prototype-cache-invalid-prefix-fallback
prototype-cache-empty-expression-fallback
'
if [ "$api03_quick" = true ]; then
  api03_fallback_workloads='balanced-100'
fi

api03_progress "building the stable-Xcode Release executable once"
api03_build_log="$api03_scratch/release-build.log"
if ! (
  cd "$api03_repository_root"
  /usr/bin/xcrun swift build \
    -c release \
    -v \
    --product HDXLURITemplateAPI03Benchmark \
    --scratch-path "$api03_scratch/measurement-build"
) >"$api03_build_log" 2>&1
then
  /bin/cat "$api03_build_log" >&2
  api03_fail "Release build failed"
fi

/usr/bin/awk \
  -v repository="$api03_repository_root" \
  -v scratch="$api03_scratch" '
    function replaceLiteral(value, needle, replacement, position) {
      while ((position = index(value, needle)) != 0) {
        value = substr(value, 1, position - 1) replacement \
          substr(value, position + length(needle))
      }
      return value
    }
    /\/swiftc -module-name HDXLURITemplate / ||
    /\/swiftc -module-name HDXLURITemplateAPI03Benchmark(Support)? / {
      line = replaceLiteral($0, repository, "<REPOSITORY_ROOT>")
      line = replaceLiteral(line, scratch, "<SCRATCH>")
      print line
    }
  ' "$api03_build_log" >"$api03_swiftc_invocations_file"
api03_invocation_count=$(
  /usr/bin/wc -l <"$api03_swiftc_invocations_file"
)
[ "$api03_invocation_count" -eq 3 ] \
  || api03_fail "could not extract all three Swift compiler invocations"

api03_binary_directory=$(
  cd "$api03_repository_root"
  /usr/bin/xcrun swift build \
    -c release \
    --show-bin-path \
    --scratch-path "$api03_scratch/measurement-build"
)
api03_binary="$api03_binary_directory/HDXLURITemplateAPI03Benchmark"
[ -x "$api03_binary" ] \
  || api03_fail "Release benchmark executable was not produced"

api03_binary_sha256=$(
  api03_sha256_file "$api03_binary"
)
api03_swiftc_invocations_sha256=$(
  api03_sha256_file "$api03_swiftc_invocations_file"
)
api03_inputs="$api03_scratch/inputs"

api03_progress "verifying deterministic generated workloads"
"$api03_binary" verify-generated >"$api03_scratch/verified.json"

api03_progress "preparing persisted inputs outside all timed intervals"
if [ "$api03_quick" = true ]; then
  "$api03_binary" prepare \
    --directory "$api03_inputs" \
    --quick \
    >"$api03_manifest_file"
else
  "$api03_binary" prepare \
    --directory "$api03_inputs" \
    >"$api03_manifest_file"
fi

api03_plutil_insert_string() {
  /usr/bin/plutil -insert "$1" -string "$2" -s \
    "$api03_environment_file"
}

api03_plutil_insert_integer() {
  /usr/bin/plutil -insert "$1" -integer "$2" -s \
    "$api03_environment_file"
}

api03_plutil_insert_bool() {
  /usr/bin/plutil -insert "$1" -bool "$2" -s \
    "$api03_environment_file"
}

api03_xctrace_output=$(/usr/bin/xcrun xctrace version 2>/dev/null) \
  || api03_fail "could not inspect the xctrace version"
api03_xctrace_version=$(api03_first_line "$api03_xctrace_output")
api03_ac_power_before_output=$(/usr/bin/pmset -g batt 2>/dev/null) \
  || api03_fail "could not inspect AC power state before measurement"
api03_ac_power_before=$(api03_first_line "$api03_ac_power_before_output")
api03_thermal_before_output=$(/usr/bin/pmset -g therm 2>/dev/null) \
  || api03_fail "could not inspect thermal state before measurement"
api03_thermal_before=$(api03_join_lines "$api03_thermal_before_output")

/usr/bin/plutil -create xml1 "$api03_environment_file"
api03_plutil_insert_integer schemaVersion 1
api03_plutil_insert_string benchmarkCommit "$api03_commit"
api03_plutil_insert_bool cleanWorktree "$api03_clean_worktree"
api03_plutil_insert_string mode "$api03_mode"
api03_plutil_insert_string startedAtUTC "$api03_started_at"
api03_plutil_insert_string developerDirectory "$api03_developer_directory"
api03_plutil_insert_string buildConfiguration release
api03_plutil_insert_string buildProduct HDXLURITemplateAPI03Benchmark
api03_plutil_insert_string swiftBuildArguments \
  "-c release --product HDXLURITemplateAPI03Benchmark"
api03_plutil_insert_string correctnessValidationFile \
  "correctness-validation.txt"
api03_plutil_insert_string correctnessValidationCommand \
  "swift test -c release --filter api03|codableReferenceSuitePartitionsAreComplete|everyPositivePinnedExampleRetainsSourceAndSemantics|pinnedFixtureCaseCounts|pinnedSpecExamplesIncludeApostropheExample --scratch-path <VALIDATION_SCRATCH>"
api03_plutil_insert_string correctnessValidationCompletedAtUTC \
  "$api03_validation_completed_at"
api03_plutil_insert_string correctnessValidationStatus passed
api03_plutil_insert_string correctnessValidationSHA256 \
  "$api03_validation_sha256"
api03_plutil_insert_string swiftCompilerInvocationsFile \
  "release-swiftc-invocations.txt"
api03_plutil_insert_string swiftCompilerInvocationsSHA256 \
  "$api03_swiftc_invocations_sha256"
api03_plutil_insert_string binarySHA256 "$api03_binary_sha256"
api03_plutil_insert_string productName "$api03_product_name"
api03_plutil_insert_string productVersion "$api03_product_version"
api03_plutil_insert_string productBuildVersion "$api03_product_build_version"
api03_plutil_insert_string architecture "$(/usr/bin/uname -m)"
api03_plutil_insert_string kernelRelease "$(/usr/bin/uname -r)"
api03_plutil_insert_string machineModel "$(/usr/sbin/sysctl -n hw.model)"
api03_plutil_insert_string chip \
  "$(/usr/sbin/sysctl -n machdep.cpu.brand_string)"
api03_plutil_insert_integer physicalCoreCount \
  "$(/usr/sbin/sysctl -n hw.physicalcpu)"
api03_plutil_insert_integer logicalCoreCount \
  "$(/usr/sbin/sysctl -n hw.logicalcpu)"
api03_plutil_insert_integer memoryBytes \
  "$(/usr/sbin/sysctl -n hw.memsize)"
api03_plutil_insert_string xcodeVersion "$api03_xcode_version"
api03_plutil_insert_string xcodeBuildVersion "$api03_xcode_build_version"
api03_plutil_insert_string swiftVersion "$api03_swift_version"
api03_plutil_insert_string swiftTarget "$api03_swift_target"
api03_plutil_insert_string xctraceVersion "$api03_xctrace_version"
api03_plutil_insert_string acPowerBefore "$api03_ac_power_before"
api03_plutil_insert_string thermalStateBefore "$api03_thermal_before"

api03_progress "collecting warm samples"
api03_worker=0
while [ "$api03_worker" -lt "$api03_worker_count" ]; do
  if [ "$api03_quick" = true ]; then
    "$api03_binary" benchmark-warm \
      --directory "$api03_inputs" \
      --commit "$api03_commit" \
      --process-index "$api03_worker" \
      --samples "$api03_warm_samples" \
      --workload balanced-100 \
      --quick \
      --with-rejections \
      >>"$api03_warm_file"
  else
    "$api03_binary" benchmark-warm \
      --directory "$api03_inputs" \
      --commit "$api03_commit" \
      --process-index "$api03_worker" \
      --samples "$api03_warm_samples" \
      --with-rejections \
      >>"$api03_warm_file"
  fi
  api03_worker=$((api03_worker + 1))
done

api03_require_unsigned_integer() {
  case "$2" in
    ''|*[!0-9]*)
      api03_fail "$1 was not an unsigned integer: $2"
      ;;
  esac
}

api03_prewarm_fresh_configuration() {
  api03_configuration_workload=$1
  api03_configuration_operation=$2

  api03_warm_launch=0
  while [ "$api03_warm_launch" -lt 3 ]; do
    "$api03_binary" single-shot \
      --directory "$api03_inputs" \
      --workload "$api03_configuration_workload" \
      --operation "$api03_configuration_operation" \
      --commit "$api03_commit" \
      --process-index 0 \
      --sample-index "$api03_warm_launch" \
      >/dev/null
    api03_warm_launch=$((api03_warm_launch + 1))
  done
}

api03_collect_fresh_sample() {
  api03_configuration_workload=$1
  api03_configuration_operation=$2
  api03_configuration_process_index=$3

  api03_child_json="$api03_scratch/child.json"
  api03_time_output="$api03_scratch/time.txt"
  api03_launch_started=$(/bin/date +%s%N)
  /usr/bin/time -lp \
    "$api03_binary" single-shot \
    --directory "$api03_inputs" \
    --workload "$api03_configuration_workload" \
    --operation "$api03_configuration_operation" \
    --commit "$api03_commit" \
    --process-index "$api03_configuration_process_index" \
    --sample-index 0 \
    >"$api03_child_json" \
    2>"$api03_time_output"
  api03_launch_ended=$(/bin/date +%s%N)

  api03_time_real_seconds_coarse=$(
    /usr/bin/awk '
      $1 == "real" {
        print $2
        exit
      }
      $2 == "real" {
        print $1
        exit
      }
    ' "$api03_time_output"
  )
  api03_maximum_resident_set_size=$(
    /usr/bin/awk '
      /maximum resident set size$/ {
        print $1
        exit
      }
    ' "$api03_time_output"
  )
  api03_peak_memory_footprint=$(
    /usr/bin/awk '
      /peak memory footprint$/ {
        print $1
        exit
      }
    ' "$api03_time_output"
  )
  api03_require_unsigned_integer launchStarted "$api03_launch_started"
  api03_require_unsigned_integer launchEnded "$api03_launch_ended"
  case "$api03_time_real_seconds_coarse" in
    ''|*[!0-9.]*)
      api03_fail \
        "timeRealSecondsCoarse was not a nonnegative decimal: $api03_time_real_seconds_coarse"
      ;;
  esac
  api03_require_unsigned_integer \
    maximumResidentSetSize "$api03_maximum_resident_set_size"
  api03_require_unsigned_integer \
    peakMemoryFootprint "$api03_peak_memory_footprint"
  api03_launch_nanoseconds=$((api03_launch_ended - api03_launch_started))
  api03_require_unsigned_integer \
    launchElapsedNanoseconds "$api03_launch_nanoseconds"

  api03_spliced_child_json="$api03_scratch/spliced-child.json"
  if /usr/bin/awk -v launch="$api03_launch_nanoseconds" '
      BEGIN {
        token = "\"launchElapsedNanoseconds\":18446744073709551615"
        replacement = "\"launchElapsedNanoseconds\":" launch
        replacements = 0
      }
      {
        if (index($0, token) != 0) {
          sub(token, replacement)
          replacements += 1
        }
        print
      }
      END {
        if (replacements != 1) {
          exit 42
        }
      }
    ' "$api03_child_json" >"$api03_spliced_child_json"
  then
    /bin/cat "$api03_spliced_child_json" >>"$api03_fresh_file"
  else
    api03_fail \
      "fresh record did not contain exactly one unavailable launch sentinel"
  fi

  printf \
    '{"benchmarkCommit":"%s","launchElapsedNanoseconds":%s,"maximumResidentSetSizeBytes":%s,"operation":"%s","peakMemoryFootprintBytes":%s,"processIndex":%s,"sampleIndex":0,"schemaVersion":1,"timeRealSecondsCoarse":"%s","workloadID":"%s"}\n' \
    "$api03_commit" \
    "$api03_launch_nanoseconds" \
    "$api03_maximum_resident_set_size" \
    "$api03_configuration_operation" \
    "$api03_peak_memory_footprint" \
    "$api03_configuration_process_index" \
    "$api03_time_real_seconds_coarse" \
    "$api03_configuration_workload" \
    >>"$api03_memory_file"
}

api03_fresh_plan="$api03_scratch/fresh-plan.tsv"
: >"$api03_fresh_plan"

api03_append_fresh_configuration() {
  api03_plan_workload=$1
  api03_plan_operation=$2
  api03_plan_rank=$(
    api03_sha256_text \
      "0x4844584C41504903|$api03_plan_workload|$api03_plan_operation"
  )
  printf '%s\t%s\t%s\n' \
    "$api03_plan_rank" \
    "$api03_plan_workload" \
    "$api03_plan_operation" \
    >>"$api03_fresh_plan"
}

for api03_workload in $api03_fresh_workloads; do
  for api03_operation in $api03_primary_operations; do
    api03_append_fresh_configuration \
      "$api03_workload" "$api03_operation"
  done
done

# Rejection startup evidence is intentionally scoped to realistic balanced
# 1,000/10,000 collections (balanced-100 in quick mode).
for api03_workload in $api03_fallback_workloads; do
  for api03_operation in $api03_fallback_operations; do
    api03_append_fresh_configuration \
      "$api03_workload" "$api03_operation"
  done
done

api03_shuffled_fresh_plan="$api03_scratch/fresh-plan-shuffled.tsv"
LC_ALL=C /usr/bin/sort \
  -k1,1 -k2,2 -k3,3 \
  "$api03_fresh_plan" \
  >"$api03_shuffled_fresh_plan"

api03_tab=$(printf '\t')
api03_progress "prewarming every fresh-process configuration"
while IFS="$api03_tab" read -r \
  api03_plan_rank api03_workload api03_operation
do
  [ -n "$api03_plan_rank" ] \
    || api03_fail "fresh-process plan contains an empty rank"
  api03_prewarm_fresh_configuration \
    "$api03_workload" "$api03_operation"
done <"$api03_shuffled_fresh_plan"

api03_retained_fresh_plan="$api03_scratch/fresh-plan-retained.tsv"
: >"$api03_retained_fresh_plan"
api03_round=0
while [ "$api03_round" -lt "$api03_fresh_samples" ]; do
  while IFS="$api03_tab" read -r \
    api03_plan_rank api03_workload api03_operation
  do
    [ -n "$api03_plan_rank" ] \
      || api03_fail "fresh-process plan contains an empty rank"
    api03_round_rank=$(
      api03_sha256_text \
        "0x4844584C41504903|$api03_round|$api03_workload|$api03_operation"
    )
    printf '%d\t%s\t%s\t%s\n' \
      "$api03_round" \
      "$api03_round_rank" \
      "$api03_workload" \
      "$api03_operation" \
      >>"$api03_retained_fresh_plan"
  done <"$api03_fresh_plan"
  api03_round=$((api03_round + 1))
done

api03_shuffled_retained_fresh_plan="$api03_scratch/fresh-plan-retained-shuffled.tsv"
LC_ALL=C /usr/bin/sort \
  -k1,1n -k2,2 -k3,3 -k4,4 \
  "$api03_retained_fresh_plan" \
  >"$api03_shuffled_retained_fresh_plan"

api03_progress \
  "collecting interleaved fixed-seed fresh-process and /usr/bin/time -lp rounds"
while IFS="$api03_tab" read -r \
  api03_round api03_round_rank api03_workload api03_operation
do
  [ -n "$api03_round_rank" ] \
    || api03_fail "retained fresh-process plan contains an empty rank"
  api03_collect_fresh_sample \
    "$api03_workload" "$api03_operation" "$api03_round"
done <"$api03_shuffled_retained_fresh_plan"

api03_progress "computing deterministic summaries and bootstrap intervals"
"$api03_binary" summarize \
  --input "$api03_warm_file" \
  --input "$api03_fresh_file" \
  --output "$api03_summary_file"

if [ "$api03_quick" = true ]; then
  api03_expected_raw_records=13
  api03_expected_configuration_count=13
  api03_expected_process_count=1
  api03_expected_warm_batches=1
else
  api03_expected_raw_records=1620
  api03_expected_configuration_count=54
  api03_expected_process_count=30
  api03_expected_warm_batches=6
fi

api03_operation_contract_awk='
  function isPrimary(operation) {
    return operation == "direct-parse" \
      || operation == "semantic-json" \
      || operation == "semantic-binary-property-list" \
      || operation == "prototype-cache"
  }
  function isFallback(operation) {
    return operation == "prototype-cache-truncated-fallback" \
      || operation == "prototype-cache-corrupt-fallback" \
      || operation == "prototype-cache-wrong-version-fallback" \
      || operation == "prototype-cache-stale-fallback" \
      || operation == "prototype-cache-source-mismatch-fallback" \
      || operation == "prototype-cache-unknown-operator-fallback" \
      || operation == "prototype-cache-unknown-modifier-fallback" \
      || operation == "prototype-cache-invalid-prefix-fallback" \
      || operation == "prototype-cache-empty-expression-fallback"
  }
  function isExpectedConfiguration(workload, operation) {
    if (profile == "quick") {
      return workload == "balanced-100" \
        && (isPrimary(operation) || isFallback(operation))
    }
    if (isPrimary(operation)) {
      return workload == "balanced-1" \
        || workload == "balanced-10" \
        || workload == "balanced-100" \
        || workload == "balanced-1000" \
        || workload == "balanced-10000" \
        || workload == "all-repeated-1000" \
        || workload == "all-unique-1000" \
        || workload == "all-repeated-10000" \
        || workload == "all-unique-10000"
    }
    return isFallback(operation) \
      && (workload == "balanced-1000" \
        || workload == "balanced-10000")
  }
  function expectedOutcome(operation) {
    if (operation == "direct-parse" \
      || operation == "semantic-json" \
      || operation == "semantic-binary-property-list")
    {
      return "not-applicable"
    }
    if (operation == "prototype-cache") {
      return "hit"
    }
    if (operation == "prototype-cache-truncated-fallback") {
      return "fallback-decode-or-truncated"
    }
    if (operation == "prototype-cache-corrupt-fallback") {
      return "fallback-integrity-mismatch"
    }
    if (operation == "prototype-cache-wrong-version-fallback") {
      return "fallback-unsupported-version"
    }
    if (operation == "prototype-cache-stale-fallback") {
      return "fallback-authoritative-source-mismatch"
    }
    if (operation == "prototype-cache-source-mismatch-fallback") {
      return "fallback-payload-source-mismatch"
    }
    return "fallback-structural-validation"
  }
'

api03_validate_raw_file() {
  api03_raw_path=$1
  api03_raw_mode=$2
  api03_raw_expected_records=$3
  api03_raw_expected_configurations=$4
  api03_raw_expected_processes=$5
  api03_raw_expected_batches=$6

  /usr/bin/awk \
    -v expectedCommit="$api03_commit" \
    -v expectedMode="$api03_raw_mode" \
    -v expectedRecords="$api03_raw_expected_records" \
    -v expectedConfigurations="$api03_raw_expected_configurations" \
    -v expectedProcesses="$api03_raw_expected_processes" \
    -v expectedBatches="$api03_raw_expected_batches" \
    -v profile="$api03_mode" "$api03_operation_contract_awk"'
      function fail(message) {
        print "raw evidence validation: " message >"/dev/stderr"
        failed = 1
      }
      function stringValue(line, name, marker, remainder, ending) {
        marker = "\"" name "\":\""
        if (index(line, marker) == 0) {
          return "\034"
        }
        remainder = substr(line, index(line, marker) + length(marker))
        ending = index(remainder, "\"")
        if (ending == 0) {
          return "\034"
        }
        return substr(remainder, 1, ending - 1)
      }
      function unsignedValue(line, name, marker, remainder) {
        marker = "\"" name "\":"
        if (index(line, marker) == 0) {
          return "\034"
        }
        remainder = substr(line, index(line, marker) + length(marker))
        if (match(remainder, /^[0-9]+/) == 0) {
          return "\034"
        }
        return substr(remainder, 1, RLENGTH)
      }
      BEGIN {
        expectedSize["balanced-1"] = 1
        expectedSize["balanced-10"] = 10
        expectedSize["balanced-100"] = 100
        expectedSize["balanced-1000"] = 1000
        expectedSize["balanced-10000"] = 10000
        expectedSize["all-repeated-1000"] = 1000
        expectedSize["all-unique-1000"] = 1000
        expectedSize["all-repeated-10000"] = 10000
        expectedSize["all-unique-10000"] = 10000
        expectedCorpus["balanced-1"] = \
          "2f37db2ec67d4d0681905cfd419231f9265c81c70dc63a07d19f9905858c2799"
        expectedCorpus["balanced-10"] = \
          "53d0f546f4d8dcc3747e0f9864b55fdc24b0ad29b250a2ec0e34e8ee6f359c5a"
        expectedCorpus["balanced-100"] = \
          "230d0f04ce6634c515917cb593e418dd534e29f63350fba64cf24bc4071af10b"
        expectedCorpus["balanced-1000"] = \
          "8892a5bed2e0c2db945364e319be9d55a367cac34ef2ffaa8faf65cd68c2723b"
        expectedCorpus["balanced-10000"] = \
          "78b035cc47584ca769643cecbbbdc19057568f4d84b3d9275f2f9e1ad459e704"
        expectedCorpus["all-repeated-1000"] = \
          "12504c0f2f3fbecb5ff7cc9cba8ed1fe490f4710b5033c5c781dd3c29093c25b"
        expectedCorpus["all-unique-1000"] = \
          "94373c6840e46676a35621cc8fe0a9baca8a5ecb3df989137298f14f2a59cfeb"
        expectedCorpus["all-repeated-10000"] = \
          "f147a41fe97de58a94cea283fd55d9f28dbfb3598c1929c137894ecb879bdb1f"
        expectedCorpus["all-unique-10000"] = \
          "d51ea8b412e54de834c1dafc592c41172600b919556a96707f4b57750475667a"
      }
      {
        records += 1
        commit = stringValue($0, "benchmarkCommit")
        mode = stringValue($0, "mode")
        operation = stringValue($0, "operation")
        workload = stringValue($0, "workloadID")
        corpusKind = stringValue($0, "corpusKind")
        corpusDigest = stringValue($0, "corpusDigest")
        resultDigest = stringValue($0, "resultDigest")
        outcome = stringValue($0, "outcome")
        collectionSize = unsignedValue($0, "collectionSize")
        processIndex = unsignedValue($0, "processIndex")
        sampleIndex = unsignedValue($0, "sampleIndex")
        elapsedNanoseconds = unsignedValue($0, "elapsedNanoseconds")
        launchElapsedNanoseconds = \
          unsignedValue($0, "launchElapsedNanoseconds")
        repetitions = unsignedValue($0, "repetitions")
        templateOperations = unsignedValue($0, "templateOperations")
        encodedBytes = unsignedValue($0, "encodedBytes")

        if (commit != expectedCommit) {
          fail("record " records " has the wrong benchmark commit")
        }
        if (mode != expectedMode) {
          fail("record " records " has mode " mode)
        }
        if (!isExpectedConfiguration(workload, operation)) {
          fail("unexpected configuration " workload "/" operation \
            " in " expectedMode)
        }
        if (!(workload in expectedSize)) {
          fail("record " records " has an unpinned workload")
        } else {
          expectedCorpusKind = workload
          sub(/-[0-9]+$/, "", expectedCorpusKind)
          if (collectionSize + 0 != expectedSize[workload]) {
            fail("record " records " has the wrong collection size")
          }
          if (corpusKind != expectedCorpusKind) {
            fail("record " records " has the wrong corpus kind")
          }
          if (corpusDigest != expectedCorpus[workload]) {
            fail("record " records " has the wrong pinned corpus digest")
          }
        }
        if (repetitions == "\034" || repetitions + 0 <= 0) {
          fail("invalid repetitions at record " records)
        }
        if (templateOperations == "\034" \
          || templateOperations + 0 \
            != collectionSize * repetitions)
        {
          fail("invalid templateOperations at record " records)
        }
        if (encodedBytes == "\034" || encodedBytes + 0 <= 0) {
          fail("invalid encodedBytes at record " records)
        }
        if (length(resultDigest) != 64 \
          || tolower(resultDigest) !~ /^[0-9a-f]+$/)
        {
          fail("invalid result digest at record " records)
        }
        if (outcome != expectedOutcome(operation)) {
          fail("unexpected cache outcome at record " records)
        }
        if (processIndex == "\034" \
          || processIndex + 0 < 0 \
          || processIndex + 0 >= expectedProcesses)
        {
          fail("invalid processIndex at record " records)
        }
        if (sampleIndex == "\034" \
          || sampleIndex + 0 < 0 \
          || sampleIndex + 0 >= expectedBatches)
        {
          fail("invalid sampleIndex at record " records)
        }
        if (elapsedNanoseconds == "\034" \
          || elapsedNanoseconds + 0 <= 0)
        {
          fail("invalid elapsedNanoseconds at record " records)
        }
        if (expectedMode == "warm" \
          && elapsedNanoseconds + 0 < 200000000)
        {
          fail("retained warm batch is below 200 ms at record " records)
        }
        if (expectedMode == "warm" \
          && launchElapsedNanoseconds != "18446744073709551615")
        {
          fail("warm record unexpectedly has launch timing")
        }
        if (expectedMode == "fresh-process" \
          && (launchElapsedNanoseconds == "\034" \
            || launchElapsedNanoseconds + 0 <= 0))
        {
          fail("fresh record has no positive launch timing")
        }

        configuration = workload SUBSEP operation
        if (configuration in encodedBytesByConfiguration) {
          if (encodedBytesByConfiguration[configuration] != encodedBytes) {
            fail("encoded bytes changed within " configuration)
          }
          if (resultDigestByConfiguration[configuration] != resultDigest) {
            fail("result digest changed within " configuration)
          }
        } else {
          encodedBytesByConfiguration[configuration] = encodedBytes
          resultDigestByConfiguration[configuration] = resultDigest
        }
        observation = configuration SUBSEP processIndex SUBSEP sampleIndex
        if (observation in observations) {
          fail("duplicate process/sample tuple for " workload "/" operation)
        }
        observations[observation] = 1
        if (!(configuration in configurationCounts)) {
          configurations += 1
        }
        configurationCounts[configuration] += 1
      }
      END {
        if (records != expectedRecords) {
          fail("expected " expectedRecords " " expectedMode \
            " records, observed " records)
        }
        if (configurations != expectedConfigurations) {
          fail("expected " expectedConfigurations " " expectedMode \
            " configurations, observed " configurations)
        }
        for (configuration in configurationCounts) {
          expected = expectedProcesses * expectedBatches
          if (configurationCounts[configuration] != expected) {
            fail("configuration " configuration " has " \
              configurationCounts[configuration] \
              " records, expected " expected)
          }
        }
        if (failed) {
          exit 42
        }
      }
    ' "$api03_raw_path"
}

api03_validate_raw_file \
  "$api03_warm_file" \
  warm \
  "$api03_expected_raw_records" \
  "$api03_expected_configuration_count" \
  "$api03_worker_count" \
  "$api03_expected_warm_batches" \
  || api03_fail "warm raw evidence failed validation"
api03_validate_raw_file \
  "$api03_fresh_file" \
  fresh-process \
  "$api03_expected_raw_records" \
  "$api03_expected_configuration_count" \
  "$api03_expected_process_count" \
  1 \
  || api03_fail "fresh-process raw evidence failed validation"

/usr/bin/awk \
  -v expectedCommit="$api03_commit" \
  -v expectedRecords="$api03_expected_raw_records" \
  -v expectedConfigurations="$api03_expected_configuration_count" \
  -v expectedProcesses="$api03_expected_process_count" '
    function fail(message) {
      print "memory evidence validation: " message >"/dev/stderr"
      failed = 1
    }
    function stringValue(line, name, marker, remainder, ending) {
      marker = "\"" name "\":\""
      if (index(line, marker) == 0) {
        return "\034"
      }
      remainder = substr(line, index(line, marker) + length(marker))
      ending = index(remainder, "\"")
      if (ending == 0) {
        return "\034"
      }
      return substr(remainder, 1, ending - 1)
    }
    function unsignedValue(line, name, marker, remainder) {
      marker = "\"" name "\":"
      if (index(line, marker) == 0) {
        return "\034"
      }
      remainder = substr(line, index(line, marker) + length(marker))
      if (match(remainder, /^[0-9]+/) == 0) {
        return "\034"
      }
      return substr(remainder, 1, RLENGTH)
    }
    FNR == NR {
      workload = stringValue($0, "workloadID")
      operation = stringValue($0, "operation")
      processIndex = unsignedValue($0, "processIndex")
      key = workload SUBSEP operation SUBSEP processIndex
      freshLaunch[key] = unsignedValue($0, "launchElapsedNanoseconds")
      next
    }
    {
      records += 1
      commit = stringValue($0, "benchmarkCommit")
      workload = stringValue($0, "workloadID")
      operation = stringValue($0, "operation")
      processIndex = unsignedValue($0, "processIndex")
      sampleIndex = unsignedValue($0, "sampleIndex")
      launch = unsignedValue($0, "launchElapsedNanoseconds")
      maximumRSS = unsignedValue($0, "maximumResidentSetSizeBytes")
      peakFootprint = unsignedValue($0, "peakMemoryFootprintBytes")
      timeReal = stringValue($0, "timeRealSecondsCoarse")
      key = workload SUBSEP operation SUBSEP processIndex
      configuration = workload SUBSEP operation

      if (commit != expectedCommit) {
        fail("record " records " has the wrong benchmark commit")
      }
      if (processIndex == "\034" \
        || processIndex + 0 < 0 \
        || processIndex + 0 >= expectedProcesses)
      {
        fail("invalid processIndex at record " records)
      }
      if (sampleIndex != "0") {
        fail("memory sampleIndex is not zero at record " records)
      }
      if (!(key in freshLaunch)) {
        fail("memory record has no matching fresh-process record")
      } else if (launch != freshLaunch[key]) {
        fail("launch duration differs from the fresh-process record")
      }
      if (maximumRSS == "\034" || maximumRSS + 0 <= 0) {
        fail("maximum resident set size is missing or zero")
      }
      if (peakFootprint == "\034" || peakFootprint + 0 <= 0) {
        fail("peak memory footprint is missing or zero")
      }
      if (timeReal == "\034" || timeReal !~ /^[0-9]+[.][0-9]+$/) {
        fail("/usr/bin/time coarse real duration is missing or invalid")
      }
      if (key in memoryObservations) {
        fail("duplicate memory record for " workload "/" operation)
      }
      memoryObservations[key] = 1
      if (!(configuration in configurationCounts)) {
        configurations += 1
      }
      configurationCounts[configuration] += 1
    }
    END {
      if (records != expectedRecords) {
        fail("expected " expectedRecords " records, observed " records)
      }
      if (configurations != expectedConfigurations) {
        fail("expected " expectedConfigurations \
          " configurations, observed " configurations)
      }
      for (configuration in configurationCounts) {
        if (configurationCounts[configuration] != expectedProcesses) {
          fail("configuration " configuration " has " \
            configurationCounts[configuration] \
            " memory records, expected " expectedProcesses)
        }
      }
      if (failed) {
        exit 42
      }
    }
  ' "$api03_fresh_file" "$api03_memory_file" \
  || api03_fail "memory evidence failed validation"

if api03_noise_count=$(
  /usr/bin/awk \
    -F, \
    -v expectedCommit="$api03_commit" \
    -v expectedRows="$((api03_expected_configuration_count * 2))" \
    -v expectedRowsPerMode="$api03_expected_configuration_count" \
    -v expectedSamples="$(
      if [ "$api03_quick" = true ]; then
        printf '1\n'
      else
        printf '30\n'
      fi
    )" \
    -v expectedWarmProcesses="$api03_worker_count" \
    -v expectedFreshProcesses="$api03_expected_process_count" \
    -v expectedWarmBatches="$api03_expected_warm_batches" \
    -v profile="$api03_mode" "$api03_operation_contract_awk"'
      function fail(message) {
        print "summary validation: " message >"/dev/stderr"
        failed = 1
      }
      NR == 1 {
        headerCount = NF
        for (fieldIndex = 1; fieldIndex <= NF; fieldIndex += 1) {
          column[$fieldIndex] = fieldIndex
        }
        requiredColumns[1] = "benchmark_commit"
        requiredColumns[2] = "mode"
        requiredColumns[3] = "operation"
        requiredColumns[4] = "workload_id"
        requiredColumns[5] = "sample_count"
        requiredColumns[6] = "independent_process_count"
        requiredColumns[7] = "minimum_batches_per_process"
        requiredColumns[8] = "maximum_batches_per_process"
        requiredColumns[9] = "relative_mad"
        requiredColumns[10] = "launch_sample_count"
        requiredColumns[11] = "bootstrap_resamples"
        requiredColumns[12] = "encoded_bytes"
        requiredColumns[13] = "corpus_digest"
        requiredColumns[14] = "result_digest"
        requiredColumns[15] = "outcome"
        requiredColumns[16] = "median_nanoseconds"
        requiredColumns[17] = "median_ci95_lower_nanoseconds"
        requiredColumns[18] = "median_ci95_upper_nanoseconds"
        requiredColumns[19] = "median_launch_to_exit_nanoseconds"
        requiredColumns[20] = "p95_launch_to_exit_nanoseconds"
        requiredColumns[21] = "direct_parse_speedup"
        requiredColumns[22] = "direct_parse_speedup_ci95_lower"
        requiredColumns[23] = "direct_parse_speedup_ci95_upper"
        requiredColumns[24] = "direct_parse_launch_speedup"
        requiredColumns[25] = "direct_parse_launch_speedup_ci95_lower"
        requiredColumns[26] = "direct_parse_launch_speedup_ci95_upper"
        for (required = 1; required <= 26; required += 1) {
          if (!(requiredColumns[required] in column)) {
            fail("missing column " requiredColumns[required])
          }
        }
        next
      }
      {
        rows += 1
        if (NF != headerCount) {
          fail("row " rows " has " NF " fields; expected " headerCount)
        }
        commit = $(column["benchmark_commit"])
        mode = $(column["mode"])
        operation = $(column["operation"])
        workload = $(column["workload_id"])
        samples = $(column["sample_count"])
        processes = $(column["independent_process_count"])
        minimumBatches = $(column["minimum_batches_per_process"])
        maximumBatches = $(column["maximum_batches_per_process"])
        relativeMAD = $(column["relative_mad"])
        launchSamples = $(column["launch_sample_count"])
        encodedBytes = $(column["encoded_bytes"])
        corpusDigest = $(column["corpus_digest"])
        resultDigest = $(column["result_digest"])
        outcome = $(column["outcome"])
        configuration = mode SUBSEP workload SUBSEP operation
        lane = workload SUBSEP operation

        if (commit != expectedCommit) {
          fail("row " rows " has the wrong benchmark commit")
        }
        if (mode != "warm" && mode != "fresh-process") {
          fail("row " rows " has invalid mode " mode)
        }
        if (!isExpectedConfiguration(workload, operation)) {
          fail("unexpected configuration " workload "/" operation)
        }
        if (configuration in configurations) {
          fail("duplicate or split summary row for " configuration)
        }
        configurations[configuration] = 1
        modeRows[mode] += 1
        if (samples != expectedSamples) {
          fail(configuration " has sample_count=" samples)
        }
        if (relativeMAD !~ /^[0-9]+[.][0-9]+$/) {
          fail(configuration " has invalid relative_mad=" relativeMAD)
        }
        if (mode == "warm") {
          if (processes != expectedWarmProcesses \
            || minimumBatches != expectedWarmBatches \
            || maximumBatches != expectedWarmBatches)
          {
            fail(configuration " has invalid warm process topology")
          }
          if (launchSamples != 0) {
            fail(configuration " unexpectedly has warm launch samples")
          }
          if ($(column["median_launch_to_exit_nanoseconds"]) != "" \
            || $(column["p95_launch_to_exit_nanoseconds"]) != "" \
            || $(column["direct_parse_launch_speedup"]) != "" \
            || $(column["direct_parse_launch_speedup_ci95_lower"]) != "" \
            || $(column["direct_parse_launch_speedup_ci95_upper"]) != "")
          {
            fail(configuration " has warm launch statistics")
          }
          if (relativeMAD + 0 > 0.05) {
            noise += 1
          }
        } else {
          if (processes != expectedFreshProcesses \
            || minimumBatches != 1 \
            || maximumBatches != 1)
          {
            fail(configuration " has invalid fresh process topology")
          }
          if (launchSamples != expectedSamples) {
            fail(configuration " has invalid launch_sample_count")
          }
          if ($(column["median_launch_to_exit_nanoseconds"]) == "" \
            || $(column["p95_launch_to_exit_nanoseconds"]) == "" \
            || $(column["direct_parse_launch_speedup"]) == "" \
            || $(column["direct_parse_launch_speedup_ci95_lower"]) == "" \
            || $(column["direct_parse_launch_speedup_ci95_upper"]) == "")
          {
            fail(configuration " is missing fresh launch statistics")
          }
          if (relativeMAD + 0 > 0.10) {
            noise += 1
          }
        }
        if ($(column["median_nanoseconds"]) == "" \
          || $(column["median_ci95_lower_nanoseconds"]) == "" \
          || $(column["median_ci95_upper_nanoseconds"]) == "" \
          || $(column["direct_parse_speedup"]) == "" \
          || $(column["direct_parse_speedup_ci95_lower"]) == "" \
          || $(column["direct_parse_speedup_ci95_upper"]) == "")
        {
          fail(configuration " is missing latency or speedup statistics")
        }
        if ($(column["bootstrap_resamples"]) != 10000) {
          fail(configuration " has the wrong bootstrap count")
        }
        if (encodedBytes + 0 <= 0) {
          fail(configuration " has no encoded bytes")
        }
        if (lane in encodedBytesByLane) {
          if (encodedBytesByLane[lane] != encodedBytes) {
            fail(lane " has different warm and fresh encoded bytes")
          }
        } else {
          encodedBytesByLane[lane] = encodedBytes
        }
        if (length(corpusDigest) != 64 \
          || tolower(corpusDigest) !~ /^[0-9a-f]+$/)
        {
          fail(configuration " has an invalid corpus digest")
        }
        if (length(resultDigest) != 64 \
          || tolower(resultDigest) !~ /^[0-9a-f]+$/)
        {
          fail(configuration " has an invalid result digest")
        }
        if (outcome != expectedOutcome(operation)) {
          fail(configuration " has unexpected outcome " outcome)
        }
        if (workload in corpusByWorkload) {
          if (corpusByWorkload[workload] != corpusDigest) {
            fail(workload " has inconsistent corpus digests")
          }
          if (resultByWorkload[workload] != resultDigest) {
            fail(workload " has inconsistent result digests")
          }
        } else {
          corpusByWorkload[workload] = corpusDigest
          resultByWorkload[workload] = resultDigest
        }
      }
      END {
        if (rows != expectedRows) {
          fail("expected " expectedRows " rows, observed " rows)
        }
        if (modeRows["warm"] != expectedRowsPerMode) {
          fail("expected " expectedRowsPerMode \
            " warm rows, observed " modeRows["warm"])
        }
        if (modeRows["fresh-process"] != expectedRowsPerMode) {
          fail("expected " expectedRowsPerMode \
            " fresh-process rows, observed " modeRows["fresh-process"])
        }
        if (failed) {
          exit 42
        }
        print noise + 0
      }
    ' "$api03_summary_file"
)
then
  :
else
  api03_fail "summary evidence failed validation"
fi

api03_noise_threshold_exceeded=false
api03_evidence_validation_status=passed
if [ "$api03_quick" = false ] && [ "$api03_noise_count" -gt 0 ]; then
  api03_noise_threshold_exceeded=true
  api03_evidence_validation_status=noise-threshold-exceeded
fi

api03_ac_power_after_output=$(/usr/bin/pmset -g batt 2>/dev/null) \
  || api03_fail "could not inspect AC power state after measurement"
api03_ac_power_after=$(api03_first_line "$api03_ac_power_after_output")
api03_thermal_after_output=$(/usr/bin/pmset -g therm 2>/dev/null) \
  || api03_fail "could not inspect thermal state after measurement"
api03_thermal_after=$(api03_join_lines "$api03_thermal_after_output")

api03_ended_at=$(/bin/date -u '+%Y-%m-%dT%H:%M:%SZ')
/usr/bin/plutil -insert endedAtUTC -string "$api03_ended_at" -s \
  "$api03_environment_file"
/usr/bin/plutil -insert evidenceValidationStatus -string \
  "$api03_evidence_validation_status" \
  -s "$api03_environment_file"
/usr/bin/plutil -insert noiseThresholdExceeded -bool \
  "$api03_noise_threshold_exceeded" \
  -s "$api03_environment_file"
/usr/bin/plutil -insert noiseThresholdExceededConfigurationCount -integer \
  "$api03_noise_count" \
  -s "$api03_environment_file"
/usr/bin/plutil -insert acPowerAfter -string "$api03_ac_power_after" \
  -s "$api03_environment_file"
/usr/bin/plutil -insert thermalStateAfter -string "$api03_thermal_after" \
  -s "$api03_environment_file"
/usr/bin/plutil -convert json "$api03_environment_file"

if [ "$api03_noise_threshold_exceeded" = true ]; then
  api03_fail \
    "$api03_noise_count configurations exceeded the frozen noise thresholds; retain this run and rerun into a different directory"
fi

api03_progress "completed; evidence is in $api03_output_directory"
