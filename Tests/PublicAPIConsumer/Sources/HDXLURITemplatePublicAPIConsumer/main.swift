import Foundation
import HDXLURITemplate

@main
struct PublicAPIConsumer {
  static func main() async throws {
    try readmeQuickStart()
    try readmeVariableValues()
    try publicPrefixExample()
    try publicErrorExamples()
    try publicCodableExamples()
    try await publicConcurrencyExample()

    let template = try URITemplate(
      parsing: "https://example.com{/id}"
    )
    let equivalentTemplate = try URITemplate(
      parsing: "https://example.com{/id}"
    )
    let templates: Set<URITemplate> = [
      template,
      equivalentTemplate,
    ]
    let templatesByName: [URITemplate: String] = [
      template: "example.com"
    ]

    precondition(template == equivalentTemplate)
    precondition(templates.count == 1)
    precondition(templatesByName[template] == "example.com")
    requireSendable(template)

    let value = URIVariableValue.text("value")
    let equivalentValue = URIVariableValue.text("value")
    let values: Set<URIVariableValue> = [
      value,
      equivalentValue,
    ]
    let valuesByName: [URIVariableValue: String] = [
      value: "text"
    ]

    precondition(value == equivalentValue)
    precondition(values.count == 1)
    precondition(valuesByName[value] == "text")
    requireSendable(value)

    let associationRawValue: UInt8 =
      URIVariableValueType.association.rawValue
    precondition(associationRawValue == 8)
    precondition(
      URIVariableValueType(rawValue: associationRawValue)
        == .association
    )
    requireSendable(URIVariableValueType.association)
  }
}

private func requireSendable<T: Sendable>(_ value: T) {
  _ = value
}
