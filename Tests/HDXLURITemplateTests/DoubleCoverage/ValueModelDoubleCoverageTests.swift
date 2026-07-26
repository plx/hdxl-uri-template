import Foundation
import Testing
@testable import HDXLURITemplate

extension Tag {
  @Tag
  static var doubleCoverageValueModel: Self
}

@Test(
  "Manual variable value model coverage",
  .tags(.doubleCoverageValueModel)
)
private func manualVariableValueModelCoverage() throws {
  // These hand-picked values cover every value flavor and every public constructor, including singleton list and singleton association convenience paths.
  let text = URIVariableTextValue(rawValue: "hello")
  let emptyText: URIVariableTextValue = ""
  let scalarLiteral = URIVariableTextValue(unicodeScalarLiteral: "s")
  let graphemeLiteral = URIVariableTextValue(extendedGraphemeClusterLiteral: "e")
  let list = URIVariableListValue(values: [text, emptyText])
  let listLiteral: URIVariableListValue = ["a", "b"]
  let singletonList = URIVariableListValue(string: "solo")
  let pair = URIVariablePairValue(key: "key", value: "value")
  let association = try URIVariableAssociationValue(validating: [pair])
  let associationLiteral = try URIVariableAssociationValue(
    validating: [
      URIVariablePairValue(key: "a", value: "1"),
      URIVariablePairValue(key: "b", value: "2")
    ]
  )
  let singletonAssociation = URIVariableAssociationValue(key: "single", value: "1")

  #expect(text.rawValue == "hello")
  #expect(scalarLiteral.rawValue == "s")
  #expect(graphemeLiteral.rawValue == "e")
  #expect(text.description == "hello")
  #expect(text.debugDescription.contains("URIVariableTextValue"))
  #expect(text.isValid)
  #expect(!text.isEmpty)
  #expect(emptyText.isEmpty)
  #expect(text.errorMessageRepresentation == "hello")
  #expect(try JSONDecoder().decode(URIVariableTextValue.self, from: JSONEncoder().encode(text)) == text)

  #expect(list.storage == [text, emptyText])
  #expect(listLiteral.storage.map(\.rawValue) == ["a", "b"])
  #expect(singletonList.storage == ["solo"])
  #expect(URIVariableListValue(value: text).storage == [text])
  #expect(URIVariableListValue(strings: ["a", "b"]).storage == ["a", "b"])
  #expect(list.count == 2)
  #expect(list[0] == text)
  #expect(!list.isEmpty)
  #expect(list.description == "[ \"hello\", \"\" ]")
  #expect(list.debugDescription.contains("URIVariableListValue"))
  #expect(list.errorMessageRepresentation == "[ hello,  ]")
  #expect(try JSONDecoder().decode(URIVariableListValue.self, from: JSONEncoder().encode(list)) == list)

  #expect(pair.key == "key")
  #expect(pair.value == "value")
  #expect(pair.description == "\"key\":\"value\"")
  #expect(pair.debugDescription.contains("URIVariablePairValue"))
  #expect(pair.errorMessageRepresentation == "key: value")

  #expect(association.storage == [pair])
  #expect(associationLiteral.storage.map(\.key.rawValue) == ["a", "b"])
  #expect(associationLiteral.storage.map(\.value.rawValue) == ["1", "2"])
  #expect(singletonAssociation.storage == [["single", "1"]])
  #expect(
    try URIVariableAssociationValue(
      validatingStrings: [("a", "1"), ("b", "2")]
    ).count == 2
  )
  #expect(association[0] == pair)
  #expect(association["key"] == "value")
  #expect(association[URIVariableTextValue(rawValue: "missing")] == nil)
  #expect(association.allKeysAreDistinct)
  #expect(association.isValid)
  #expect(association.description == "[ \"key\":\"value\" ]")
  #expect(association.debugDescription.contains("URIVariableAssociationValue"))
  #expect(association.errorMessageRepresentation == "[ key: value ]")
  #expect(!URITemplateVariableName(rawValue: "").isValid)
  #expect(!(URIVariableValueData.undefined < .undefined))

  let values: [URIVariableValue] = try [
    .undefined,
    .emptyString,
    .emptyList,
    .emptyAssociation,
    .text("hello"),
    .list("solo"),
    .list(["a", "b"]),
    .association(key: "k", value: "v"),
    .association([("a", "1"), ("b", "2")])
  ]

  #expect(values[0].isUndefined)
  #expect(values[1].isTextValue)
  #expect(values[2].isListValue)
  #expect(values[3].isAssociationValue)
  #expect(values[4].description.contains("hello"))
  #expect(values[4].debugDescription.contains("URIVariableValue"))
  #expect(values[5].count == 1)
  #expect(values[6].count == 2)
  #expect(values[8].valueType == .association)
  #expect(values.sorted().first == .undefined)

  for value in values {
    let roundTrip = try JSONDecoder().decode(URIVariableValue.self, from: JSONEncoder().encode(value))
    #expect(roundTrip == value)
    #expect(value.isValid)
  }
}

