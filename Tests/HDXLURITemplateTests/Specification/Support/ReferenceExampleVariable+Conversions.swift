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
    get throws {
      switch self {
      case .value(.null):
        .undefined
      case .value(let value):
        .text(value.stringRepresentation)
      case .list(let values):
        .list(
          values.compactMap { value in
            switch value {
            case .null:
              nil
            default:
              value.stringRepresentation
            }
          }
        )
      case .association(let association):
        try .association(
          association.lazy.compactMap { key, value in
            switch value {
            case .null:
              nil
            default:
              (key, value.stringRepresentation)
            }
          }
          .sorted(by: { $0.0 < $1.0 })
        )
      }
    }
  }
  
}
