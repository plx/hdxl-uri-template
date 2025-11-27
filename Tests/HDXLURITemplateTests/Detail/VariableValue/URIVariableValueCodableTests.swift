import Testing
import Foundation
@testable import HDXLURITemplate

extension Tag {
  @Tag
  static var uriVariableValueCodable: Self
}

@Suite(.tags(.uriVariableValueCodable))
struct URIVariableValueCodableTests {

  // MARK: - Undefined Codable Tests

  @Test
  func `undefined codable round trip`() throws {
    let original = URIVariableValue.undefined
    let encoder = JSONEncoder()
    let data = try encoder.encode(original)
    let decoder = JSONDecoder()
    let decoded = try decoder.decode(URIVariableValue.self, from: data)
    #expect(original == decoded)
    #expect(decoded.isUndefined)
  }

  // MARK: - Text Codable Tests

  @Test
  func `text codable round trip`() throws {
    let original = URIVariableValue.text("hello world")
    let encoder = JSONEncoder()
    let data = try encoder.encode(original)
    let decoder = JSONDecoder()
    let decoded = try decoder.decode(URIVariableValue.self, from: data)
    #expect(original == decoded)
    #expect(decoded.isTextValue)
  }

  @Test
  func `empty text codable round trip`() throws {
    let original = URIVariableValue.emptyString
    let encoder = JSONEncoder()
    let data = try encoder.encode(original)
    let decoder = JSONDecoder()
    let decoded = try decoder.decode(URIVariableValue.self, from: data)
    #expect(original == decoded)
    #expect(decoded.isTextValue)
    #expect(decoded.isEmpty)
  }

  @Test
  func `text with special characters codable round trip`() throws {
    let original = URIVariableValue.text("special: !@#$%^&*(){}[]|\\:\";<>?,./~`")
    let encoder = JSONEncoder()
    let data = try encoder.encode(original)
    let decoder = JSONDecoder()
    let decoded = try decoder.decode(URIVariableValue.self, from: data)
    #expect(original == decoded)
  }

  @Test
  func `text with unicode codable round trip`() throws {
    let original = URIVariableValue.text("unicode: \u{1F600}\u{1F4BB}\u{2764}")
    let encoder = JSONEncoder()
    let data = try encoder.encode(original)
    let decoder = JSONDecoder()
    let decoded = try decoder.decode(URIVariableValue.self, from: data)
    #expect(original == decoded)
  }

  @Test
  func `text with newlines codable round trip`() throws {
    let original = URIVariableValue.text("line1\nline2\r\nline3")
    let encoder = JSONEncoder()
    let data = try encoder.encode(original)
    let decoder = JSONDecoder()
    let decoded = try decoder.decode(URIVariableValue.self, from: data)
    #expect(original == decoded)
  }

  // MARK: - List Codable Tests

  @Test
  func `list codable round trip`() throws {
    let original = URIVariableValue.list(["a", "b", "c"])
    let encoder = JSONEncoder()
    let data = try encoder.encode(original)
    let decoder = JSONDecoder()
    let decoded = try decoder.decode(URIVariableValue.self, from: data)
    #expect(original == decoded)
    #expect(decoded.isListValue)
    #expect(decoded.count == 3)
  }

  @Test
  func `empty list codable round trip`() throws {
    let original = URIVariableValue.emptyList
    let encoder = JSONEncoder()
    let data = try encoder.encode(original)
    let decoder = JSONDecoder()
    let decoded = try decoder.decode(URIVariableValue.self, from: data)
    #expect(original == decoded)
    #expect(decoded.isListValue)
    #expect(decoded.isEmpty)
  }

  @Test
  func `single element list codable round trip`() throws {
    let original = URIVariableValue.list("single")
    let encoder = JSONEncoder()
    let data = try encoder.encode(original)
    let decoder = JSONDecoder()
    let decoded = try decoder.decode(URIVariableValue.self, from: data)
    #expect(original == decoded)
    #expect(decoded.count == 1)
  }

  @Test
  func `list with many elements codable round trip`() throws {
    let elements = (0..<100).map { "element\($0)" }
    let original = URIVariableValue.list(elements)
    let encoder = JSONEncoder()
    let data = try encoder.encode(original)
    let decoder = JSONDecoder()
    let decoded = try decoder.decode(URIVariableValue.self, from: data)
    #expect(original == decoded)
    #expect(decoded.count == 100)
  }

  // MARK: - Association Codable Tests

  @Test
  func `association codable round trip`() throws {
    let original = URIVariableValue.association([("key1", "value1"), ("key2", "value2")])
    let encoder = JSONEncoder()
    let data = try encoder.encode(original)
    let decoder = JSONDecoder()
    let decoded = try decoder.decode(URIVariableValue.self, from: data)
    #expect(original == decoded)
    #expect(decoded.isAssociationValue)
    #expect(decoded.count == 2)
  }

  @Test
  func `empty association codable round trip`() throws {
    let original = URIVariableValue.emptyAssociation
    let encoder = JSONEncoder()
    let data = try encoder.encode(original)
    let decoder = JSONDecoder()
    let decoded = try decoder.decode(URIVariableValue.self, from: data)
    #expect(original == decoded)
    #expect(decoded.isAssociationValue)
    #expect(decoded.isEmpty)
  }

  @Test
  func `single pair association codable round trip`() throws {
    let original = URIVariableValue.association(key: "name", value: "value")
    let encoder = JSONEncoder()
    let data = try encoder.encode(original)
    let decoder = JSONDecoder()
    let decoded = try decoder.decode(URIVariableValue.self, from: data)
    #expect(original == decoded)
    #expect(decoded.count == 1)
  }

  // MARK: - Property List Codable Tests

  @Test
  func `text plist codable round trip`() throws {
    let original = URIVariableValue.text("plist test")
    let encoder = PropertyListEncoder()
    encoder.outputFormat = .binary
    let data = try encoder.encode(original)
    let decoder = PropertyListDecoder()
    let decoded = try decoder.decode(URIVariableValue.self, from: data)
    #expect(original == decoded)
  }

  @Test
  func `list plist codable round trip`() throws {
    let original = URIVariableValue.list(["x", "y", "z"])
    let encoder = PropertyListEncoder()
    encoder.outputFormat = .binary
    let data = try encoder.encode(original)
    let decoder = PropertyListDecoder()
    let decoded = try decoder.decode(URIVariableValue.self, from: data)
    #expect(original == decoded)
  }

  // MARK: - Encoding Format Tests

  @Test
  func `different encoder formats produce decodable data`() throws {
    let original = URIVariableValue.association([("a", "1"), ("b", "2")])

    // JSON
    let jsonEncoder = JSONEncoder()
    jsonEncoder.outputFormatting = .prettyPrinted
    let jsonData = try jsonEncoder.encode(original)
    let jsonDecoded = try JSONDecoder().decode(URIVariableValue.self, from: jsonData)
    #expect(original == jsonDecoded)

    // Compact JSON
    let compactEncoder = JSONEncoder()
    let compactData = try compactEncoder.encode(original)
    let compactDecoded = try JSONDecoder().decode(URIVariableValue.self, from: compactData)
    #expect(original == compactDecoded)
  }

}
