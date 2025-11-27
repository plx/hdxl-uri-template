import Testing
import Foundation
@testable import HDXLURITemplateObjC
@testable import HDXLURITemplate

extension Tag {
  @Tag
  static var uriVariableValueWrapper: Self
}

// MARK: - Construction Tests

@Suite(.tags(.uriVariableValueWrapper))
struct URIVariableValueWrapperConstructionTests {

  // MARK: - Well-Known Values

  @Test func `undefined creates undefined value`() {
    let value = URIVariableValueWrapper.undefined
    #expect(value.isUndefinedVariableValue)
    #expect(!value.isDefinedVariableValue)
    #expect(value.variableValueType == .undefined)
  }

  @Test func `emptyString creates text value`() {
    let value = URIVariableValueWrapper.emptyString
    #expect(value.isTextVariableValue)
    #expect(value.textValue == "")
    #expect(value.variableValueType == .text)
  }

  @Test func `emptyList creates list value`() {
    let value = URIVariableValueWrapper.emptyList
    #expect(value.isListVariableValue)
    #expect(value.listValue == [])
    #expect(value.variableValueType == .list)
  }

  @Test func `emptyAssociation creates association value`() {
    let value = URIVariableValueWrapper.emptyAssociation
    #expect(value.isAssociationVariableValue)
    #expect(value.associationValueAsDictionary == [:])
    #expect(value.variableValueType == .association)
  }

  // MARK: - String Initializer

  @Test func `string initializer creates text`() {
    let value = URIVariableValueWrapper(string: "hello")
    #expect(value.isTextVariableValue)
    #expect(value.textValue == "hello")
  }

  @Test func `string initializer empty string`() {
    let value = URIVariableValueWrapper(string: "")
    #expect(value.isTextVariableValue)
    #expect(value.textValue == "")
  }

  // MARK: - Strings Array Initializer

  @Test func `strings initializer creates list`() {
    let value = URIVariableValueWrapper(strings: ["a", "b", "c"])
    #expect(value.isListVariableValue)
    #expect(value.listValue == ["a", "b", "c"])
  }

  @Test func `strings initializer empty array`() {
    let value = URIVariableValueWrapper(strings: [])
    #expect(value.isListVariableValue)
    #expect(value.listValue == [])
  }

  // MARK: - Key-Value Pair Initializer

  @Test func `key value initializer creates association`() {
    let value = URIVariableValueWrapper(key: "name", value: "alice")
    #expect(value.isAssociationVariableValue)
    #expect(value.associationValueAsDictionary == ["name": "alice"])
  }

  // MARK: - Keys-Values Arrays Initializer

  @Test func `keys values initializer creates association`() {
    let value = URIVariableValueWrapper(
      keys: ["a", "b"],
      values: ["1", "2"]
    )
    #expect(value.isAssociationVariableValue)
    let dict = value.associationValueAsDictionary
    #expect(dict?["a"] == "1")
    #expect(dict?["b"] == "2")
  }

  @Test func `keys values empty arrays`() {
    let value = URIVariableValueWrapper(keys: [], values: [])
    #expect(value.isAssociationVariableValue)
    #expect(value.associationValueAsDictionary == [:])
  }

  // MARK: - Dictionary Initializer

  @Test func `dictionary initializer creates association`() {
    let value = URIVariableValueWrapper(
      dictionary: ["x": "10", "y": "20"]
    ) { $0.compare($1) }
    #expect(value.isAssociationVariableValue)
    #expect(value.associationValueAsDictionary == ["x": "10", "y": "20"])
  }

  @Test func `dictionary initializer empty dictionary`() {
    let value = URIVariableValueWrapper(dictionary: [:]) { $0.compare($1) }
    #expect(value.isAssociationVariableValue)
    #expect(value.associationValueAsDictionary == [:])
  }

  // MARK: - Signed Integer Constructors

  @Test func `make with Int`() {
    let value = URIVariableValueWrapper.make(wrapping: 42)
    #expect(value.isTextVariableValue)
    #expect(value.textValue == "42")
  }

