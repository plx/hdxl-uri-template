import Foundation
import Testing
@testable import HDXLURITemplate

extension Tag {
  @Tag
  static var doubleCoverageObjC: Self
}

private final class NonKeyedCoder: NSCoder { }

@Test(
  "Manual ObjC template wrapper coverage",
  .tags(.doubleCoverageObjC)
)
private func manualObjCTemplateWrapperCoverage() throws {
  // ObjC callers only see the wrapper, so this checks identity, value equality, copying, properties, and secure archiving through the NSObject surface.
  let wrapper = try #require(URITemplateWrapper(templateString: "https://example.com{/id}{?q}"))
  let sameTemplate = try #require(URITemplateWrapper(templateString: "https://example.com{/id}{?q}"))
  let differentTemplate = try #require(URITemplateWrapper(templateString: "https://example.com/{id}"))

  #expect(wrapper.isEqual(wrapper))
  #expect(wrapper.isEqual(sameTemplate))
  #expect(!wrapper.isEqual(differentTemplate))
  #expect(!wrapper.isEqual("not a template"))
  #expect(wrapper.hash == sameTemplate.hash)
  #expect(wrapper.description.contains("HDXLURITemplate"))
  #expect(wrapper.debugDescription.contains("HDXLURITemplate<"))
  #expect(wrapper.templateRepresentation == "https://example.com{/id}{?q}")
  #expect(wrapper.templateVariableNames == ["id", "q"])
  #expect(wrapper.copy() as AnyObject === wrapper)
  #expect(URITemplateWrapper.supportsSecureCoding)
  #expect(URITemplateWrapper(templateString: "{") == nil)

  let archived = try NSKeyedArchiver.archivedData(
    withRootObject: wrapper,
    requiringSecureCoding: true
  )
  let unarchivedTemplate = try NSKeyedUnarchiver.unarchivedObject(
    ofClass: URITemplateWrapper.self,
    from: archived
  )
  let unarchived = try #require(unarchivedTemplate)
  #expect(unarchived.isEqual(wrapper))

  #expect(URITemplateWrapper(coder: NonKeyedCoder()) == nil)
  wrapper.encode(with: NonKeyedCoder())
}

@Test(
  "Property ObjC template wrapper coverage",
  .tags(.doubleCoverageObjC)
)
private func propertyObjCTemplateWrapperCoverage() throws {
  let templateStrings = [
    "https://example.com/{a}",
    "https://example.com{/a,b}",
    "https://example.com{?a,b,c}"
  ]

  for templateString in templateStrings {
    let wrapper = try #require(URITemplateWrapper(templateString: templateString))
    let native = try URITemplate(parsing: templateString)
    #expect(wrapper.templateRepresentation == native.templateRepresentation)
    #expect(wrapper.templateVariableNames == native.variableNames)
    #expect(wrapper.isEqual(URITemplateWrapper(template: native)))
  }
}

