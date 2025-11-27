import Testing
import Foundation
@testable import HDXLURITemplate

extension Tag {
  @Tag
  static var uriVariableValueLiteral: Self
}

// MARK: - ExpressibleByNilLiteral Tests

@Suite(.tags(.uriVariableValueLiteral))
struct URIVariableValueNilLiteralTests {

  @Test
  func `nil literal creates undefined value`() {
    let value: URIVariableValue = nil
    #expect(value.isUndefined)
    #expect(value == .undefined)
  }

  @Test
  func `nil literal valueType is undefined`() {
    let value: URIVariableValue = nil
    #expect(value.valueType == .undefined)
  }

}

// MARK: - ExpressibleByStringLiteral Tests

@Suite(.tags(.uriVariableValueLiteral))
struct URIVariableValueStringLiteralTests {

  @Test
  func `string literal creates text value`() {
    let value: URIVariableValue = "hello"
    #expect(value.isTextValue)
    #expect(value.valueType == .text)
  }

  @Test
  func `empty string literal creates text value`() {
    let value: URIVariableValue = ""
    #expect(value.isTextValue)
    #expect(value.isEmpty)
  }

  @Test
  func `string literal with unicode`() {
    let value: URIVariableValue = "emoji: \u{1F600}"
    #expect(value.isTextValue)
    #expect(!value.isEmpty)
  }

}

// MARK: - ExpressibleByUnicodeScalarLiteral Tests

@Suite(.tags(.uriVariableValueLiteral))
struct URIVariableValueUnicodeScalarLiteralTests {

  @Test
  func `unicode scalar literal creates text value`() {
    let scalar: Unicode.Scalar = "A"
    let value = URIVariableValue(unicodeScalarLiteral: scalar)
    #expect(value.isTextValue)
  }

}

// MARK: - ExpressibleByExtendedGraphemeClusterLiteral Tests

@Suite(.tags(.uriVariableValueLiteral))
struct URIVariableValueExtendedGraphemeClusterLiteralTests {

  @Test
  func `extended grapheme cluster literal creates text value`() {
    let cluster: Character = "A"
    let value = URIVariableValue(extendedGraphemeClusterLiteral: cluster)
    #expect(value.isTextValue)
  }

}

// MARK: - ExpressibleByIntegerLiteral Tests

@Suite(.tags(.uriVariableValueLiteral))
struct URIVariableValueIntegerLiteralTests {

  @Test
  func `integer literal creates text value`() {
    let value: URIVariableValue = 42
    #expect(value.isTextValue)
    #expect(value.valueType == .text)
  }

  @Test
  func `zero literal creates text value`() {
    let value: URIVariableValue = 0
    #expect(value.isTextValue)
  }

  @Test
  func `negative integer literal creates text value`() {
    let value: URIVariableValue = -123
    #expect(value.isTextValue)
  }

  @Test
  func `large integer literal creates text value`() {
    let value: URIVariableValue = 999999999
    #expect(value.isTextValue)
  }

}

// MARK: - ExpressibleByFloatLiteral Tests

@Suite(.tags(.uriVariableValueLiteral))
struct URIVariableValueFloatLiteralTests {

  @Test
  func `float literal creates text value`() {
    let value: URIVariableValue = 3.14
    #expect(value.isTextValue)
    #expect(value.valueType == .text)
  }

  @Test
  func `zero float literal creates text value`() {
    let value: URIVariableValue = 0.0
    #expect(value.isTextValue)
  }

  @Test
  func `negative float literal creates text value`() {
    let value: URIVariableValue = -2.5
    #expect(value.isTextValue)
  }

}

// MARK: - ExpressibleByArrayLiteral Tests

@Suite(.tags(.uriVariableValueLiteral))
struct URIVariableValueArrayLiteralTests {

  @Test
  func `array literal creates list value`() {
    let value: URIVariableValue = [.text("a"), .text("b"), .text("c")]
    #expect(value.isListValue)
    #expect(value.valueType == .list)
  }

  @Test
  func `empty array literal creates list value`() {
    // Use the factory method for empty lists since empty array literals
    // cannot be inferred from context without a concrete element type
    let value = URIVariableValue.emptyList
    #expect(value.isListValue)
    #expect(value.isEmpty)
  }

  @Test
  func `single element array literal`() {
    let value: URIVariableValue = [.text("single")]
    #expect(value.isListValue)
    #expect(value.count == 1)
  }

}

// MARK: - ExpressibleByDictionaryLiteral Tests

@Suite(.tags(.uriVariableValueLiteral))
struct URIVariableValueDictionaryLiteralTests {

  @Test
  func `dictionary literal creates association value`() {
    let value: URIVariableValue = ["key": .text("value")]
    #expect(value.isAssociationValue)
    #expect(value.valueType == .association)
  }

  @Test
  func `empty dictionary literal creates association value`() {
    // Use the factory method for empty associations since empty dictionary literals
    // cannot be inferred from context without concrete types
    let value = URIVariableValue.emptyAssociation
    #expect(value.isAssociationValue)
    #expect(value.isEmpty)
  }

  @Test
  func `multiple pairs dictionary literal`() {
    let value: URIVariableValue = [
      "a": .text("1"),
      "b": .text("2"),
      "c": .text("3")
    ]
    #expect(value.isAssociationValue)
    #expect(value.count == 3)
  }

}

// MARK: - Factory Method Tests

@Suite(.tags(.uriVariableValueLiteral))
struct URIVariableValueFactoryTests {

