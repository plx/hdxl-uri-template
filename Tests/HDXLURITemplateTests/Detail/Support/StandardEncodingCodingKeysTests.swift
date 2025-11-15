import Testing
@testable import HDXLURITemplate

extension Tag {
  @Tag
  static var standardEnumerationCodingKeys: Self
}

@Test(
  "`StandardEnumerationCodingKeys.intValues` is sensible",
  .tags(.standardEnumerationCodingKeys)
)
private func intValuesExistAndUnique() throws {
  let typeIntValue = try #require(StandardEnumerationCodingKeys.type.intValue)
  let dataIntValue = try #require(StandardEnumerationCodingKeys.data.intValue)
  #expect(typeIntValue != dataIntValue)
}

@Test(
  "`StandardEnumerationCodingKeys.intValues` round-trips",
  .tags(.standardEnumerationCodingKeys),
  arguments: StandardEnumerationCodingKeys.allCases
)
private func intValuesRoundTrip(probe: StandardEnumerationCodingKeys) throws {
  let intValue = try #require(probe.intValue)
  let roundTrippedProbe = try #require(StandardEnumerationCodingKeys(intValue: intValue))
  #expect(probe == roundTrippedProbe)
}
