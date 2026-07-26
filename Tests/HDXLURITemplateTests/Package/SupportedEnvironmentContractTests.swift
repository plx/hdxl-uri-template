import Foundation
import Testing

@Test("Manifest and README agree on the supported environment floor")
private func supportedEnvironmentContractIsConsistent() throws {
  let manifest = try repositoryFile(named: "Package.swift")
  let readme = try repositoryFile(named: "README.md")
  let normalizedReadme =
    readme
    .split(whereSeparator: { $0.isWhitespace })
    .joined(separator: " ")

  let platformDeclarations = """
    .iOS(.v26)
    .macOS(.v26)
    .tvOS(.v26)
    .watchOS(.v26)
    .visionOS(.v26)
    .macCatalyst(.v26)
    """
    .split(separator: "\n")
    .map(String.init)

  #expect(manifest.hasPrefix("// swift-tools-version:6.3\n"))
  #expect(
    manifest.range(
      of: #"swiftLanguageModes:\s*\[\s*\.v6\s*\]"#,
      options: .regularExpression
    ) != nil
  )
  #expect(
    manifest.components(separatedBy: ".v26").count - 1
      == platformDeclarations.count
  )

  for platform in platformDeclarations {
    #expect(manifest.contains(platform))
  }

  #expect(normalizedReadme.contains("Swift tools version 6.3"))
  #expect(normalizedReadme.contains("Swift language mode 6"))
  #expect(
    normalizedReadme.contains(
      """
      iOS 26 or later, macOS 26 or later, tvOS 26 or later, watchOS 26 or \
      later, visionOS 26 or later, and Mac Catalyst 26 or later
      """
    )
  )
  #expect(
    normalizedReadme.contains(
      """
      Older Swift toolchains, older Apple OS releases, and non-Apple \
      platforms, including Linux, are intentionally unsupported.
      """
    )
  )
}

private func repositoryFile(named name: String) throws -> String {
  let repositoryRoot = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()
    .deletingLastPathComponent()
    .deletingLastPathComponent()
    .deletingLastPathComponent()
  return try String(
    contentsOf: repositoryRoot.appendingPathComponent(name),
    encoding: .utf8
  )
}
