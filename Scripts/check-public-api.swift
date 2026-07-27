#!/usr/bin/env swift
import Foundation

private struct PublicAPIContract: Decodable {
  let module: String
  let forbiddenObjectiveCDeclarations: [String]
  let forbiddenDeclarations: [[String]]
  let declarations: [Declaration]

  struct Declaration: Decodable {
    let path: [String]
    let requiredConformances: [String]
    let forbiddenConformances: [String]
    let forbiddenMembers: [String]
  }
}

private struct SymbolGraph: Decodable {
  let module: Module
  let symbols: [Symbol]
  let relationships: [Relationship]

  struct Module: Decodable {
    let name: String
  }

  struct Symbol: Decodable {
    let identifier: Identifier
    let pathComponents: [String]
    let declarationFragments: [DeclarationFragment]?

    struct Identifier: Decodable {
      let precise: String
    }

    struct DeclarationFragment: Decodable {
      let kind: String
      let preciseIdentifier: String?
    }
  }

  struct Relationship: Decodable {
    let kind: String
    let source: String
    let targetFallback: String?
  }
}

private enum PublicAPICheckError: Error, CustomStringConvertible {
  case commandFailed(command: String, status: Int32)
  case documentationViolations([String])
  case missingObjectiveCHeader(module: String, directory: String)
  case missingSymbolGraph(module: String, directory: String)
  case unexpectedObjectiveCHeaders(module: String, paths: [String])
  case multipleSymbolGraphs(module: String, paths: [String])
  case contractViolations([String])

  var description: String {
    switch self {
    case .commandFailed(let command, let status):
      "Command failed with status \(status): \(command)"
    case .documentationViolations(let violations):
      violations.joined(separator: "\n")
    case .missingObjectiveCHeader(let module, let directory):
      "No canonical \(module)-Swift.h was emitted beneath \(directory)."
    case .missingSymbolGraph(let module, let directory):
      "No \(module).symbols.json was emitted beneath \(directory)."
    case .unexpectedObjectiveCHeaders(let module, let paths):
      "Expected two canonical \(module)-Swift.h headers, found \(paths.count): \(paths.joined(separator: ", "))."
    case .multipleSymbolGraphs(let module, let paths):
      "Found multiple \(module) symbol graphs where exactly one was expected: \(paths.joined(separator: ", "))."
    case .contractViolations(let violations):
      violations.joined(separator: "\n")
    }
  }
}

private func generatedObjectiveCHeaders(
  for module: String,
  beneath directory: URL
) throws -> [URL] {
  let expectedName = "\(module)-Swift.h"
  let resourceKeys: [URLResourceKey] = [.isRegularFileKey]
  guard
    let enumerator = FileManager.default.enumerator(
      at: directory,
      includingPropertiesForKeys: resourceKeys,
      options: [.skipsHiddenFiles]
    )
  else {
    throw PublicAPICheckError.missingObjectiveCHeader(
      module: module,
      directory: directory.path
    )
  }

  var matches: [URL] = []
  for case let candidate as URL in enumerator
  where candidate.lastPathComponent == expectedName {
    let values = try candidate.resourceValues(forKeys: Set(resourceKeys))
    if values.isRegularFile == true {
      matches.append(candidate)
    }
  }

  let canonicalMatches = matches.filter {
    $0.deletingLastPathComponent().lastPathComponent
      == "GeneratedModuleMaps"
  }
  guard !canonicalMatches.isEmpty else {
    throw PublicAPICheckError.missingObjectiveCHeader(
      module: module,
      directory: directory.path
    )
  }
  guard canonicalMatches.count == 2 else {
    throw PublicAPICheckError.unexpectedObjectiveCHeaders(
      module: module,
      paths: canonicalMatches.map(\.path).sorted()
    )
  }
  return canonicalMatches
}

private func runSwift(
  arguments: [String],
  in repositoryRoot: URL,
  discardingStandardOutput: Bool = false
) throws {
  let process = Process()
  process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
  process.arguments = ["swift"] + arguments
  process.currentDirectoryURL = repositoryRoot
  if discardingStandardOutput {
    process.standardOutput = FileHandle.nullDevice
  }
  try process.run()
  process.waitUntilExit()

  guard process.terminationReason == .exit, process.terminationStatus == 0 else {
    throw PublicAPICheckError.commandFailed(
      command: (["swift"] + arguments).joined(separator: " "),
      status: process.terminationStatus
    )
  }
}

private func swiftCodeBlocks(in markdown: String) -> [String] {
  var blocks: [String] = []
  var currentBlock: [Substring]?

  for line in markdown.split(
    separator: "\n",
    omittingEmptySubsequences: false
  ) {
    guard var block = currentBlock else {
      if line == "```swift" {
        currentBlock = []
      }
      continue
    }

    if line == "```" {
      blocks.append(block.joined(separator: "\n"))
      currentBlock = nil
    } else {
      block.append(line)
      currentBlock = block
    }
  }

  return blocks
}

