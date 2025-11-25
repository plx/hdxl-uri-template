/// A result builder for constructing URI template parameter dictionaries using a DSL.
///
/// This builder enables fluent construction of `[String: URIVariableValue]` dictionaries
/// using tuple syntax for key-value pairs.
///
/// Example usage:
/// ```swift
/// @URITemplateContextBuilder
/// var context: [String: URIVariableValue] {
///   ("name", "John")
///   ("tags", ["swift", "ios"])
///   ("meta", [("version", "1.0"), ("author", "Jane")])
/// }
/// ```
@resultBuilder
public enum URITemplateContextBuilder {

  /// A single element in the context, pairing a variable name with its value.
  public struct ContextElement {
    /// The variable name.
    @usableFromInline
    internal var name: String

    /// The variable value.
    @usableFromInline
    internal var value: URIVariableValueData

    @inlinable
    internal init(
      name: String,
      value: URIVariableValueData
    ) {
      self.name = name
      self.value = value
    }

  }

  /// The component type for the result builder.
  public typealias Component = [ContextElement]

  /// Combines multiple components into a single component array.
  ///
  /// - Parameter components: The components to combine.
  ///
  /// - Returns: A flattened array of all context elements.
  public static func buildBlock(_ components: Component...) -> Component {
    components.flatMap { $0 }
  }

  /// Builds a component with limited availability.
  ///
  /// - Parameter component: The component to build.
  ///
  /// - Returns: The component unchanged.
  public static func buildLimitedAvailability(_ component: Component) -> Component {
    component
  }

  /// Builds the first branch of a conditional.
  ///
  /// - Parameter component: The component from the first branch.
  ///
  /// - Returns: The component unchanged.
  public static func buildEither(first component: Component) -> Component {
    component
  }

  /// Builds the second branch of a conditional.
  ///
  /// - Parameter component: The component from the second branch.
  ///
  /// - Returns: The component unchanged.
  public static func buildEither(second component: Component) -> Component {
    component
  }

  /// Builds an optional component.
  ///
  /// - Parameter component: The optional component.
  ///
  /// - Returns: The component if present, otherwise an empty array.
  public static func buildOptional(_ component: Component?) -> Component {
    component ?? []
  }

  /// Builds a text value expression from a string tuple.
  ///
  /// - Parameter expression: A tuple of (variable name, string value).
  ///
  /// - Returns: A component containing the text value.
  public static func buildExpression(_ expression: (String, String)) -> Component {
    [
      ContextElement(
        name: expression.0,
        value: .text(
          URIVariableTextValue(rawValue: expression.1)
        )
      )
    ]
  }

  /// Builds a list value expression from a string array tuple.
  ///
  /// - Parameter expression: A tuple of (variable name, array of strings).
  ///
  /// - Returns: A component containing the list value.
  public static func buildExpression(_ expression: (String, [String])) -> Component {
    [
      ContextElement(
        name: expression.0,
        value: .list(
          URIVariableListValue(strings: expression.1)
        )
      )
    ]
  }

  /// Builds an association value expression from a key-value pair array tuple.
  ///
  /// - Parameter expression: A tuple of (variable name, array of key-value pairs).
  ///
  /// - Returns: A component containing the association value.
  public static func buildExpression(_ expression: (String, [(String, String)])) -> Component {
    [
      ContextElement(
        name: expression.0,
        value: .association(
          URIVariableAssociationValue(strings: expression.1)
        )
      )
    ]
  }

  /// Builds the final result dictionary from the collected components.
  ///
  /// - Parameter component: The collected context elements.
  ///
  /// - Returns: A dictionary mapping variable names to their values.
  ///
  /// - Note: If duplicate names exist, the later value wins.
  public static func buildFinalResult(_ component: Component) -> [String: URIVariableValue] {
    [String: URIVariableValue](
      component.lazy.map { ($0.name, URIVariableValue(storage: $0.value) )}
    ) { earlier, later in later }
  }

}
