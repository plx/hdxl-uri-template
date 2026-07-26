import Foundation
import HDXLURITemplate
import Testing

@Test(
  "Public arrays and dictionaries round trip through JSON and property lists"
)
private func publicCollectionsRoundTripThroughSupportedCoders() throws {
  let sources = ["", "literal", "cafe\u{301}/%2f{?name%2F,x:2,list*}", "{+path}/here"]
  let templates = try sources.map(URITemplate.init(parsing:))
  let names = ["empty", "literal", "query", "reserved"]
  let templatesByName = Dictionary(
    uniqueKeysWithValues: zip(names, templates)
  )
  let sourcesByName = Dictionary(
    uniqueKeysWithValues: zip(names, sources)
  )

  try verifyJSONCollections(
    sources: sources,
    templates: templates,
    sourcesByName: sourcesByName,
    templatesByName: templatesByName
  )
  for outputFormat in publicContractPropertyListFormats {
    try verifyPropertyListCollections(
      outputFormat: outputFormat,
      sources: sources,
      templates: templates,
      sourcesByName: sourcesByName,
      templatesByName: templatesByName
    )
  }
}

private func verifyJSONCollections(
  sources: [String],
  templates: [URITemplate],
  sourcesByName: [String: String],
  templatesByName: [String: URITemplate]
) throws {
  let arrayJSON = try JSONEncoder().encode(templates)
  let arrayJSONObject = try JSONSerialization.jsonObject(
    with: arrayJSON
  )
  let arrayJSONStrings = try #require(
    arrayJSONObject as? [String]
  )
  verifyExactSources(arrayJSONStrings, sources)
  let decodedJSONArray = try JSONDecoder().decode(
    [URITemplate].self,
    from: arrayJSON
  )
  try verifyEquivalentTemplates(templates, decodedJSONArray)

  let dictionaryJSON = try JSONEncoder().encode(templatesByName)
  let dictionaryJSONObject = try JSONSerialization.jsonObject(
    with: dictionaryJSON
  )
  let dictionaryJSONStrings = try #require(
    dictionaryJSONObject as? [String: String]
  )
  #expect(dictionaryJSONStrings == sourcesByName)
  let decodedJSONDictionary = try JSONDecoder().decode(
    [String: URITemplate].self,
    from: dictionaryJSON
  )
  try verifyEquivalentTemplateDictionaries(
    templatesByName,
    decodedJSONDictionary
  )
}

private func verifyPropertyListCollections(
  outputFormat: PropertyListSerialization.PropertyListFormat,
  sources: [String],
  templates: [URITemplate],
  sourcesByName: [String: String],
  templatesByName: [String: URITemplate]
) throws {
  let encoder = PropertyListEncoder()
  encoder.outputFormat = outputFormat
  try verifyPropertyListArray(
    encoder: encoder,
    sources: sources,
    templates: templates
  )
  try verifyPropertyListDictionary(
    encoder: encoder,
    sourcesByName: sourcesByName,
    templatesByName: templatesByName
  )
}

private func verifyPropertyListArray(
  encoder: PropertyListEncoder,
  sources: [String],
  templates: [URITemplate]
) throws {
  let propertyList = try encoder.encode(templates)
  let propertyListObject =
    try PropertyListSerialization.propertyList(
      from: propertyList,
      options: [],
      format: nil
    )
  let propertyListStrings = try #require(
    propertyListObject as? [String]
  )
  verifyExactSources(propertyListStrings, sources)
  let decoded = try PropertyListDecoder().decode(
    [URITemplate].self,
    from: propertyList
  )
  try verifyEquivalentTemplates(templates, decoded)
}

private func verifyPropertyListDictionary(
  encoder: PropertyListEncoder,
  sourcesByName: [String: String],
  templatesByName: [String: URITemplate]
) throws {
  let propertyList = try encoder.encode(templatesByName)
  let propertyListObject =
    try PropertyListSerialization.propertyList(
      from: propertyList,
      options: [],
      format: nil
    )
  let propertyListStrings = try #require(
    propertyListObject as? [String: String]
  )
  #expect(propertyListStrings == sourcesByName)
  let decoded = try PropertyListDecoder().decode(
    [String: URITemplate].self,
    from: propertyList
  )
  try verifyEquivalentTemplateDictionaries(
    templatesByName,
    decoded
  )
}

private func verifyExactSources(
  _ observed: [String],
  _ expected: [String]
) {
  #expect(observed.count == expected.count)
  #expect(
    zip(observed, expected).allSatisfy {
      $0.utf8.elementsEqual($1.utf8)
    }
  )
}

private func verifyEquivalentTemplateDictionaries(
  _ originals: [String: URITemplate],
  _ decoded: [String: URITemplate]
) throws {
  #expect(originals.keys == decoded.keys)
  for key in originals.keys {
    let original = try #require(originals[key])
    let decodedTemplate = try #require(decoded[key])
    try verifyEquivalentTemplates(
      [original],
      [decodedTemplate]
    )
  }
}

private func verifyEquivalentTemplates(
  _ originals: [URITemplate],
  _ decoded: [URITemplate]
) throws {
  #expect(originals.count == decoded.count)
  for (original, decodedTemplate) in zip(originals, decoded) {
    try verifyEquivalentTemplate(
      original,
      decodedTemplate
    )
  }
}

private func verifyEquivalentTemplate(
  _ original: URITemplate,
  _ decoded: URITemplate
) throws {
  #expect(decoded == original)
  #expect(
    decoded.templateRepresentation.utf8.elementsEqual(
      original.templateRepresentation.utf8
    )
  )
  #expect(decoded.variableNames == original.variableNames)

  let originalExpansion = try original.evaluateAsString(
    parameters: publicContractParameters
  )
  let decodedExpansion = try decoded.evaluateAsString(
    parameters: publicContractParameters
  )
  #expect(decodedExpansion == originalExpansion)

  let reparsed = try URITemplate(
    parsing: decoded.templateRepresentation
  )
  #expect(reparsed == decoded)
  #expect(
    reparsed.templateRepresentation.utf8.elementsEqual(
      decoded.templateRepresentation.utf8
    )
  )
}

private typealias PropertyListFormat = PropertyListSerialization.PropertyListFormat

private let publicContractPropertyListFormats: [PropertyListFormat] = [.xml, .binary]

private let publicContractParameters: [String: URIVariableValue] = {
  var parameters: [String: URIVariableValue] = [:]
  parameters["name%2F"] = .text("encoded")
  parameters["x"] = .text("abcdef")
  parameters["list"] = .list(["one", "two"])
  parameters["path"] = .text("a/b")
  return parameters
}()
