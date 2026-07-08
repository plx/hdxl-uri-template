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