@Test(
  "Property variable value model coverage",
  .tags(.doubleCoverageValueModel)
)
private func propertyVariableValueModelCoverage() throws {
  let strings = ["", "a", "b", "space value", "symbols:/?#"]
  let textValues = strings.map(URIVariableTextValue.init(rawValue:))
  let lists = strings.indices.map { index in
    URIVariableListValue(values: Array(textValues.prefix(index + 1)))
  }
  let pairs = zip(strings, strings.reversed()).map {
    URIVariablePairValue(
      key: URIVariableTextValue(rawValue: $0),
      value: URIVariableTextValue(rawValue: $1)
    )
  }
  let associations = try pairs.indices.map { index in
    try URIVariableAssociationValue(
      validating: pairs.prefix(index + 1)
    )
  }

  for text in textValues {
    #expect(text.isEmpty == text.rawValue.isEmpty)
    #expect(text.errorMessageRepresentation == text.rawValue)
    #expect(try JSONDecoder().decode(URIVariableTextValue.self, from: JSONEncoder().encode(text)) == text)
  }

  for list in lists {
    #expect(list.count == list.storage.count)
    #expect(list.isEmpty == list.storage.isEmpty)
    #expect(list.isValid == list.storage.allSatisfy(\.isValid))
    #expect(try JSONDecoder().decode(URIVariableListValue.self, from: JSONEncoder().encode(list)) == list)
  }

  for pair in pairs {
    #expect(pair.isValid == (pair.key.isValid && pair.value.isValid))
    #expect(pair.errorMessageRepresentation == "\(pair.key.rawValue): \(pair.value.rawValue)")
  }

  for association in associations {
    #expect(association.count == association.storage.count)
    #expect(association.isEmpty == association.storage.isEmpty)
    #expect(association.isValid == association.allKeysAreDistinct)
    for pair in association.storage {
      #expect(association[pair.key.rawValue] == pair.value)
    }
  }

  let dataValues: [URIVariableValueData] =
    [.undefined]
    + textValues.map { .text($0) }
    + lists.map { .list($0) }
    + associations.map { .association($0) }

  for data in dataValues {
    let publicValue = URIVariableValue(storage: data)
    #expect(publicValue.storage == data)
    #expect(publicValue.valueType == data.valueType)
    #expect(publicValue.isEmpty == data.isEmpty)
    #expect(publicValue.count == data.count)
    #expect(publicValue.isDefined == data.isDefined)
    #expect(publicValue.isUndefined == data.isUndefined)
    #expect(publicValue.isUndefinedValue == data.isUndefinedValue)
    #expect(publicValue.isTextValue == data.isTextValue)
    #expect(publicValue.isListValue == data.isListValue)
    #expect(publicValue.isAssociationValue == data.isAssociationValue)
    #expect(publicValue.errorMessageRepresentation == data.errorMessageRepresentation)
    #expect(try JSONDecoder().decode(URIVariableValueData.self, from: JSONEncoder().encode(data)) == data)
    #expect(try JSONDecoder().decode(URIVariableValue.self, from: JSONEncoder().encode(publicValue)) == publicValue)
  }
}

