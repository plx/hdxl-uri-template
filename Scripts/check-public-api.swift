#!/usr/bin/env swift
import Foundation

private struct PublicAPIContract: Decodable {
  let module: String
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
  case missingSymbolGraph(module: String, directory: String)
  case multipleSymbolGraphs(module: String, paths: [String])
  case contractViolations([String])

  var description: String {
    switch self {
    case .commandFailed(let command, let status):
      "Command failed with status \(status): \(command)"
    case .missingSymbolGraph(let module, let directory):
      "No \(module).symbols.json was emitted beneath \(directory)."
    case .multipleSymbolGraphs(let module, let paths):
      "Found multiple \(module) symbol graphs where exactly one was expected: \(paths.joined(separator: ", "))."
    case .contractViolations(let violations):
      violations.joined(separator: "\n")
    }
  }
}

private func runSwift(
  arguments: [String],
  in repositoryRoot: URL
) throws {
  let process = Process()
  process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
  process.arguments = ["swift"] + arguments
  process.currentDirectoryURL = repositoryRoot
  try process.run()
  process.waitUntilExit()

  guard process.terminationReason == .exit, process.terminationStatus == 0 else {
    throw PublicAPICheckError.commandFailed(
      command: (["swift"] + arguments).joined(separator: " "),
      status: process.terminationStatus
    )
  }
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
  against graph: SymbolGraph
) throws {
  var violations: [String] = []

  if graph.module.name != contract.module {
    violations.append(
      "Expected module \(contract.module), but the symbol graph describes \(graph.module.name)."
    )
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

  try runSwift(
    arguments: [
      "build",
      "--package-path", repositoryRoot.path,
      "--scratch-path", scratchDirectory.path,
      "--build-tests",
      "-q",
    ],
    in: repositoryRoot
  )
  try runSwift(
    arguments: [
      "build",
      "--package-path", externalConsumerURL.path,
      "--scratch-path",
      scratchDirectory.appendingPathComponent("external-consumer").path,
      "-q",
    ],
    in: externalConsumerURL
  )
  try runSwift(
    arguments: [
      "package",
      "--package-path", repositoryRoot.path,
      "--scratch-path", scratchDirectory.path,
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
  try validate(contract: contract, against: graph)

  print(
    "Public API contract passed for \(contract.module) "
      + "(\(contract.declarations.count) declarations checked)."
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
