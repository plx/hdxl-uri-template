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

check-pinned-fixtures:
    ./Scripts/check-pinned-fixtures.sh

test-check-pinned-fixtures:
    ./Scripts/test-check-pinned-fixtures.sh

test-warning-guard:
    ./Scripts/test-run-without-warnings.sh

test-all: check-pinned-fixtures test-check-pinned-fixtures test-warning-guard check-public-api test-debug test-heavy-debug test-release

check-clean-output: build-debug test-debug build-heavy-debug test-heavy-debug build-release test-release
