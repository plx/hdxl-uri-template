
public protocol URITemplateValueConvertible {

  var uriVariableValueRepresentation: URIVariableValue { get }

}

extension String: URITemplateValueConvertible {

  public var uriVariableValueRepresentation: URIVariableValue {
    URIVariableValue.text(self)
  }

}

