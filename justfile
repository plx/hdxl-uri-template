
build-debug:
    swift build -c debug -q

build-release:
    swift build -c release -q

build-all: build-debug build-heavy-debug build-release

test-debug:
    swift test -c debug -q

test-release:
    swift test -c release -q

test-all: test-debug test-release