  // MARK: - Text Factory

  @Test
  func `text factory creates text value`() {
    let value = URIVariableValue.text("hello")
    #expect(value.isTextValue)
  }

  // MARK: - Boolean Factories

  @Test
  func `trueOrFalse true lowercase`() {
    let value = URIVariableValue.trueOrFalse(boolValue: true, capitalization: .lowercase)
    #expect(value.isTextValue)
  }

  @Test
  func `trueOrFalse false lowercase`() {
    let value = URIVariableValue.trueOrFalse(boolValue: false, capitalization: .lowercase)
    #expect(value.isTextValue)
  }

  @Test
  func `trueOrFalse true capitalized`() {
    let value = URIVariableValue.trueOrFalse(boolValue: true, capitalization: .capitalized)
    #expect(value.isTextValue)
  }

  @Test
  func `trueOrFalse true allCaps`() {
    let value = URIVariableValue.trueOrFalse(boolValue: true, capitalization: .allCaps)
    #expect(value.isTextValue)
  }

  @Test
  func `yesOrNo true lowercase`() {
    let value = URIVariableValue.yesOrNo(boolValue: true, capitalization: .lowercase)
    #expect(value.isTextValue)
  }

  @Test
  func `yesOrNo false lowercase`() {
    let value = URIVariableValue.yesOrNo(boolValue: false, capitalization: .lowercase)
    #expect(value.isTextValue)
  }

  @Test
  func `yOrN true allCaps`() {
    let value = URIVariableValue.yOrN(boolValue: true, capitalization: .allCaps)
    #expect(value.isTextValue)
  }

  @Test
  func `yOrN false allCaps`() {
    let value = URIVariableValue.yOrN(boolValue: false, capitalization: .allCaps)
    #expect(value.isTextValue)
  }

  @Test
  func `yOrN default capitalization`() {
    let value = URIVariableValue.yOrN(boolValue: true)
    #expect(value.isTextValue)
  }

  @Test
  func `zeroOrOne true`() {
    let value = URIVariableValue.zeroOrOne(boolValue: true)
    #expect(value.isTextValue)
  }

  @Test
  func `zeroOrOne false`() {
    let value = URIVariableValue.zeroOrOne(boolValue: false)
    #expect(value.isTextValue)
  }

  // MARK: - Integer Factory

  @Test
  func `integer factory with Int`() {
    let value = URIVariableValue.integer(42)
    #expect(value.isTextValue)
  }

  @Test
  func `integer factory with Int8`() {
    let value = URIVariableValue.integer(Int8(127))
    #expect(value.isTextValue)
  }

  @Test
  func `integer factory with Int16`() {
    let value = URIVariableValue.integer(Int16(32000))
    #expect(value.isTextValue)
  }

  @Test
  func `integer factory with Int32`() {
    let value = URIVariableValue.integer(Int32(100000))
    #expect(value.isTextValue)
  }

  @Test
  func `integer factory with Int64`() {
    let value = URIVariableValue.integer(Int64(9999999999))
    #expect(value.isTextValue)
  }

  @Test
  func `integer factory with UInt`() {
    let value = URIVariableValue.integer(UInt(42))
    #expect(value.isTextValue)
  }

  @Test
  func `integer factory with negative`() {
    let value = URIVariableValue.integer(-99)
    #expect(value.isTextValue)
  }

  @Test
  func `integer factory with zero`() {
    let value = URIVariableValue.integer(0)
    #expect(value.isTextValue)
  }

  // MARK: - List Factory

  @Test
  func `list factory with sequence`() {
    let value = URIVariableValue.list(["a", "b", "c"])
    #expect(value.isListValue)
    #expect(value.count == 3)
  }

  @Test
  func `list factory with empty sequence`() {
    let value = URIVariableValue.list([] as [String])
    #expect(value.isListValue)
    #expect(value.isEmpty)
  }

  @Test
  func `list factory with single string`() {
    let value = URIVariableValue.list("single")
    #expect(value.isListValue)
    #expect(value.count == 1)
  }

  // MARK: - Association Factory

  @Test
  func `association factory with sequence of pairs`() {
    let value = URIVariableValue.association([("a", "1"), ("b", "2")])
    #expect(value.isAssociationValue)
    #expect(value.count == 2)
  }

  @Test
  func `association factory with empty sequence`() {
    let value = URIVariableValue.association([] as [(String, String)])
    #expect(value.isAssociationValue)
    #expect(value.isEmpty)
  }

  @Test
  func `association factory with single pair`() {
    let value = URIVariableValue.association(key: "key", value: "value")
    #expect(value.isAssociationValue)
    #expect(value.count == 1)
  }

}

// MARK: - Well-Known Values Tests

@Suite(.tags(.uriVariableValueLiteral))
struct URIVariableValueWellKnownValuesTests {

  @Test
  func `undefined well-known value`() {
    let value = URIVariableValue.undefined
    #expect(value.isUndefined)
    #expect(value.isEmpty)
  }

  @Test
  func `emptyString well-known value`() {
    let value = URIVariableValue.emptyString
    #expect(value.isTextValue)
    #expect(value.isEmpty)
  }

  @Test
  func `emptyList well-known value`() {
    let value = URIVariableValue.emptyList
    #expect(value.isListValue)
    #expect(value.isEmpty)
  }

  @Test
  func `emptyAssociation well-known value`() {
    let value = URIVariableValue.emptyAssociation
    #expect(value.isAssociationValue)
    #expect(value.isEmpty)
  }

}