  @Test func `make with negative Int`() {
    let value = URIVariableValueWrapper.make(wrapping: -123)
    #expect(value.isTextVariableValue)
    #expect(value.textValue == "-123")
  }

  @Test func `make with Int8`() {
    let value = URIVariableValueWrapper.make(wrapping: Int8(127))
    #expect(value.isTextVariableValue)
    #expect(value.textValue == "127")
  }

  @Test func `make with Int16`() {
    let value = URIVariableValueWrapper.make(wrapping: Int16(32000))
    #expect(value.isTextVariableValue)
    #expect(value.textValue == "32000")
  }

  @Test func `make with Int32`() {
    let value = URIVariableValueWrapper.make(wrapping: Int32(100000))
    #expect(value.isTextVariableValue)
    #expect(value.textValue == "100000")
  }

  @Test func `make with Int64`() {
    let value = URIVariableValueWrapper.make(wrapping: Int64(9876543210))
    #expect(value.isTextVariableValue)
    #expect(value.textValue == "9876543210")
  }

  @Test func `make with zero`() {
    let value = URIVariableValueWrapper.make(wrapping: 0)
    #expect(value.isTextVariableValue)
    #expect(value.textValue == "0")
  }

  // MARK: - Unsigned Integer Constructors

  @Test func `make with UInt`() {
    let value = URIVariableValueWrapper.make(wrapping: UInt(99))
    #expect(value.isTextVariableValue)
    #expect(value.textValue == "99")
  }

  @Test func `make with UInt8`() {
    let value = URIVariableValueWrapper.make(wrapping: UInt8(255))
    #expect(value.isTextVariableValue)
    #expect(value.textValue == "255")
  }

  @Test func `make with UInt16`() {
    let value = URIVariableValueWrapper.make(wrapping: UInt16(65000))
    #expect(value.isTextVariableValue)
    #expect(value.textValue == "65000")
  }

  @Test func `make with UInt32`() {
    let value = URIVariableValueWrapper.make(wrapping: UInt32(4000000000))
    #expect(value.isTextVariableValue)
    #expect(value.textValue == "4000000000")
  }

  @Test func `make with UInt64`() {
    let value = URIVariableValueWrapper.make(wrapping: UInt64(18446744073709551615))
    #expect(value.isTextVariableValue)
    #expect(value.textValue == "18446744073709551615")
  }

  // MARK: - Boolean Constructors - Yes/No

  @Test func `makeYesOrNo true lowercase`() {
    let value = URIVariableValueWrapper.makeYesOrNo(
      wrapping: true,
      capitalization: .lowercase
    )
    #expect(value.isTextVariableValue)
    #expect(value.textValue == "yes")
  }

  @Test func `makeYesOrNo false lowercase`() {
    let value = URIVariableValueWrapper.makeYesOrNo(
      wrapping: false,
      capitalization: .lowercase
    )
    #expect(value.isTextVariableValue)
    #expect(value.textValue == "no")
  }

  @Test func `makeYesOrNo true capitalized`() {
    let value = URIVariableValueWrapper.makeYesOrNo(
      wrapping: true,
      capitalization: .capitalized
    )
    #expect(value.isTextVariableValue)
    #expect(value.textValue == "Yes")
  }

  @Test func `makeYesOrNo false capitalized`() {
    let value = URIVariableValueWrapper.makeYesOrNo(
      wrapping: false,
      capitalization: .capitalized
    )
    #expect(value.isTextVariableValue)
    #expect(value.textValue == "No")
  }

  @Test func `makeYesOrNo true allCaps`() {
    let value = URIVariableValueWrapper.makeYesOrNo(
      wrapping: true,
      capitalization: .allCaps
    )
    #expect(value.isTextVariableValue)
    #expect(value.textValue == "YES")
  }

  @Test func `makeYesOrNo false allCaps`() {
    let value = URIVariableValueWrapper.makeYesOrNo(
      wrapping: false,
      capitalization: .allCaps
    )
    #expect(value.isTextVariableValue)
    #expect(value.textValue == "NO")
  }