@Test(
  "Manual ObjC variable value wrapper coverage",
  .tags(.doubleCoverageObjC)
)
private func manualObjCVariableValueWrapperCoverage() throws {
  // The wrapper exposes each native value flavor differently, so these examples cover scalar, list, association, singleton, and nil-like values.
  let text = URIVariableValueWrapper(string: "hello")
  let list = URIVariableValueWrapper(strings: ["a", "b"])
  let pair = URIVariableValueWrapper(key: "k", value: "v")
  let pairs = URIVariableValueWrapper(keys: ["b", "a"], values: ["2", "1"])
  let dictionary = URIVariableValueWrapper(
    dictionary: ["b": "2", "a": "1"],
    comparator: { lhs, rhs in lhs < rhs ? .orderedAscending : (lhs == rhs ? .orderedSame : .orderedDescending) }
  )
  let undefined = URIVariableValueWrapper.undefined

  #expect(text.variableValueType == .text)
  #expect(text.isDefinedVariableValue)
  #expect(!text.isUndefinedVariableValue)
  #expect(text.isTextVariableValue)
  #expect(!text.isListVariableValue)
  #expect(!text.isAssociationVariableValue)
  #expect(text.textValue == "hello")
  #expect(text.listValue == nil)
  #expect(text.associationValueAsDictionary == nil)

  #expect(list.variableValueType == .list)
  #expect(list.textValue == nil)
  #expect(list.listValue == ["a", "b"])

  #expect(pair.variableValueType == .association)
  #expect(pair.associationValueAsDictionary == ["k": "v"])
  #expect(pairs.associationValueAsDictionary == ["a": "1", "b": "2"])
  #expect(dictionary.associationValueAsDictionary == ["a": "1", "b": "2"])

  var enumerated: [(String, String, Int)] = []
  pairs.enumerateAssociation { key, value, index, _ in
    enumerated.append((key, value, index))
  }
  #expect(enumerated.map(\.0) == ["b", "a"])
  #expect(enumerated.map(\.1) == ["2", "1"])
  #expect(enumerated.map(\.2) == [0, 1])

  var stopped: [(String, String)] = []
  pairs.enumerateAssociation { key, value, _, stop in
    stopped.append((key, value))
    stop.pointee = true
  }
  #expect(stopped.count == 1)
  text.enumerateAssociation { _, _, _, _ in
    Issue.record("Text values should not enumerate association pairs.")
  }

  #expect(undefined.variableValueType == .undefined)
  #expect(!undefined.isDefinedVariableValue)
  #expect(undefined.isUndefinedVariableValue)
  #expect(!undefined.isTextVariableValue)
  #expect(undefined.textValue == nil)
  #expect(URIVariableValueWrapper.emptyString.textValue == "")
  #expect(URIVariableValueWrapper.emptyList.listValue == [])
  #expect(URIVariableValueWrapper.emptyAssociation.associationValueAsDictionary == [:])

  #expect(text.isEqual(text))
  #expect(text.isEqual(URIVariableValueWrapper(string: "hello")))
  #expect(!text.isEqual(list))
  #expect(!text.isEqual("not a value"))
  #expect(text.hash == URIVariableValueWrapper(string: "hello").hash)
  #expect(text.description.contains("HDXLURIVariableValue"))
  #expect(text.debugDescription.contains("HDXLURIVariableValue<"))
  #expect(text.copy() as AnyObject === text)
  #expect(URIVariableValueWrapper.supportsSecureCoding)

  let archived = try NSKeyedArchiver.archivedData(
    withRootObject: pairs,
    requiringSecureCoding: true
  )
  let unarchivedValue = try NSKeyedUnarchiver.unarchivedObject(
    ofClass: URIVariableValueWrapper.self,
    from: archived
  )
  let unarchived = try #require(unarchivedValue)
  #expect(unarchived.isEqual(pairs))

  #expect(URIVariableValueWrapper(coder: NonKeyedCoder()) == nil)
  text.encode(with: NonKeyedCoder())
}

@Test(
  "Property ObjC variable value wrapper coverage",
  .tags(.doubleCoverageObjC)
)
private func propertyObjCVariableValueWrapperCoverage() {
  let values: [URIVariableValue] = [
    .undefined,
    .emptyString,
    .emptyList,
    .emptyAssociation,
    .text("text"),
    .list(["a", "b", "c"]),
    .association([("a", "1"), ("b", "2")])
  ]

  for value in values {
    let wrapper = URIVariableValueWrapper(variableValue: value)
    #expect(wrapper.variableValueType == value.valueType)
    #expect(wrapper.isDefinedVariableValue == value.isDefined)
    #expect(wrapper.isUndefinedVariableValue == value.isUndefined)
    #expect(wrapper.isTextVariableValue == value.isTextValue)
    #expect(wrapper.isListVariableValue == value.isListValue)
    #expect(wrapper.isAssociationVariableValue == value.isAssociationValue)
    #expect(wrapper.isEqual(URIVariableValueWrapper(variableValue: value)))
  }
}
