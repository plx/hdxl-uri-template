
@resultBuilder
public enum URITemplateContextBuilder {
  
  public struct ContextElement {
    @usableFromInline
    internal var name: String

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

  public typealias Component = [ContextElement]

  public static func buildBlock(_ components: Component...) -> Component {
    components.flatMap { $0 }
  }

  public static func buildLimitedAvailability(_ component: Component) -> Component {
    component
  }

  public static func buildEither(first component: Component) -> Component {
    component
  }

  public static func buildEither(second component: Component) -> Component {
    component
  }

  public static func buildOptional(_ component: Component?) -> Component {
    component ?? []
  }

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

  public static func buildFinalResult(_ component: Component) -> [String: URIVariableValue] {
    [String: URIVariableValue](
      component.lazy.map { ($0.name, URIVariableValue(storage: $0.value) )}
    ) { earlier, later in later }
  }

}
