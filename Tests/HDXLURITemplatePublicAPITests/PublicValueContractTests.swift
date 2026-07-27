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

private func requireSendable<T: Sendable>(_ value: T) {
  _ = value
}
