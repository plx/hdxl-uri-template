#!/usr/bin/env swift
import Foundation

private struct Arguments {
  let label: String
  let commit: String

  static func parse(_ values: [String]) throws -> Self {
    guard values.count == 5, values[1] == "--label", values[3] == "--commit"
    else {
      throw InventoryError(
        "usage: inventory-cross-module-inlining.swift "
          + "--label LABEL --commit SHA"
      )
    }
    return Self(label: values[2], commit: values[4])
  }
}

private struct Inventory: Codable {
  let schemaVersion: Int
  let label: String
  let commit: String
  let sourceRoot: String
  let swiftFileCount: Int
  let annotatedFileCount: Int
  let totals: Counts
  let categories: [Category]
}

private struct Category: Codable {
  let name: String
  let counts: Counts
  let files: [FileRecord]
}

private struct FileRecord: Codable {
  let path: String
  let counts: Counts
}

private struct Counts: Codable {
  var inlinable = 0
  var usableFromInline = 0
  var alwaysInline = 0
  var alwaysEmitIntoClient = 0

  static func + (lhs: Self, rhs: Self) -> Self {
    Self(
      inlinable: lhs.inlinable + rhs.inlinable,
      usableFromInline: lhs.usableFromInline + rhs.usableFromInline,
      alwaysInline: lhs.alwaysInline + rhs.alwaysInline,
      alwaysEmitIntoClient:
        lhs.alwaysEmitIntoClient + rhs.alwaysEmitIntoClient
    )
  }

  var total: Int {
    inlinable + usableFromInline + alwaysInline + alwaysEmitIntoClient
  }
}

private struct InventoryError: Error, CustomStringConvertible {
  let description: String

  init(_ description: String) {
    self.description = description
  }
}

private func occurrences(of needle: String, in value: String) -> Int {
  value.components(separatedBy: needle).count - 1
}

private func counts(in source: String) -> Counts {
  Counts(
    inlinable: occurrences(of: "@inlinable", in: source),
    usableFromInline: occurrences(of: "@usableFromInline", in: source),
    alwaysInline: occurrences(of: "@inline(__always)", in: source),
    alwaysEmitIntoClient:
      occurrences(of: "@_alwaysEmitIntoClient", in: source)
  )
}

private func category(for path: String) -> String {
  if path.contains("/Assertions/") || path.contains("/Tests/") {
    return "tests-and-assertions"
  }
  if path.contains("Codable") || path.contains("/Coding/") {
    return "codable"
  }
  if path.contains("Description") || path.contains("StringConvertible") {
    return "descriptions"
  }
  if path.contains("ObjectiveC") || path.contains("/ObjC/") {
    return "objective-c"
  }
  if path.contains("/Parsing/") {
    return "parser"
  }
  if path.contains("/ValueExpansion/")
    || path.contains("/Variable/")
    || path.contains("/VariableValue/")
    || path.contains("/TemplateComponent/")
    || path.contains("+Evaluation")
  {
    return "expansion"
  }
  if path.contains("/Template/") {
    return "storage"
  }
  if path.split(separator: "/").count == 3 {
    return "public-api"
  }
  return "support"
}

private func main() throws {
  let arguments = try Arguments.parse(CommandLine.arguments)
  let repositoryRoot = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()
    .deletingLastPathComponent()
    .standardizedFileURL
  let sourceRoot =
    repositoryRoot
    .appendingPathComponent("Sources")
    .appendingPathComponent("HDXLURITemplate")
  guard
    let enumerator = FileManager.default.enumerator(
      at: sourceRoot,
      includingPropertiesForKeys: [.isRegularFileKey],
      options: [.skipsHiddenFiles]
    )
  else {
    throw InventoryError("Unable to enumerate \(sourceRoot.path).")
  }

  var swiftFileCount = 0
  var recordsByCategory: [String: [FileRecord]] = [:]
  for case let fileURL as URL in enumerator
  where fileURL.pathExtension == "swift" {
    swiftFileCount += 1
    let source = try String(contentsOf: fileURL, encoding: .utf8)
    let fileCounts = counts(in: source)
    guard fileCounts.total > 0 else {
      continue
    }
    let path = fileURL.path.replacingOccurrences(
      of: repositoryRoot.path + "/",
      with: ""
    )
    recordsByCategory[category(for: path), default: []].append(
      FileRecord(path: path, counts: fileCounts)
    )
  }

  let categoryNames = [
    "public-api",
    "parser",
    "expansion",
    "storage",
    "codable",
    "descriptions",
    "objective-c",
    "tests-and-assertions",
    "support",
  ]
  let categories = categoryNames.map { name in
    let files = recordsByCategory[name, default: []].sorted {
      $0.path < $1.path
    }
    return Category(
      name: name,
      counts: files.reduce(into: Counts()) {
        $0 = $0 + $1.counts
      },
      files: files
    )
  }
  let totals = categories.reduce(into: Counts()) {
    $0 = $0 + $1.counts
  }
  let inventory = Inventory(
    schemaVersion: 1,
    label: arguments.label,
    commit: arguments.commit,
    sourceRoot: "Sources/HDXLURITemplate",
    swiftFileCount: swiftFileCount,
    annotatedFileCount:
      categories.reduce(into: 0) { $0 += $1.files.count },
    totals: totals,
    categories: categories
  )
  let encoder = JSONEncoder()
  encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
  FileHandle.standardOutput.write(try encoder.encode(inventory))
  FileHandle.standardOutput.write(Data([0x0A]))
}

do {
  try main()
} catch {
  FileHandle.standardError.write(Data("\(error)\n".utf8))
  exit(EXIT_FAILURE)
}
