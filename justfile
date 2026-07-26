set quiet := true

default:
    @just --list

build-debug:
    swift build -c debug -q

build-heavy-debug:
    swift build -c debug -q -Xswiftc -DHEAVY_DEBUG 

build-release:
    swift build -c release -q

build-all: build-debug build-heavy-debug build-release

test-debug:
    swift test -c debug -q

test-release:
    swift test -c release -q

check-public-api:
    swift Scripts/check-public-api.swift

test-all: check-public-api test-debug test-release
