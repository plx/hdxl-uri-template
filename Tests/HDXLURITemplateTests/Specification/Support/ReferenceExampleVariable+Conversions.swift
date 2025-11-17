@testable import HDXLURITemplate

extension ReferenceExamplePrimitiveJSONValue {
  
  var stringRepresentation: String {
    switch self {
    case .null:
      ""
    case .integer(let integer):
      String(integer)
    case .double(let double):
      String(double)
    case .boolean(let boolean):
      switch boolean {
      case true:
        "true"
      case false:
        "false"
      }
    case .string(let string):
      string
    }
  }
  
}

extension ReferenceExampleVariable {
  
  var variableValue: URIVariableValue {
    switch self {
    case .value(let value):
      .text(value.stringRepresentation)
    case .list(let values):
      .list(values.map(\.stringRepresentation))
    case .association(let association):
      .association(
        association.lazy.map { key, value in
          (key, value.stringRepresentation)
        }.sorted(by: { $0.0 < $1.0 })
      )
    }
  }
  
}
