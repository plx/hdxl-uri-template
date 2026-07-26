import CryptoKit
import Foundation

/// Stable, deliberately-small hashing support for the API-03 research format.
///
/// Every field is prefixed with an unsigned, big-endian 64-bit byte count.
/// This makes the input unambiguous without depending on `Codable`, property-list
/// key ordering, native integer width, or Swift's randomized `Hasher`.
package enum StableDigest {

  package static func sha256(
    lengthPrefixed fields: [Data]
  ) -> Data {
    var hasher = SHA256()

    for field in fields {
      var bigEndianLength = UInt64(field.count).bigEndian
      withUnsafeBytes(of: &bigEndianLength) { lengthBytes in
        hasher.update(bufferPointer: lengthBytes)
      }
      hasher.update(data: field)
    }

    return Data(hasher.finalize())
  }

  package static func sha256(
    lengthPrefixedUTF8 strings: [String]
  ) -> Data {
    sha256(
      lengthPrefixed: strings.map {
        Data($0.utf8)
      }
    )
  }

  package static func hex(
    _ digest: Data
  ) -> String {
    digest.map {
      String(format: "%02x", $0)
    }.joined()
  }

}
