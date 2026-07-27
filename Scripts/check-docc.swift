#!/usr/bin/env swift
import Foundation

private struct DocumentationCoverageEntry: Decodable {
  let title: String
  let referencePath: String
  let kind: Kind
  let hasAbstract: Bool

  struct Kind: Decodable {
    let isSymbol: Bool
    let name: String
  }
}

private enum DocCCheckError: Error, CustomStringConvertible {
  case commandFailed(command: String, status: Int32)
  case documentationViolations([String])
  case missingSymbolGraph(directory: String)
  case multipleSymbolGraphs(paths: [String])
  case missingCoverage(path: String)
  case undocumentedSymbols([String])

  var description: String {
    switch self {
    case .commandFailed(let command, let status):
      "Command failed with status \(status): \(command)"
    case .documentationViolations(let violations):
      violations.joined(separator: "\n")
    case .missingSymbolGraph(let directory):
      "No HDXLURITemplate.symbols.json was emitted beneath \(directory)."
    case .multipleSymbolGraphs(let paths):
      "Expected one HDXLURITemplate symbol graph, found: \(paths.joined(separator: ", "))."
    case .missingCoverage(let path):
      "DocC did not emit documentation coverage at \(path)."
    case .undocumentedSymbols(let symbols):
      "Public symbols without an abstract:\n\(symbols.joined(separator: "\n"))"
    }
  }
}

