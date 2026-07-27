extension Collection {

  var smallPowerSet: [[Element]] {
    guard !isEmpty else {
      return []
    }
    guard count <= 8 else {
      fatalError(
        """
        `smallPowerSet` is only allowed with collections of size <= 8!  
        """
      )
    }

    let elements = Array(self)

    let upperBound: Int = (1 << count) - 1
    assert(upperBound >= 0)

    var results: [[Element]] = []
    for bitMask in 0...upperBound {
      var subset: [Element] = []
      for i in 0..<count {
        if 0 != (bitMask & (1 << i)) {
          subset.append(elements[i])
        }
      }
      results.append(subset)
    }
    return results
  }

}
