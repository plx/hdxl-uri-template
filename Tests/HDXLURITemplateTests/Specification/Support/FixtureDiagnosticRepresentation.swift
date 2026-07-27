@testable import HDXLURITemplate

// Reference-fixture failures deliberately render their owned test inputs.
// Keep this sensitive formatter in the test target so production error paths
// cannot accidentally adopt it as a default diagnostic.
extension URIVariableValue {
  var fixtureDiagnosticRepresentation: String {
    storage.fixtureDiagnosticRepresentation
  }
}

extension URIVariableValueData {
  var fixtureDiagnosticRepresentation: String {
    switch self {
    case .undefined:
      ".undefined"
    case .text(let text):
      text.fixtureDiagnosticRepresentation
    case .list(let list):
      list.fixtureDiagnosticRepresentation
    case .association(let association):
      association.fixtureDiagnosticRepresentation
    }
  }
}

extension URIVariableTextValue {
  var fixtureDiagnosticRepresentation: String {
    rawValue
  }
}

extension URIVariableListValue {
  var fixtureDiagnosticRepresentation: String {
    let members = storage.lazy.map(\.fixtureDiagnosticRepresentation)
      .joined(separator: ", ")
    return "[ \(members) ]"
  }
}

extension URIVariablePairValue {
  var fixtureDiagnosticRepresentation: String {
    """
    \(key.fixtureDiagnosticRepresentation): \
    \(value.fixtureDiagnosticRepresentation)
    """
  }
}

extension URIVariableAssociationValue {
  var fixtureDiagnosticRepresentation: String {
    let members = storage.lazy.map(\.fixtureDiagnosticRepresentation)
      .joined(separator: ", ")
    return "[ \(members) ]"
  }
}