  @Test func `makeYesOrNo default capitalization`() {
    let value = URIVariableValueWrapper.makeYesOrNo(wrapping: true)
    #expect(value.textValue == "yes")
  }

  // MARK: - Boolean Constructors - Y/N

  @Test func `makeYOrN true allCaps`() {
    let value = URIVariableValueWrapper.makeYOrN(
      wrapping: true,
      capitalization: .allCaps
    )
    #expect(value.isTextVariableValue)
    #expect(value.textValue == "Y")
  }

  @Test func `makeYOrN false allCaps`() {
    let value = URIVariableValueWrapper.makeYOrN(
      wrapping: false,
      capitalization: .allCaps
    )
    #expect(value.isTextVariableValue)
    #expect(value.textValue == "N")
  }

  @Test func `makeYOrN default capitalization`() {
    let value = URIVariableValueWrapper.makeYOrN(wrapping: true)
    #expect(value.textValue == "Y")
  }

  // MARK: - Boolean Constructors - True/False

  @Test func `makeTrueOrFalse true lowercase`() {
    let value = URIVariableValueWrapper.makeTrueOrFalse(
      wrapping: true,
      capitalization: .lowercase
    )
    #expect(value.isTextVariableValue)
    #expect(value.textValue == "true")
  }

  @Test func `makeTrueOrFalse false lowercase`() {
    let value = URIVariableValueWrapper.makeTrueOrFalse(
      wrapping: false,
      capitalization: .lowercase
    )
    #expect(value.isTextVariableValue)
    #expect(value.textValue == "false")
  }

  @Test func `makeTrueOrFalse true capitalized`() {
    let value = URIVariableValueWrapper.makeTrueOrFalse(
      wrapping: true,
      capitalization: .capitalized
    )
    #expect(value.isTextVariableValue)
    #expect(value.textValue == "True")
  }

  @Test func `makeTrueOrFalse false capitalized`() {
    let value = URIVariableValueWrapper.makeTrueOrFalse(
      wrapping: false,
      capitalization: .capitalized
    )
    #expect(value.isTextVariableValue)
    #expect(value.textValue == "False")
  }

  @Test func `makeTrueOrFalse true allCaps`() {
    let value = URIVariableValueWrapper.makeTrueOrFalse(
      wrapping: true,
      capitalization: .allCaps
    )
    #expect(value.isTextVariableValue)
    #expect(value.textValue == "TRUE")
  }

  @Test func `makeTrueOrFalse false allCaps`() {
    let value = URIVariableValueWrapper.makeTrueOrFalse(
      wrapping: false,
      capitalization: .allCaps
    )
    #expect(value.isTextVariableValue)
    #expect(value.textValue == "FALSE")
  }

  @Test func `makeTrueOrFalse default capitalization`() {
    let value = URIVariableValueWrapper.makeTrueOrFalse(wrapping: true)
    #expect(value.textValue == "true")
  }

  // MARK: - Boolean Constructors - Zero/One

  @Test func `zeroOrOne true`() {
    let value = URIVariableValueWrapper.zeroOrOne(wrapping: true)
    #expect(value.isTextVariableValue)
    #expect(value.textValue == "1")
  }

  @Test func `zeroOrOne false`() {
    let value = URIVariableValueWrapper.zeroOrOne(wrapping: false)
    #expect(value.isTextVariableValue)
    #expect(value.textValue == "0")
  }

}

// MARK: - Introspection Tests

@Suite(.tags(.uriVariableValueWrapper))
struct URIVariableValueWrapperIntrospectionTests {

  // MARK: - Type Checking

  @Test func `undefined type checking`() {
    let value = URIVariableValueWrapper.undefined
    #expect(value.isUndefinedVariableValue)
    #expect(!value.isDefinedVariableValue)
    #expect(!value.isTextVariableValue)
    #expect(!value.isListVariableValue)
    #expect(!value.isAssociationVariableValue)
    #expect(value.variableValueType == .undefined)
  }

