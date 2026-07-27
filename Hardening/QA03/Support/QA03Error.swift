import Foundation

package struct QA03Error:
  Error,
  CustomStringConvertible,
  Sendable
{
  package let description: String

  package init(_ description: String) {
    self.description = description
  }
}

extension Duration {

  package var qa03Nanoseconds: UInt64 {
    let components = self.components
    let wholeSeconds = UInt64(max(0, components.seconds))
    let positiveAttoseconds = UInt64(max(0, components.attoseconds))
    return wholeSeconds &* 1_000_000_000
      &+ positiveAttoseconds / 1_000_000_000
  }
}

package func qa03Hex(_ value: UInt64) -> String {
  "0x" + String(value, radix: 16, uppercase: true)
}

package func qa03StableDigest(_ string: String) -> UInt64 {
  string.utf8.reduce(0xCBF2_9CE4_8422_2325) { partialResult, byte in
    (partialResult ^ UInt64(byte)) &* 0x0000_0100_0000_01B3
  }
}
