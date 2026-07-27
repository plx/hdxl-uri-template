import Foundation

extension NSRegularExpression {
  
  internal func matchesEntirety(of string: String) -> Bool {
    let completeRange = NSRange(
      string.startIndex..<string.endIndex,
      in: string
    )
    return completeRange == rangeOfFirstMatch(
      in: string,
      options: .anchored,
      range: completeRange
    )
  }
  
}
