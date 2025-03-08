import Testing
@testable import HDXLURITemplate

extension Tag {
  @Tag
  static var standardEncodingCodingKeys: Self
}

@Test(
  "`StandardEncodingCodingKeys.intValues` is sensible",
  .tags(.standardEncodingCodingKeys)
)
private func intValuesExistAndUnique() throws {
  let typeIntValue = try #require(StandardEnumerationCodingKeys.type.intValue)
  let dataIntValue = try #require(StandardEnumerationCodingKeys.data.intValue)
  #expect(typeIntValue != dataIntValue)
}

@Test(
  "`StandardEncodingCodingKeys.intValues` round-trips",
  .tags(.standardEncodingCodingKeys),
  arguments: StandardEnumerationCodingKeys.allCases
)
private func intValuesRoundTrip(probe: StandardEnumerationCodingKeys) throws {
  let intValue = try #require(probe.intValue)
  let roundTrippedProbe = try #require(StandardEnumerationCodingKeys(intValue: intValue))
  #expect(probe == roundTrippedProbe)
}
