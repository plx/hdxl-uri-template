import Foundation
import HDXLURITemplate
import Testing

@Test("Public value contracts remain available without testable import")
private func publicValueContracts() throws {
  let template = try URITemplate(parsing: "https://example.com{/id}")
  let equivalentTemplate = try URITemplate(
    parsing: "https://example.com{/id}"
  )
  let distinctTemplate = try URITemplate(
    parsing: "https://example.net{/id}"
  )

  #expect(template == equivalentTemplate)
  #expect(
    Set([template, equivalentTemplate, distinctTemplate]).count == 2
  )
  #expect(
    [template: "example.com", distinctTemplate: "example.net"][template]
      == "example.com"
  )
  requireSendable(template)

  let decodedTemplate = try JSONDecoder().decode(
    URITemplate.self,
    from: JSONEncoder().encode(template)
  )
  #expect(decodedTemplate == template)

  let value = URIVariableValue.text("value")
  let equivalentValue = URIVariableValue.text("value")
  let distinctValue = URIVariableValue.list(["value"])

  #expect(value == equivalentValue)
  #expect(Set([value, equivalentValue, distinctValue]).count == 2)
  #expect([value: "text", distinctValue: "list"][value] == "text")
  requireSendable(value)

  let valueTypes = Set(URIVariableValueType.allCases)
  #expect(
    valueTypes == [.undefined, .text, .list, .association]
  )
  let rawValues: Set<UInt8> = Set(valueTypes.map(\.rawValue))
  #expect(rawValues == [1, 2, 4, 8])
  #expect(
    URIVariableValueType(rawValue: UInt8(8)) == .association
  )
  requireSendable(URIVariableValueType.text)
}

@Test("Public payload accessors recover every value flavor without testable import")
private func publicPayloadInspection() throws {
  let values: [URIVariableValue] = [
    .undefined,
    .text(""),
    .list(["first", "second"]),
    try .association([
      ("second", "2"),
      ("first", "1"),
    ]),
  ]

  for value in values {
    switch value.valueType {
    case .undefined:
      #expect(value.textValue == nil)
      #expect(value.listValue == nil)
      #expect(value.associationValue == nil)
    case .text:
      #expect(value.textValue == "")
      #expect(value.listValue == nil)
      #expect(value.associationValue == nil)
    case .list:
      #expect(value.textValue == nil)
      #expect(value.listValue == ["first", "second"])
      #expect(value.associationValue == nil)
    case .association:
      #expect(value.textValue == nil)
      #expect(value.listValue == nil)
      let association = try #require(value.associationValue)
      #expect(association.map(\.key) == ["second", "first"])
      #expect(association.map(\.value) == ["2", "1"])
      #expect(Set(association.map(\.key)).count == association.count)
    }
  }

  #expect(URIVariableValue.emptyString.textValue == "")
  #expect(URIVariableValue.emptyList.listValue == [])
  #expect(URIVariableValue.emptyAssociation.associationValue?.isEmpty == true)

  let list = URIVariableValue.list(["original"])
  var recoveredList = try #require(list.listValue)
  recoveredList.append("local")
  #expect(recoveredList == ["original", "local"])
  #expect(list.listValue == ["original"])

  let association = try URIVariableValue.association([
    ("key", "original")
  ])
  var recoveredAssociation = try #require(association.associationValue)
  recoveredAssociation.append((key: "local", value: "change"))
  #expect(recoveredAssociation.map(\.key) == ["key", "local"])
  #expect(association.associationValue?.map(\.key) == ["key"])

  requireSendable(recoveredList)
  requireSendable(recoveredAssociation)
}

private func requireSendable<T: Sendable>(_ value: T) {
  _ = value
}
