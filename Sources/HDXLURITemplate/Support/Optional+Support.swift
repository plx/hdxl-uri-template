
extension Optional {

  @inlinable
  mutating func obtainAssuredValue(
    guaranteedBy fallback: @autoclosure () -> Wrapped
  ) -> Wrapped {
    switch self {
    case .none:
      let value = fallback()
      self = .some(value)
      return value
    case .some(let existingValue):
      return existingValue
    }
  }

}
