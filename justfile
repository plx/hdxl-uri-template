set quiet

# SwiftPM's `-q` hides resource warnings that this guard must inspect.
warning_guard := "./Scripts/run-without-warnings.sh"

swift := "xcrun swift"

default:
    @just --list

resolve:
    {{ swift }} package resolve

dump-package:
    {{ swift }} package dump-package

build-debug:
    {{ warning_guard }} {{ swift }} build -c debug

build-heavy-debug:
    {{ warning_guard }} {{ swift }} build -c debug -Xswiftc -DHEAVY_DEBUG

build-release:
    {{ warning_guard }} {{ swift }} build -c release

build-all: build-debug build-heavy-debug build-release

test-debug:
    {{ warning_guard }} {{ swift }} test -c debug

test-heavy-debug:
    {{ warning_guard }} {{ swift }} test -c debug -Xswiftc -DHEAVY_DEBUG

test-release:
    {{ warning_guard }} {{ swift }} test -c release

check-public-api:
    {{ swift }} Scripts/check-public-api.swift

check-immutable-template-storage:
    {{ swift }} Scripts/check-immutable-template-storage.swift

check-pinned-fixtures:
    ./Scripts/check-pinned-fixtures.sh

test-check-pinned-fixtures:
    ./Scripts/test-check-pinned-fixtures.sh

test-warning-guard:
    ./Scripts/test-run-without-warnings.sh

qa-03-smoke:
    QA03_COMMIT="$(git rev-parse HEAD)" {{ swift }} run -c release HDXLURITemplateQA03 fuzz --seed 0x4844584C51413033 --iterations 200000 --fixtures Tests/HDXLURITemplateTests/Resources
    QA03_COMMIT="$(git rev-parse HEAD)" {{ swift }} run -c release HDXLURITemplateQA03 concurrency --operations 100000
    QA03_COMMIT="$(git rev-parse HEAD)" {{ swift }} run -c release HDXLURITemplateQA03 scaling --baseline Hardening/QA03/baselines.json --samples 5

qa-03-detectors:
    ./Scripts/test-qa-03-detectors.sh

test-all: check-pinned-fixtures test-check-pinned-fixtures test-warning-guard check-public-api check-immutable-template-storage test-debug test-heavy-debug test-release

check-clean-output: build-debug test-debug build-heavy-debug test-heavy-debug build-release test-release

arch-01-benchmark label commit:
    {{ swift }} run -c release HDXLURITemplateARCH01Benchmark --label {{ label }} --commit {{ commit }}

arch-02-benchmark label commit:
    ARCH02_SWIFT_VERSION="$({{ swift }} --version | head -n 1)" {{ swift }} run -c release HDXLURITemplateARCH02Benchmark --label {{ label }} --commit {{ commit }}

arch-02-inventory label commit:
    {{ swift }} Scripts/inventory-cross-module-inlining.swift --label {{ label }} --commit {{ commit }}

arch-02-measure label commit:
    DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer {{ swift }} Scripts/measure-arch-02.swift --label {{ label }} --commit {{ commit }}
