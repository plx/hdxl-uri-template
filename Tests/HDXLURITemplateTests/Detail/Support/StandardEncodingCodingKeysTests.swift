import Testing
@testable import HDXLURITemplate

extension Tag {
  @Tag
  static var standardEncodingCodingKeys: Self
}

@Suite(.tags(.standardEncodingCodingKeys))
struct StandardEncodingCodingKeysTests {
  
  @Test
  private func `distinct intValues`() throws {
    let typeIntValue = try #require(StandardEnumerationCodingKeys.type.intValue)
    let dataIntValue = try #require(StandardEnumerationCodingKeys.data.intValue)
    #expect(typeIntValue != dataIntValue)
  }
  
  @Test(arguments: StandardEnumerationCodingKeys.allCases)
  private func `intValue round-trip`(
    probe: StandardEnumerationCodingKeys
  ) throws {
    let intValue = try #require(probe.intValue)
    let roundTrippedProbe = try #require(StandardEnumerationCodingKeys(intValue: intValue))
    #expect(probe == roundTrippedProbe)
  }

}
