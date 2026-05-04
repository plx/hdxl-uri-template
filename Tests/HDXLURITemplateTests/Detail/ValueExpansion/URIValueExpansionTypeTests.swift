import Foundation
import Testing
@testable import HDXLURITemplate

extension Tag {
  @Tag
  static var uriValueExpansionType: Self
}

@Test(
  "`URIValueExpansionType.allCases` is ordered ascending",
  .tags(.uriValueExpansionType)
)
private func allCasesOrderedAscending() {
  verifyOrderedAscending(URIValueExpansionType.allCases)
}

@Test(
  "`URIValueExpansionType` has unique descriptions",
  .tags(.uriValueExpansionType)
)
private func uniqueDescriptions() {
  verifyUniqueStringification(
    URIValueExpansionType.allCases,
    using: \.description
  )
}

@Test(
  "`URIValueExpansionType` has unique debugDescriptions",
  .tags(.uriValueExpansionType)
)
private func uniqueDebugDescriptions() {
  verifyUniqueStringification(
    URIValueExpansionType.allCases,
    using: \.debugDescription
  )
}

@Test(
  "`URIValueExpansionType` round-trips with format strings",
  .tags(.uriValueExpansionType),
  arguments: URIValueExpansionType.allCases
)
private func formatStringRoundTrip(expansionType: URIValueExpansionType) throws {
  let formatString = expansionType.formatString
  let roundTrippedExpansionType = try #require(URIValueExpansionType(formatString: formatString))
  #expect(
    expansionType == roundTrippedExpansionType,
    """
    Failed to round-trip `\(expansionType)` through intermediate format-string `\(formatString)`!
    """
  )
}

@Test(
  "`ucschar` scalar ranges match RFC 6570",
  .tags(.uriValueExpansionType)
)
private func ucscharScalarRangesMatchRFC6570() throws {
  let finalDPlaneScalar = try #require(UnicodeScalar(0xDFFFD))
  let excludedEPlaneScalar = try #require(UnicodeScalar(0xE0000))
  let firstIncludedEPlaneScalar = try #require(UnicodeScalar(0xE1000))
  let finalEPlaneScalar = try #require(UnicodeScalar(0xEFFFD))

  #expect(rfc_ucschar.contains(finalDPlaneScalar))
  #expect(!rfc_ucschar.contains(excludedEPlaneScalar))
  #expect(rfc_ucschar.contains(firstIncludedEPlaneScalar))
  #expect(rfc_ucschar.contains(finalEPlaneScalar))
}