private func run(
  executable: String,
  arguments: [String],
  in directory: URL
) throws {
  let process = Process()
  process.executableURL = URL(fileURLWithPath: executable)
  process.arguments = arguments
  process.currentDirectoryURL = directory
  try process.run()
  process.waitUntilExit()

  guard process.terminationReason == .exit, process.terminationStatus == 0 else {
    throw DocCCheckError.commandFailed(
      command: ([executable] + arguments).joined(separator: " "),
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

private func markdownFiles(beneath catalog: URL) throws -> [URL] {
  let resourceKeys: [URLResourceKey] = [.isRegularFileKey]
  guard
    let enumerator = FileManager.default.enumerator(
      at: catalog,
      includingPropertiesForKeys: resourceKeys,
      options: [.skipsHiddenFiles]
    )
  else {
    return []
  }

  var files: [URL] = []
  for case let candidate as URL in enumerator
  where candidate.pathExtension == "md" {
    let values = try candidate.resourceValues(forKeys: Set(resourceKeys))
    if values.isRegularFile == true {
      files.append(candidate)
    }
  }
  return files.sorted { $0.path < $1.path }
}

private func validateCompiledExamples(
  catalog: URL,
  consumerSourceDirectory: URL
) throws -> Int {
  let expectedSourceNames = [
    "READMEQuickStart.swift",
    "READMEVariableValues.swift",
    "DocCOperatorsAndModifiers.swift",
    "DocCErrorsAndDiagnostics.swift",
    "DocCPersistence.swift",
    "DocCConcurrencyAndLimits.swift",
  ]
  let blocks = try markdownFiles(beneath: catalog).flatMap {
    swiftCodeBlocks(
      in: try String(contentsOf: $0, encoding: .utf8)
    )
  }
  var violations: [String] = []

  if blocks.count != expectedSourceNames.count {
    violations.append(
      "Expected exactly \(expectedSourceNames.count) DocC Swift examples, "
        + "found \(blocks.count)."
    )
  }

  for sourceName in expectedSourceNames {
    let sourceURL =
      consumerSourceDirectory.appendingPathComponent(sourceName)
    let source = try String(contentsOf: sourceURL, encoding: .utf8)
      .trimmingCharacters(in: .newlines)
    let matches = blocks.filter { $0 == source }
    if matches.count != 1 {
      violations.append(
        "DocC must contain exactly one example matching \(sourceURL.path); "
          + "found \(matches.count)."
      )
    }
  }

  guard violations.isEmpty else {
    throw DocCCheckError.documentationViolations(violations)
  }
  return blocks.count
}

private func validatePageAbstracts(catalog: URL) throws -> Int {
  let files = try markdownFiles(beneath: catalog)
  var violations: [String] = []

  for file in files {
    let lines = try String(contentsOf: file, encoding: .utf8)
      .split(separator: "\n", omittingEmptySubsequences: false)
    guard
      let titleIndex = lines.firstIndex(where: {
        !$0.trimmingCharacters(in: .whitespaces).isEmpty
      }),
      lines[titleIndex].hasPrefix("# ")
    else {
      violations.append(
        "DocC page must begin with a level-one title: \(file.path)"
      )
      continue
    }

    let firstContent =
      lines[(titleIndex + 1)...].first(where: {
        !$0.trimmingCharacters(in: .whitespaces).isEmpty
      })
    guard
      let firstContent,
      !firstContent.hasPrefix("#"),
      !firstContent.hasPrefix("@"),
      !firstContent.hasPrefix("```")
    else {
      violations.append(
        "DocC page title must be followed by a prose abstract: \(file.path)"
      )
      continue
    }
  }

  guard violations.isEmpty else {
    throw DocCCheckError.documentationViolations(violations)
  }
  return files.count
}

private func symbolGraph(
  beneath directory: URL
) throws -> URL {
  let expectedName = "HDXLURITemplate.symbols.json"
  let resourceKeys: [URLResourceKey] = [.isRegularFileKey]
  guard
    let enumerator = FileManager.default.enumerator(
      at: directory,
      includingPropertiesForKeys: resourceKeys,
      options: [.skipsHiddenFiles]
    )
  else {
    throw DocCCheckError.missingSymbolGraph(directory: directory.path)
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
    throw DocCCheckError.missingSymbolGraph(directory: directory.path)
  default:
    throw DocCCheckError.multipleSymbolGraphs(
      paths: eligibleMatches.map(\.path).sorted()
    )
  }
}

private func main() throws {
  let repositoryRoot = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()
    .deletingLastPathComponent()
    .standardizedFileURL
  let defaultCatalog =
    repositoryRoot
    .appendingPathComponent("Sources")
    .appendingPathComponent("HDXLURITemplate")
    .appendingPathComponent("HDXLURITemplate.docc")
  let catalog =
    ProcessInfo.processInfo.environment["HDXL_DOCC_CATALOG_PATH"].map {
      URL(fileURLWithPath: $0).standardizedFileURL
    } ?? defaultCatalog
  let consumerSourceDirectory =
    repositoryRoot
    .appendingPathComponent("Tests")
    .appendingPathComponent("PublicAPIConsumer")
    .appendingPathComponent("Sources")
    .appendingPathComponent("HDXLURITemplatePublicAPIConsumer")
  let scratchDirectory =
    FileManager.default.temporaryDirectory
    .appendingPathComponent(
      "hdxl-uri-template-docc-\(UUID().uuidString)",
      isDirectory: true
    )
  let buildDirectory =
    scratchDirectory.appendingPathComponent("build", isDirectory: true)
  let symbolGraphDirectory =
    scratchDirectory.appendingPathComponent("symbols", isDirectory: true)
  let archive =
    scratchDirectory.appendingPathComponent(
      "HDXLURITemplate.doccarchive",
      isDirectory: true
    )

  try FileManager.default.createDirectory(
    at: symbolGraphDirectory,
    withIntermediateDirectories: true
  )
  defer {
    try? FileManager.default.removeItem(at: scratchDirectory)
  }

  let pageCount = try validatePageAbstracts(catalog: catalog)
  let exampleCount = try validateCompiledExamples(
    catalog: catalog,
    consumerSourceDirectory: consumerSourceDirectory
  )
  try run(
    executable: "/usr/bin/env",
    arguments: [
      "swift",
      "build",
      "--package-path", repositoryRoot.path,
      "--scratch-path", buildDirectory.path,
      "--build-system", "swiftbuild",
      "--build-tests",
      "-q",
    ],
    in: repositoryRoot
  )
  try run(
    executable: "/usr/bin/env",
    arguments: [
      "swift",
      "package",
      "--package-path", repositoryRoot.path,
      "--scratch-path", buildDirectory.path,
      "--build-system", "swiftbuild",
      "dump-symbol-graph",
      "--minimum-access-level", "public",
      "--skip-synthesized-members",
    ],
    in: repositoryRoot
  )
  let emittedGraph = try symbolGraph(beneath: buildDirectory)
  try FileManager.default.copyItem(
    at: emittedGraph,
    to: symbolGraphDirectory.appendingPathComponent(
      "HDXLURITemplate.symbols.json"
    )
  )

  try run(
    executable: "/usr/bin/xcrun",
    arguments: [
      "docc",
      "convert",
      catalog.path,
      "--additional-symbol-graph-dir", symbolGraphDirectory.path,
      "--output-path", archive.path,
      "--fallback-display-name", "HDXLURITemplate",
      "--fallback-bundle-identifier", "com.plx.HDXLURITemplate",
      "--fallback-bundle-version", "0",
      "--fallback-default-module-kind", "Library",
      "--warnings-as-errors",
      "--analyze",
      "--enable-inherited-docs",
      "--enable-parameters-and-returns-validation",
      "--experimental-documentation-coverage",
      "--coverage-summary-level", "brief",
      "--checkout-path", repositoryRoot.path,
      "--source-service", "github",
      "--source-service-base-url",
      "https://github.com/plx/hdxl-uri-template/blob/master",
    ],
    in: repositoryRoot
  )

  let coverageURL =
    archive.appendingPathComponent("documentation-coverage.json")
  guard FileManager.default.fileExists(atPath: coverageURL.path) else {
    throw DocCCheckError.missingCoverage(path: coverageURL.path)
  }
  let coverage = try JSONDecoder().decode(
    [DocumentationCoverageEntry].self,
    from: Data(contentsOf: coverageURL)
  )
  let publicSymbols = coverage.filter(\.kind.isSymbol)
  let undocumented = publicSymbols.filter { !$0.hasAbstract }
  guard undocumented.isEmpty else {
    throw DocCCheckError.undocumentedSymbols(
      undocumented.map {
        "\($0.kind.name): \($0.title) (\($0.referencePath))"
      }
    )
  }

  print(
    "DocC contract passed for \(publicSymbols.count) public symbols, "
      + "\(pageCount) authored catalog pages, "
      + "and \(exampleCount) synchronized compiled examples."
  )
}

do {
  try main()
} catch {
  FileHandle.standardError.write(
    Data("DocC contract failed:\n\(error)\n".utf8)
  )
  exit(EXIT_FAILURE)
}
