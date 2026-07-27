import Foundation

#if HEAVY_DEBUG
internal func pedanticAssert(
  _ condition: @autoclosure () -> Bool,
  _ message: @autoclosure () -> String = "",
  file: StaticString = #file,
  line: UInt = #line) {
  assert(condition(), message(), file: file, line: line)
}

internal func pedanticAssertionFailure(
  _ message: @autoclosure () -> String = "",
  file: StaticString = #file,
  line: UInt = #line) {
  assertionFailure(message(), file: file, line: line)
}


internal func pedanticPrecondition(
  _ condition: @autoclosure () -> Bool,
  _ message: @autoclosure () -> String = "",
  file: StaticString = #file,
  line: UInt = #line) {
  precondition(condition(), message(), file: file, line: line)
}

internal func pedanticPreconditionFailure(
  _ message: @autoclosure () -> String = "",
  file: StaticString = #file,
  line: UInt = #line) {
  preconditionFailure(message(), file: file, line: line)
}

#endif
