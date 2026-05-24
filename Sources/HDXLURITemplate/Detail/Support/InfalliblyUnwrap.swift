import Foundation

/// Unwraps a value that is guaranteed by construction to be non-`nil`.
///
/// Prefer this over a bare `!` so the rationale lives next to the
/// unwrap. The `explanation` is required to be non-empty at runtime;
/// keep it specific to the call site — describe the invariant that
/// makes the value safe to unwrap, not just *that* it is safe.
///
/// - Parameters:
///   - value: An `Optional<T>` that cannot, by construction, be `nil`.
///   - explanation: A `StaticString` describing why `value` cannot be `nil`.
/// - Returns: The wrapped value.
@inlinable
@inline(__always)
internal func infalliblyUnwrap<T>(
  _ value: T?,
  explanation: StaticString
) -> T {
  assert(
    explanation.utf8CodeUnitCount > 0,
    "`infalliblyUnwrap` requires a non-empty explanation."
  )
  return value!
}