  @Test func `text type checking`() {
    let value = URIVariableValueWrapper(string: "test")
    #expect(!value.isUndefinedVariableValue)
    #expect(value.isDefinedVariableValue)
    #expect(value.isTextVariableValue)
    #expect(!value.isListVariableValue)
    #expect(!value.isAssociationVariableValue)
    #expect(value.variableValueType == .text)
  }

  @Test func `list type checking`() {
    let value = URIVariableValueWrapper(strings: ["a"])
    #expect(!value.isUndefinedVariableValue)
    #expect(value.isDefinedVariableValue)
    #expect(!value.isTextVariableValue)
    #expect(value.isListVariableValue)
    #expect(!value.isAssociationVariableValue)
    #expect(value.variableValueType == .list)
  }

  @Test func `association type checking`() {
    let value = URIVariableValueWrapper(key: "k", value: "v")
    #expect(!value.isUndefinedVariableValue)
    #expect(value.isDefinedVariableValue)
    #expect(!value.isTextVariableValue)
    #expect(!value.isListVariableValue)
    #expect(value.isAssociationVariableValue)
    #expect(value.variableValueType == .association)
  }

  // MARK: - Text Value Extraction

  @Test func `textValue returns string`() {
    let value = URIVariableValueWrapper(string: "hello")
    #expect(value.textValue == "hello")
  }

  @Test func `textValue nil for undefined`() {
    #expect(URIVariableValueWrapper.undefined.textValue == nil)
  }

  @Test func `textValue nil for list`() {
    let value = URIVariableValueWrapper(strings: ["a"])
    #expect(value.textValue == nil)
  }

  @Test func `textValue nil for association`() {
    let value = URIVariableValueWrapper(key: "k", value: "v")
    #expect(value.textValue == nil)
  }

  // MARK: - List Value Extraction

  @Test func `listValue returns array`() {
    let value = URIVariableValueWrapper(strings: ["x", "y", "z"])
    #expect(value.listValue == ["x", "y", "z"])
  }

  @Test func `listValue empty array`() {
    let value = URIVariableValueWrapper(strings: [])
    #expect(value.listValue == [])
  }

  @Test func `listValue nil for undefined`() {
    #expect(URIVariableValueWrapper.undefined.listValue == nil)
  }

  @Test func `listValue nil for text`() {
    let value = URIVariableValueWrapper(string: "text")
    #expect(value.listValue == nil)
  }

  @Test func `listValue nil for association`() {
    let value = URIVariableValueWrapper(key: "k", value: "v")
    #expect(value.listValue == nil)
  }

  // MARK: - Association Value Extraction

  @Test func `associationValueAsDictionary returns dictionary`() {
    let value = URIVariableValueWrapper(
      keys: ["a", "b"],
      values: ["1", "2"]
    )
    let dict = value.associationValueAsDictionary
    #expect(dict?["a"] == "1")
    #expect(dict?["b"] == "2")
  }

  @Test func `associationValueAsDictionary empty dictionary`() {
    let value = URIVariableValueWrapper.emptyAssociation
    #expect(value.associationValueAsDictionary == [:])
  }

  @Test func `associationValueAsDictionary nil for undefined`() {
    #expect(URIVariableValueWrapper.undefined.associationValueAsDictionary == nil)
  }

  @Test func `associationValueAsDictionary nil for text`() {
    let value = URIVariableValueWrapper(string: "text")
    #expect(value.associationValueAsDictionary == nil)
  }

  @Test func `associationValueAsDictionary nil for list`() {
    let value = URIVariableValueWrapper(strings: ["a"])
    #expect(value.associationValueAsDictionary == nil)
  }

}

// MARK: - Enumeration Tests

@Suite(.tags(.uriVariableValueWrapper))
struct URIVariableValueWrapperEnumerationTests {

  @Test func `enumerateListValues all elements`() {
    let value = URIVariableValueWrapper(strings: ["a", "b", "c"])
    var collected: [(String, Int)] = []

    let result = value.enumerateAssociation { element, index, stop in
      collected.append((element, index))
    }

    #expect(result == true)
    #expect(collected.count == 3)
    #expect(collected[0] == ("a", 0))
    #expect(collected[1] == ("b", 1))
    #expect(collected[2] == ("c", 2))
  }

