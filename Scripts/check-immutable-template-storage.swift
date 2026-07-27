import Foundation

private let storagePath =
  "Sources/HDXLURITemplate/Detail/Template/URITemplateStorage.swift"

private func fail(_ message: String) -> Never {
  FileHandle.standardError.write(
    Data("immutable-storage contract failure: \(message)\n".utf8)
  )
  exit(1)
}

let repositoryRoot = URL(
  fileURLWithPath: FileManager.default.currentDirectoryPath,
  isDirectory: true
)
let storageURL = repositoryRoot.appendingPathComponent(storagePath)

guard let source = try? String(contentsOf: storageURL, encoding: .utf8) else {
  fail("could not read \(storagePath)")
}

let requiredFragments = [
  "internal final class URITemplateStorage",
  "internal let components: [URITemplateComponent]",
  "internal let templateSource: String",
  "internal let variableNames: Set<String>",
  "extension URITemplateStorage: Sendable {}",
]

for fragment in requiredFragments where source.contains(fragment) == false {
  fail("missing required declaration `\(fragment)`")
}

let forbiddenFragments = [
  "@unchecked Sendable",
  "OSAllocatedUnfairLock",
  "cachedFieldLock",
  "isKnownUniquelyReferenced",
  "obtainAssuredValue",
  "os.lock",
]

for fragment in forbiddenFragments where source.contains(fragment) {
  fail("found forbidden mutable-storage fragment `\(fragment)`")
}

print("immutable-storage contract passed")
