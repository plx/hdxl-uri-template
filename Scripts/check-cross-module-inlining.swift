#!/usr/bin/env swift
import Foundation

private struct Violation {
  let path: String
  let line: Int
  let annotation: String
}

private let forbiddenAnnotations = [
  "@inlinable",
  "@usableFromInline",
  "@inline(__always)",
  "@_alwaysEmitIntoClient",
]

private func main() throws {
  let repositoryRoot = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()
    .deletingLastPathComponent()
    .standardizedFileURL
  let sourceRoot =
    ProcessInfo.processInfo.environment["ARCH02_SOURCE_ROOT"].map {
      URL(fileURLWithPath: $0).standardizedFileURL
    }
    ?? repositoryRoot
    .appendingPathComponent("Sources")
    .appendingPathComponent("HDXLURITemplate")

  guard
    let enumerator = FileManager.default.enumerator(
      at: sourceRoot,
      includingPropertiesForKeys: [.isRegularFileKey],
      options: [.skipsHiddenFiles]
    )
  else {
    throw CocoaError(.fileReadNoSuchFile)
  }

  var swiftFileCount = 0
  var violations: [Violation] = []
  for case let fileURL as URL in enumerator
  where fileURL.pathExtension == "swift" {
    swiftFileCount += 1
    let source = try String(contentsOf: fileURL, encoding: .utf8)
    for (offset, line) in source.split(
      separator: "\n",
      omittingEmptySubsequences: false
    ).enumerated() {
      for annotation in forbiddenAnnotations where line.contains(annotation) {
        violations.append(
          Violation(
            path: fileURL.path.replacingOccurrences(
              of: repositoryRoot.path + "/",
              with: ""
            ),
            line: offset + 1,
            annotation: annotation
          )
        )
      }
    }
  }

  guard violations.isEmpty else {
    for violation in violations {
      FileHandle.standardError.write(
        Data(
          """
          \(violation.path):\(violation.line): forbidden \
          \(violation.annotation)

          """.utf8
        )
      )
    }
    throw InliningGateError(
      "Found \(violations.count) unjustified inlining annotations."
    )
  }

  print(
    "Cross-module inlining gate passed for \(swiftFileCount) Swift source "
      + "files (zero forbidden annotations)."
  )
}

private struct InliningGateError: Error, CustomStringConvertible {
  let description: String

  init(_ description: String) {
    self.description = description
  }
}

do {
  try main()
} catch {
  FileHandle.standardError.write(
    Data("Cross-module inlining gate failed: \(error)\n".utf8)
  )
  exit(EXIT_FAILURE)
}