  @Test func `enumerateListValues early stop`() {
    let value = URIVariableValueWrapper(strings: ["a", "b", "c", "d"])
    var collected: [String] = []

    let result = value.enumerateAssociation { element, index, stop in
      collected.append(element)
      if index == 1 {
        stop.pointee = true
      }
    }

    #expect(result == true)
    #expect(collected == ["a", "b"])
  }

  @Test func `enumerateListValues empty list`() {
    let value = URIVariableValueWrapper(strings: [])
    var called = false

    let result = value.enumerateAssociation { _, _, _ in
      called = true
    }

    #expect(result == true)
    #expect(!called)
  }

  @Test func `enumerateListValues wrong type`() {
    let value = URIVariableValueWrapper(string: "text")
    var called = false

    let result = value.enumerateAssociation { _, _, _ in
      called = true
    }

    #expect(result == false)
    #expect(!called)
  }

  @Test func `enumerateAssociationPairs all pairs`() {
    let value = URIVariableValueWrapper(
      keys: ["x", "y", "z"],
      values: ["1", "2", "3"]
    )
    var collected: [(String, String, Int)] = []

    let result = value.enumerateAssociation { key, val, index, stop in
      collected.append((key, val, index))
    }

    #expect(result == true)
    #expect(collected.count == 3)
    #expect(collected[0] == ("x", "1", 0))
    #expect(collected[1] == ("y", "2", 1))
    #expect(collected[2] == ("z", "3", 2))
  }

  @Test func `enumerateAssociationPairs early stop`() {
    let value = URIVariableValueWrapper(
      keys: ["a", "b", "c"],
      values: ["1", "2", "3"]
    )
    var collected: [String] = []

    let result = value.enumerateAssociation { key, val, index, stop in
      collected.append(key)
      if index == 0 {
        stop.pointee = true
      }
    }

    #expect(result == true)
    #expect(collected == ["a"])
  }

  @Test func `enumerateAssociationPairs empty association`() {
    let value = URIVariableValueWrapper.emptyAssociation
    var called = false

    let result = value.enumerateAssociation { (_: String, _: String, _: Int, _: UnsafeMutablePointer<ObjCBool>) in
      called = true
    }

    #expect(result == true)
    #expect(!called)
  }

  @Test func `enumerateAssociationPairs wrong type`() {
    let value = URIVariableValueWrapper(string: "text")
    var called = false

    let result = value.enumerateAssociation { (_: String, _: String, _: Int, _: UnsafeMutablePointer<ObjCBool>) in
      called = true
    }

    #expect(result == false)
    #expect(!called)
  }

}

// MARK: - NSObject Protocol Tests

@Suite(.tags(.uriVariableValueWrapper))
struct URIVariableValueWrapperNSObjectTests {

  @Test func `equality same instance`() {
    let value = URIVariableValueWrapper(string: "test")
    #expect(value.isEqual(value))
  }

  @Test func `equality equal values`() {
    let value1 = URIVariableValueWrapper(string: "test")
    let value2 = URIVariableValueWrapper(string: "test")
    #expect(value1.isEqual(value2))
  }

  @Test func `equality different values`() {
    let value1 = URIVariableValueWrapper(string: "test1")
    let value2 = URIVariableValueWrapper(string: "test2")
    #expect(!value1.isEqual(value2))
  }

  @Test func `equality different types`() {
    let value1 = URIVariableValueWrapper(string: "test")
    let value2 = URIVariableValueWrapper(strings: ["test"])
    #expect(!value1.isEqual(value2))
  }

  @Test func `equality non-wrapper object`() {
    let value = URIVariableValueWrapper(string: "test")
    #expect(!value.isEqual("test"))
  }

  @Test func `equality nil`() {
    let value = URIVariableValueWrapper(string: "test")
    #expect(!value.isEqual(nil))
  }

  @Test func `hash consistent`() {
    let value = URIVariableValueWrapper(string: "test")
    let hash1 = value.hash
    let hash2 = value.hash
    #expect(hash1 == hash2)
  }

