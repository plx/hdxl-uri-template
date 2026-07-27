# Handling Errors and Diagnostics

Use stable error categories while treating stored recovery context as
potentially sensitive.

## Overview

### Parse errors

``URITemplate/ParseError`` exposes a stable ``URITemplate/ParseError/kind`` and
an offending ``URITemplate/ParseError/sourceRange`` measured in UTF-8 bytes.
Its default Swift and Foundation descriptions are bounded and omit the source
text. The stored ``URITemplate/ParseError/template`` is explicit recovery
context and can contain secrets or personal data.

### Evaluation errors

``URITemplate/EvaluationError`` categorizes composite-prefix and invalid-URL
failures. Default descriptions omit the template, parameters, variable names,
rendered output, and nested errors. Its template, parameters, variable name,
and underlying error properties are deliberate recovery context; apply an
application-specific redaction policy before logging them.

``URIVariableValue/AssociationError`` reports duplicate positions or
mismatched collection counts without including caller-provided keys or values.

```swift
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
```
