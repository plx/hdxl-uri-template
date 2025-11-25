/// A protocol for types that can be converted to `URIVariableValue`.
///
/// Conforming types can be used directly in template contexts by providing
/// their representation as a `URIVariableValue`.
public protocol URITemplateValueConvertible {

  /// The value represented as a `URIVariableValue` for template substitution.
  var uriVariableValueRepresentation: URIVariableValue { get }

}

extension String: URITemplateValueConvertible {

  /// Returns this string as a text-flavored `URIVariableValue`.
  public var uriVariableValueRepresentation: URIVariableValue {
    URIVariableValue.text(self)
  }

}

