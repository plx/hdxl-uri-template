/// Unwraps a value that is guaranteed by construction to be non-`nil`.
///
/// Prefer this over a bare `!` so the rationale lives next to the unwrap.
/// The `explanation` must be non-empty and — should the "impossible" `nil`
/// ever occur — is used as the trap message, so it appears in the crash log
/// in both debug *and* release builds. Keep it specific to the call site:
/// describe the invariant that makes the value safe to unwrap, not just
/// *that* it is safe.
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
  // Use `precondition`/`preconditionFailure` rather than `assert`/`!` so the
  // contract is enforced — and the explanation surfaced — in release builds.
  precondition(
    explanation.utf8CodeUnitCount > 0,
    "`infalliblyUnwrap` requires a non-empty explanation."
  )
  guard let value else {
    preconditionFailure("\(explanation)")
  }
  return value
}
