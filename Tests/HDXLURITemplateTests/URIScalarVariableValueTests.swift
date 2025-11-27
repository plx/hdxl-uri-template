import Testing
import Foundation
@testable import HDXLURITemplate

extension Tag {
  @Tag
  static var uriScalarVariableValue: Self
}

@Suite(.tags(.uriScalarVariableValue))
struct URIScalarVariableValueTests {

  // MARK: - Construction Tests

  @Test
  func `text factory creates value`() {
    let value = URIScalarVariableValue.text("hello")
    #expect(!value.isEmpty)
  }

  @Test
  func `text factory with empty string`() {
    let value = URIScalarVariableValue.text("")
    #expect(value.isEmpty)
  }

  // MARK: - isEmpty Tests

  @Test
  func `isEmpty true for empty string`() {
    let value = URIScalarVariableValue.text("")
    #expect(value.isEmpty)
  }

  @Test
  func `isEmpty false for non-empty string`() {
    let value = URIScalarVariableValue.text("content")
    #expect(!value.isEmpty)
  }

  // MARK: - isValid Tests

  @Test
  func `isValid true for all values`() {
    let probes = [
      URIScalarVariableValue.text(""),
      URIScalarVariableValue.text("a"),
      URIScalarVariableValue.text("hello world"),
      URIScalarVariableValue.text("special chars: !@#$%")
    ]
    for probe in probes {
      #expect(probe.isValid)
    }
  }

  // MARK: - Equatable Tests

  @Test
  func `equal values are equal`() {
    let value1 = URIScalarVariableValue.text("test")
    let value2 = URIScalarVariableValue.text("test")
    #expect(value1 == value2)
  }

  @Test
  func `different values are not equal`() {
    let value1 = URIScalarVariableValue.text("hello")
    let value2 = URIScalarVariableValue.text("world")
    #expect(value1 != value2)
  }

  // MARK: - Hashable Tests

  @Test
  func `equal values have equal hashes`() {
    let value1 = URIScalarVariableValue.text("test")
    let value2 = URIScalarVariableValue.text("test")
    #expect(value1.hashValue == value2.hashValue)
  }

  @Test
  func `values work in sets`() {
    let value1 = URIScalarVariableValue.text("a")
    let value2 = URIScalarVariableValue.text("b")
    let value3 = URIScalarVariableValue.text("a")
    let set: Set<URIScalarVariableValue> = [value1, value2, value3]
    #expect(set.count == 2)
  }

  // MARK: - Comparable Tests

  @Test
  func `values are comparable`() {
    let value1 = URIScalarVariableValue.text("aaa")
    let value2 = URIScalarVariableValue.text("bbb")
    #expect(value1 < value2)
  }

  @Test
  func `values are correctly ordered`() {
    let probes = [
      URIScalarVariableValue.text(""),
      URIScalarVariableValue.text("a"),
      URIScalarVariableValue.text("ab"),
      URIScalarVariableValue.text("abc"),
      URIScalarVariableValue.text("b")
    ]
    verifyOrderedAscending(probes)
  }

  @Test
  func `equal values are not less than`() {
    let value1 = URIScalarVariableValue.text("same")
    let value2 = URIScalarVariableValue.text("same")
    #expect(!(value1 < value2))
    #expect(!(value2 < value1))
  }

  // MARK: - Codable Tests

  @Test
  func `codable round trip`() throws {
    let original = URIScalarVariableValue.text("hello world")
    let encoder = JSONEncoder()
    let data = try encoder.encode(original)
    let decoder = JSONDecoder()
    let decoded = try decoder.decode(URIScalarVariableValue.self, from: data)
    #expect(original == decoded)
  }

  @Test
  func `codable round trip empty string`() throws {
    let original = URIScalarVariableValue.text("")
    let encoder = JSONEncoder()
    let data = try encoder.encode(original)
    let decoder = JSONDecoder()
    let decoded = try decoder.decode(URIScalarVariableValue.self, from: data)
    #expect(original == decoded)
  }

  @Test
  func `codable round trip special characters`() throws {
    let original = URIScalarVariableValue.text("special!@#$%^&*()")
    let encoder = JSONEncoder()
    let data = try encoder.encode(original)
    let decoder = JSONDecoder()
    let decoded = try decoder.decode(URIScalarVariableValue.self, from: data)
    #expect(original == decoded)
  }

  @Test
  func `codable round trip unicode`() throws {
    let original = URIScalarVariableValue.text("unicode: \u{1F600}\u{1F4BB}")
    let encoder = JSONEncoder()
    let data = try encoder.encode(original)
    let decoder = JSONDecoder()
    let decoded = try decoder.decode(URIScalarVariableValue.self, from: data)
    #expect(original == decoded)
  }

  // MARK: - Description Tests

  @Test
  func `description returns raw value`() {
    let value = URIScalarVariableValue.text("hello")
    #expect(value.description == "hello")
  }

  @Test
  func `debugDescription contains type name`() {
    let value = URIScalarVariableValue.text("test")
    #expect(value.debugDescription.contains("URIVariableValue"))
    #expect(value.debugDescription.contains("storage"))
  }

  // MARK: - Fixture Tests

  @Test
  func `fixtures are ordered ascending`() {
    let probes = probeStrings.map { URIScalarVariableValue.text($0) }
    verifyOrderedAscending(probes)
  }

  @Test
  func `fixtures have unique descriptions`() {
    let probes = probeStrings.map { URIScalarVariableValue.text($0) }
    verifyUniqueStringification(probes, using: \.description)
  }

  @Test
  func `fixtures have unique debugDescriptions`() {
    let probes = probeStrings.map { URIScalarVariableValue.text($0) }
    verifyUniqueStringification(probes, using: \.debugDescription)
  }

}

// MARK: - Fixtures

private let probeStrings: [String] = [
  "",
  "a",
  "ab",
  "abc",
  "abcd",
  "abcde"
]
