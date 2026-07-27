import Foundation
import HDXLURITemplate

func doccErrorsAndDiagnostics() throws {
  do {
    _ = try URITemplate(parsing: "{")
    preconditionFailure("Expected strict parsing to reject the source.")
  } catch let error as URITemplate.ParseError {
    precondition(error.kind == .unterminatedExpression)
    precondition(error.sourceRange == 1..<1)
    precondition(
      error.localizedDescription
        == "The URI template could not be parsed."
    )
  }

  let template = try URITemplate(parsing: "{items:1}")
  do {
    _ = try template.evaluateAsString(
      parameters: ["items": .list(["first", "second"])]
    )
    preconditionFailure("Expected a composite prefix to fail.")
  } catch let error as URITemplate.EvaluationError {
    precondition(error.kind == .prefixModifierNotApplicable)
    precondition(error.failingVariableName == "items")
    precondition(error.prefixModifierCodePointCount == 1)
    precondition(error.failingValueType == .list)
  }
}
