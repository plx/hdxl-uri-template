import Foundation
import HDXLURITemplate

private enum InputPolicyError: Error {
  case templateTooLarge
}

func doccConcurrencyAndLimits() async throws {
  let source = "https://example.com/items/{id}"
  let maximumTemplateBytes = 4_096
  guard source.utf8.count <= maximumTemplateBytes else {
    throw InputPolicyError.templateTooLarge
  }

  let template = try URITemplate(parsing: source)
  let results = try await withThrowingTaskGroup(
    of: String.self,
    returning: Set<String>.self
  ) { group in
    for identifier in 0..<8 {
      group.addTask {
        try template.evaluateAsString(
          parameters: ["id": .text(String(identifier))]
        )
      }
    }

    var results: Set<String> = []
    for try await result in group {
      results.insert(result)
    }
    return results
  }

  precondition(results.count == 8)
}
