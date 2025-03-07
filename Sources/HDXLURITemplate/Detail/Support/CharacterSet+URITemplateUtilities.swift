import Foundation

extension CharacterSet {
  
  @inlinable
  init(unionOf characterSets: [CharacterSet]) {
    self.init()
    for characterSet in characterSets {
      formUnion(characterSet)
    }
  }
  
  @inlinable
  internal init(charactersIn range: ClosedRange<UnicodeScalar>) {
    guard
      let upperBoundSuccessor = UnicodeScalar(
        range.upperBound.value + 1
      )
    else {
      preconditionFailure("Can't convert closed range \(String(reflecting: range)) to open range!")
    }
    self.init(
      charactersIn: range.lowerBound..<upperBoundSuccessor
    )
  }
  
  @inlinable
  internal init(unionOf ranges: [Range<UnicodeScalar>]) {
    self.init()
    for range in ranges {
      insert(charactersIn: range)
    }
  }
  
  @inlinable
  internal init(unionOf ranges: [ClosedRange<UnicodeScalar>]) {
    self.init()
    for range in ranges {
      insert(
        charactersIn: range
      )
    }
  }
  
}