@Test(
  "Manual Codable validation errors coverage",
  .tags(.doubleCoverageValueModel)
)
private func manualCodableValidationErrorCoverage() throws {
  // Decoding validation is the package's repair hook, so these examples use encoded invalid payloads rather than direct parsing errors.
  let tooSmallModifierJSON = #"{"type":4,"data":0}"#.data(using: .utf8)!
  do {
    _ = try JSONDecoder().decode(URIValueExpansionModifier.self, from: tooSmallModifierJSON)
    Issue.record("Expected an out-of-range prefix modifier to throw.")
  } catch let error as DataValidationError<URIValueExpansionModifier> {
    #expect(error.repairSuggestion == .prefix(URIValueExpansionModifier.rangeOfValidPrefixCodePointCounts.lowerBound))
  }

  let tooLargeModifierJSON = #"{"type":4,"data":10000}"#.data(using: .utf8)!
  do {
    _ = try JSONDecoder().decode(URIValueExpansionModifier.self, from: tooLargeModifierJSON)
    Issue.record("Expected an out-of-range prefix modifier to throw.")
  } catch let error as DataValidationError<URIValueExpansionModifier> {
    #expect(error.repairSuggestion == .prefix(URIValueExpansionModifier.rangeOfValidPrefixCodePointCounts.upperBound))
  }

  let invalidVariableNameJSON = #""not valid""#.data(using: .utf8)!
  #expect(throws: DataValidationError<URITemplateVariableName>.self) {
    _ = try JSONDecoder().decode(URITemplateVariableName.self, from: invalidVariableNameJSON)
  }

  let invalidLiteralJSON = #""{bad}""#.data(using: .utf8)!
  #expect(throws: DataValidationError<URITemplateLiteralComponent>.self) {
    _ = try JSONDecoder().decode(URITemplateLiteralComponent.self, from: invalidLiteralJSON)
  }

  let invalidStorageJSON = Data(
    #"[{"literal":{"_0":"{bad}"}}]"#.utf8
  )
  #expect(throws: DataValidationError<URITemplateLiteralComponent>.self) {
    _ = try JSONDecoder().decode(
      URITemplateStorage.self,
      from: invalidStorageJSON
    )
  }

  try verifyDuplicateAssociationDecodeFailure()
}

private func verifyDuplicateAssociationDecodeFailure() throws {
  let duplicateAssociationJSON = Data(
    """
    {
      "type": 8,
      "data": {
        "storage": [
          { "key": "private-key", "value": "private-first-value" },
          { "key": "private-key", "value": "private-second-value" }
        ]
      }
    }
    """.utf8
  )
  do {
    _ = try JSONDecoder().decode(
      URIVariableValue.self,
      from: duplicateAssociationJSON
    )
    Issue.record("Expected duplicate association storage to throw.")
  } catch let error as URIVariableValue.AssociationError {
    #expect(
      error == .duplicateKey(
        firstIndex: 0,
        duplicateIndex: 1
      )
    )
    #expect(!String(reflecting: error).contains("private"))
    #expect(!(error as NSError).userInfo.description.contains("private"))
  }
}

@Test(
  "Property Codable validation errors coverage",
  .tags(.doubleCoverageValueModel)
)
private func propertyCodableValidationErrorCoverage() throws {
  let invalidPrefixCounts = [
    URIValueExpansionModifier.rangeOfValidPrefixCodePointCounts.lowerBound - 1,
    URIValueExpansionModifier.rangeOfValidPrefixCodePointCounts.upperBound + 1
  ]

  for count in invalidPrefixCounts {
    let json = #"{"type":4,"data":\#(count)}"#.data(using: .utf8)!
    #expect(throws: DataValidationError<URIValueExpansionModifier>.self) {
      _ = try JSONDecoder().decode(URIValueExpansionModifier.self, from: json)
    }
  }

  for invalidName in ["", "with space", "bad!", ".leading"] {
    let json = try JSONEncoder().encode(invalidName)
    #expect(throws: DataValidationError<URITemplateVariableName>.self) {
      _ = try JSONDecoder().decode(URITemplateVariableName.self, from: json)
    }
  }

  for invalidLiteral in ["", "{", "}", "has space"] {
    let json = try JSONEncoder().encode(invalidLiteral)
    #expect(throws: DataValidationError<URITemplateLiteralComponent>.self) {
      _ = try JSONDecoder().decode(URITemplateLiteralComponent.self, from: json)
    }
  }
}