  @Test func `hash equal values`() {
    let value1 = URIVariableValueWrapper(string: "test")
    let value2 = URIVariableValueWrapper(string: "test")
    #expect(value1.hash == value2.hash)
  }

  @Test func `description contains value`() {
    let value = URIVariableValueWrapper(string: "test")
    let desc = value.description
    #expect(desc.contains("HDXLURIVariableValue"))
    #expect(desc.contains("variableValue"))
  }

  @Test func `debugDescription contains address`() {
    let value = URIVariableValueWrapper(string: "test")
    let desc = value.debugDescription
    #expect(desc.contains("HDXLURIVariableValue"))
    #expect(desc.contains("variableValue"))
  }

}

// MARK: - NSCopying Tests

@Suite(.tags(.uriVariableValueWrapper))
struct URIVariableValueWrapperNSCopyingTests {

  @Test func `copy returns self`() {
    let value = URIVariableValueWrapper(string: "test")
    let copied = value.copy() as! URIVariableValueWrapper
    #expect(value === copied)
  }

  @Test func `copy with zone`() {
    let value = URIVariableValueWrapper(string: "test")
    let copied = value.copy(with: nil) as! URIVariableValueWrapper
    #expect(value === copied)
  }

}

// MARK: - NSCoding Tests

@Suite(.tags(.uriVariableValueWrapper))
struct URIVariableValueWrapperNSCodingTests {

  @Test func `supportsSecureCoding true`() {
    #expect(URIVariableValueWrapper.supportsSecureCoding)
  }

  @Test func `roundtrip text value`() throws {
    let original = URIVariableValueWrapper(string: "hello")
    let data = try NSKeyedArchiver.archivedData(
      withRootObject: original,
      requiringSecureCoding: true
    )
    let decoded = try NSKeyedUnarchiver.unarchivedObject(
      ofClass: URIVariableValueWrapper.self,
      from: data
    )
    #expect(decoded != nil)
    #expect(decoded?.textValue == "hello")
  }

  @Test func `roundtrip list value`() throws {
    let original = URIVariableValueWrapper(strings: ["a", "b", "c"])
    let data = try NSKeyedArchiver.archivedData(
      withRootObject: original,
      requiringSecureCoding: true
    )
    let decoded = try NSKeyedUnarchiver.unarchivedObject(
      ofClass: URIVariableValueWrapper.self,
      from: data
    )
    #expect(decoded != nil)
    #expect(decoded?.listValue == ["a", "b", "c"])
  }

  @Test func `roundtrip association value`() throws {
    let original = URIVariableValueWrapper(
      keys: ["x", "y"],
      values: ["1", "2"]
    )
    let data = try NSKeyedArchiver.archivedData(
      withRootObject: original,
      requiringSecureCoding: true
    )
    let decoded = try NSKeyedUnarchiver.unarchivedObject(
      ofClass: URIVariableValueWrapper.self,
      from: data
    )
    #expect(decoded != nil)
    let dict = decoded?.associationValueAsDictionary
    #expect(dict?["x"] == "1")
    #expect(dict?["y"] == "2")
  }

  @Test func `roundtrip undefined value`() throws {
    let original = URIVariableValueWrapper.undefined
    let data = try NSKeyedArchiver.archivedData(
      withRootObject: original,
      requiringSecureCoding: true
    )
    let decoded = try NSKeyedUnarchiver.unarchivedObject(
      ofClass: URIVariableValueWrapper.self,
      from: data
    )
    #expect(decoded != nil)
    #expect(decoded?.isUndefinedVariableValue == true)
  }

  @Test func `roundtrip integer value`() throws {
    let original = URIVariableValueWrapper.make(wrapping: 42)
    let data = try NSKeyedArchiver.archivedData(
      withRootObject: original,
      requiringSecureCoding: true
    )
    let decoded = try NSKeyedUnarchiver.unarchivedObject(
      ofClass: URIVariableValueWrapper.self,
      from: data
    )
    #expect(decoded != nil)
    #expect(decoded?.textValue == "42")
  }

}