private func validateREADMEExamples(
  at readmeURL: URL,
  consumerSourceDirectory: URL,
  scratchDirectory: URL,
  repositoryRoot: URL
) throws {
  let readme = try String(contentsOf: readmeURL, encoding: .utf8)
  let blocks = swiftCodeBlocks(in: readme)
  var violations: [String] = []

  guard blocks.count == 3 else {
    throw PublicAPICheckError.documentationViolations([
      "Expected exactly three Swift examples in README.md, found \(blocks.count)."
    ])
  }

  let expectedSources = [
    (
      marker: "func readmeQuickStart() throws",
      filename: "READMEQuickStart.swift"
    ),
    (
      marker: "func readmeVariableValues() throws",
      filename: "READMEVariableValues.swift"
    ),
  ]

  for expectedSource in expectedSources {
    let matchingBlocks = blocks.filter {
      $0.contains(expectedSource.marker)
    }
    guard matchingBlocks.count == 1 else {
      violations.append(
        "Expected exactly one README.md example containing "
          + "\(expectedSource.marker), found \(matchingBlocks.count)."
      )
      continue
    }

    let sourceURL =
      consumerSourceDirectory
      .appendingPathComponent(expectedSource.filename)
    let source = try String(contentsOf: sourceURL, encoding: .utf8)
      .trimmingCharacters(in: .newlines)
    if matchingBlocks[0] != source {
      violations.append(
        "README.md example \(expectedSource.marker) must exactly match "
          + sourceURL.path
      )
    }
  }

  let manifestBlocks = blocks.filter {
    $0.contains("let package = Package(")
  }
  guard manifestBlocks.count == 1 else {
    violations.append(
      "Expected exactly one README.md SwiftPM manifest example, found "
        + "\(manifestBlocks.count)."
    )
    throw PublicAPICheckError.documentationViolations(violations)
  }

  guard violations.isEmpty else {
    throw PublicAPICheckError.documentationViolations(violations)
  }

  let manifestDirectory =
    scratchDirectory
    .appendingPathComponent("readme-manifest", isDirectory: true)
  try FileManager.default.createDirectory(
    at: manifestDirectory,
    withIntermediateDirectories: true
  )
  try Data((manifestBlocks[0] + "\n").utf8).write(
    to: manifestDirectory.appendingPathComponent("Package.swift")
  )
  try runSwift(
    arguments: [
      "package",
      "--package-path", manifestDirectory.path,
      "dump-package",
    ],
    in: repositoryRoot,
    discardingStandardOutput: true
  )
}

private func emittedSymbolGraph(
  for module: String,
  beneath directory: URL
) throws -> URL {
  let expectedName = "\(module).symbols.json"
  let resourceKeys: [URLResourceKey] = [.isRegularFileKey]
  guard
    let enumerator = FileManager.default.enumerator(
      at: directory,
      includingPropertiesForKeys: resourceKeys,
      options: [.skipsHiddenFiles]
    )
  else {
    throw PublicAPICheckError.missingSymbolGraph(
      module: module,
      directory: directory.path
    )
  }

  var matches: [URL] = []
  for case let candidate as URL in enumerator
  where candidate.lastPathComponent == expectedName {
    let values = try candidate.resourceValues(forKeys: Set(resourceKeys))
    if values.isRegularFile == true {
      matches.append(candidate)
    }
  }

  let canonicalMatches = matches.filter {
    $0.deletingLastPathComponent().lastPathComponent == "symbolgraph"
  }
  let eligibleMatches =
    canonicalMatches.isEmpty
    ? matches
    : canonicalMatches

  switch eligibleMatches.count {
  case 1:
    return eligibleMatches[0]
  case 0:
    throw PublicAPICheckError.missingSymbolGraph(
      module: module,
      directory: directory.path
    )
  default:
    throw PublicAPICheckError.multipleSymbolGraphs(
      module: module,
      paths: eligibleMatches.map(\.path).sorted()
    )
  }
}

