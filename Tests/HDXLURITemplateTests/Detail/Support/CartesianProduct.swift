// simplistic implementation suitable for testing
// without dragging in a giant dependency

func cartesianProduct<A, B>(_ lhs: some Collection<A>, _ rhs: some Collection<B>) -> [(A, B)] {
  var result: [(A, B)] = []
  result.reserveCapacity(lhs.count * rhs.count)
  for x in lhs {
    for y in rhs {
      result.append((x, y))
    }
  }
  return result
}
