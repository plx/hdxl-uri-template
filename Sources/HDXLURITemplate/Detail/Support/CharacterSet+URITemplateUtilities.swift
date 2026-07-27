import Foundation

extension CharacterSet {

  init(unionOf characterSets: [CharacterSet]) {
    self.init()
    for characterSet in characterSets {
      formUnion(characterSet)
    }
  }

  internal init(unionOf ranges: [Range<UnicodeScalar>]) {
    self.init()
    for range in ranges {
      insert(charactersIn: range)
    }
  }

  internal init(unionOf ranges: [ClosedRange<UnicodeScalar>]) {
    self.init()
    for range in ranges {
      insert(
        charactersIn: range
      )
    }
  }

}
