import Foundation

// RFC-derived Code Components in this file are attributed in
// THIRD_PARTY_NOTICES.md.

// RFC 6570 section 3.1 defines literal ASCII independently from the
// operator-specific character sets used for variable-value expansion.
@usableFromInline
internal let rfcLiteralASCIIAllowedCharacterSet = CharacterSet(
  charactersIn:
    "!#$%&'()*+,-./0123456789:;=?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[]_abcdefghijklmnopqrstuvwxyz~"
)

extension URITemplateLiteralComponent {

  @inlinable
  internal var expansionRepresentation: String {
#if HEAVY_DEBUG
    pedanticAssert(isValid)
#endif
    return rawValue.escapedPreservingPercentEncodedTriplets(
      allowedCharacters: rfcLiteralASCIIAllowedCharacterSet
    )
  }

}