private func validate(
  contract: PublicAPIContract,
  against graph: SymbolGraph,
  objectiveCHeader: String
) throws {
  var violations: [String] = []

  if graph.module.name != contract.module {
    violations.append(
      "Expected module \(contract.module), but the symbol graph describes \(graph.module.name)."
    )
  }

  for forbiddenDeclaration in contract.forbiddenObjectiveCDeclarations
  where objectiveCHeader.contains(forbiddenDeclaration) {
    violations.append(
      "Generated Objective-C header must not expose \(forbiddenDeclaration)."
    )
  }

  for forbiddenPath in contract.forbiddenDeclarations {
    let matches = graph.symbols.filter {
      $0.pathComponents == forbiddenPath
    }
    if !matches.isEmpty {
      violations.append(
        "Public declaration \(forbiddenPath.joined(separator: ".")) must remain absent."
      )
    }
  }

  for declaration in contract.declarations {
    let declarationName = declaration.path.joined(separator: ".")
    let matches = graph.symbols.filter {
      $0.pathComponents == declaration.path
    }

    guard matches.count == 1, let symbol = matches.first else {
      violations.append(
        "Expected exactly one public declaration at \(declarationName), found \(matches.count)."
      )
      continue
    }

    let conformances = Set(
      graph.relationships.lazy
        .filter {
          $0.kind == "conformsTo"
            && $0.source == symbol.identifier.precise
        }
        .compactMap(\.targetFallback)
    )

    for required in declaration.requiredConformances
    where !conformances.contains(required) {
      violations.append(
        "\(declarationName) must retain conformance to \(required)."
      )
    }

    for forbidden in declaration.forbiddenConformances
    where conformances.contains(forbidden) {
      violations.append(
        "\(declarationName) must not conform to \(forbidden)."
      )
    }

    for forbiddenMember in declaration.forbiddenMembers {
      let forbiddenPath = declaration.path + [forbiddenMember]
      let exposesForbiddenMember = graph.symbols.contains { candidate in
        guard candidate.pathComponents.last == forbiddenMember else {
          return false
        }
        if candidate.pathComponents == forbiddenPath {
          return true
        }

        let referencesToDeclaration =
          candidate.declarationFragments?
          .filter {
            $0.kind == "typeIdentifier"
              && $0.preciseIdentifier == symbol.identifier.precise
          }
          .count ?? 0
        return referencesToDeclaration >= 2
      }

      if exposesForbiddenMember {
        violations.append(
          "\(declarationName) must not expose public member \(forbiddenMember)."
        )
      }
    }
  }

  guard violations.isEmpty else {
    throw PublicAPICheckError.contractViolations(violations.sorted())
  }
}

private func main() throws {
  let repositoryRoot = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()
    .deletingLastPathComponent()
    .standardizedFileURL
  let contractURL =
    repositoryRoot
    .appendingPathComponent("Documentation")
    .appendingPathComponent("API")
    .appendingPathComponent("HDXLURITemplate.public-api.json")
  let externalConsumerURL =
    repositoryRoot
    .appendingPathComponent("Tests")
    .appendingPathComponent("PublicAPIConsumer")
  let externalConsumerSourceURL =
    externalConsumerURL
    .appendingPathComponent("Sources")
    .appendingPathComponent("HDXLURITemplatePublicAPIConsumer")
  let scratchDirectory = FileManager.default.temporaryDirectory
    .appendingPathComponent(
      "hdxl-uri-template-public-api-\(UUID().uuidString)",
      isDirectory: true
    )

  try FileManager.default.createDirectory(
    at: scratchDirectory,
    withIntermediateDirectories: true
  )
  defer {
    try? FileManager.default.removeItem(at: scratchDirectory)
  }

  try validateREADMEExamples(
    at: repositoryRoot.appendingPathComponent("README.md"),
    consumerSourceDirectory: externalConsumerSourceURL,
    scratchDirectory: scratchDirectory,
    repositoryRoot: repositoryRoot
  )
  try runSwift(
    arguments: [
      "build",
      "--package-path", repositoryRoot.path,
      "--scratch-path", scratchDirectory.path,
      "--build-system", "swiftbuild",
      "--build-tests",
      "-q",
    ],
    in: repositoryRoot
  )
  try runSwift(
    arguments: [
      "run",
      "--package-path", externalConsumerURL.path,
      "--scratch-path",
      scratchDirectory.appendingPathComponent("external-consumer").path,
      "--build-system", "swiftbuild",
      "-q",
    ],
    in: externalConsumerURL
  )
  try runSwift(
    arguments: [
      "package",
      "--package-path", repositoryRoot.path,
      "--scratch-path", scratchDirectory.path,
      "--build-system", "swiftbuild",
      "dump-symbol-graph",
      "--minimum-access-level", "public",
    ],
    in: repositoryRoot
  )

  let contract = try JSONDecoder().decode(
    PublicAPIContract.self,
    from: Data(contentsOf: contractURL)
  )
  let symbolGraphURL = try emittedSymbolGraph(
    for: contract.module,
    beneath: scratchDirectory
  )
  let graph = try JSONDecoder().decode(
    SymbolGraph.self,
    from: Data(contentsOf: symbolGraphURL)
  )
  let objectiveCHeaderURLs = try generatedObjectiveCHeaders(
    for: contract.module,
    beneath: scratchDirectory
  )
  let objectiveCHeader =
    try objectiveCHeaderURLs
    .map { try String(contentsOf: $0, encoding: .utf8) }
    .joined(separator: "\n")
  try validate(
    contract: contract,
    against: graph,
    objectiveCHeader: objectiveCHeader
  )

  print(
    "Public API contract and external consumer passed for \(contract.module) "
      + "(\(contract.declarations.count) Swift declarations and "
      + "\(contract.forbiddenDeclarations.count) Swift absences plus "
      + "\(contract.forbiddenObjectiveCDeclarations.count) "
      + "Objective-C absences checked across "
      + "\(objectiveCHeaderURLs.count) generated headers; "
      + "all README Swift examples synchronized)."
  )
}

do {
  try main()
} catch {
  FileHandle.standardError.write(
    Data("Public API contract failed:\n\(error)\n".utf8)
  )
  exit(EXIT_FAILURE)
}
