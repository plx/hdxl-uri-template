import Foundation
import HDXLURITemplate
import Testing

@Test("The public Swift association factory rejects duplicate keys")
private func publicAssociationFactoryRejectsDuplicateKeys() {
  do {
    _ = try URIVariableValue.association([
      ("private-key", "private-first"),
      ("private-key", "private-second")
    ])
    Issue.record("Expected duplicate association keys to throw.")
  } catch let error as URIVariableValue.AssociationError {
    #expect(
      error == .duplicateKey(
        firstIndex: 0,
        duplicateIndex: 1
      )
    )
    #expect(!String(reflecting: error).contains("private"))
    #expect(!(error as NSError).userInfo.description.contains("private"))
  } catch {
    Issue.record("Unexpected public association error: \(error)")
  }
}

@Test("The public Swift association APIs preserve valid behavior")
private func publicAssociationAPIsPreserveValidBehavior() throws {
  let orderedValue = try URIVariableValue.association([
    ("b", "2"),
    ("a", "1")
  ])
  let dictionaryValue = URIVariableValue.association([
    "b": "2",
    "a": "1"
  ])
  let tiedDictionaryValue = URIVariableValue.association(
    [
      "b": "2",
      "a": "1"
    ],
    orderingKeysWith: { _, _ in false }
  )
  let template = try URITemplate(parsing: "{?items*}")

  #expect(orderedValue.isAssociationValue)
  #expect(orderedValue.count == 2)
  #expect(dictionaryValue.isAssociationValue)
  #expect(tiedDictionaryValue.isAssociationValue)
  #expect(
    try template.evaluateAsString(
      parameters: ["items": orderedValue]
    ) == "?b=2&a=1"
  )
  #expect(
    try template.evaluateAsString(
      parameters: ["items": dictionaryValue]
    ) == "?a=1&b=2"
  )
  #expect(
    try template.evaluateAsString(
      parameters: ["items": tiedDictionaryValue]
    ) == "?a=1&b=2"
  )

  let data = try JSONEncoder().encode(orderedValue)
  let decoded = try JSONDecoder().decode(
    URIVariableValue.self,
    from: data
  )
  #expect(decoded == orderedValue)
}
