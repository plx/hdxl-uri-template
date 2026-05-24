import Foundation

// -------------------------------------------------------------------------- //
// MARK: HDXLURIVariableValue - Definition
// -------------------------------------------------------------------------- //

/// Objective-C compatible wrapper around the native-Swift `URIVariableValue`.
///
/// Exists to make the package's functionality accessible from Objective-C, and
/// is entirely-unnecessary when used only from Swift.
///
@objc(HDXLURIVariableValue)
public final class URIVariableValueWrapper : NSObject, NSCopying, NSCoding, NSSecureCoding  {
  
  // ------------------------------------------------------------------------ //
  // MARK: NSObject Overrides
  // ------------------------------------------------------------------------ //
  
  @objc
  override public func isEqual(_ object: Any?) -> Bool {
    guard let other = object as? URIVariableValueWrapper else {
      return false
    }
    return self === other || variableValue == other.variableValue
  }
  
  @objc
  override public var hash: Int {
    variableValue.hashValue
  }
  
  @objc
  override public var description: String {
    "HDXLURIVariableValue(variableValue: \"\(variableValue.description)\")"
  }

  @objc
  override public var debugDescription: String {
    "HDXLURIVariableValue<\(ObjectIdentifier(self).debugDescription)>(variableValue: \"\(variableValue.debugDescription)\")"
  }

  // ------------------------------------------------------------------------ //
  // MARK: Stored Properties
  // ------------------------------------------------------------------------ //

  internal let variableValue: URIVariableValue
  
  // ------------------------------------------------------------------------ //
  // MARK: Derived Properties
  // ------------------------------------------------------------------------ //
  
  @objc
  public var variableValueType: URIVariableValueType {
    variableValue.valueType
  }

  @objc
  public var isDefinedVariableValue: Bool {
    variableValue.isDefined
  }

  @objc
  public var isUndefinedVariableValue: Bool {
    variableValue.isUndefined
  }

  @objc
  public var isTextVariableValue: Bool {
    variableValue.isTextValue
  }

  @objc
  public var isListVariableValue: Bool {
    variableValue.isListValue
  }

  @objc
  public var isAssociationVariableValue: Bool {
    variableValue.isAssociationValue
  }
  
  @objc
  public var textValue: String? {
    switch variableValue.storage {
    case .text(let text):
      text.rawValue
    default:
      nil
    }
  }

  @objc
  public var listValue: [String]? {
    guard
      case .list(let list) = variableValue.storage
    else {
      return nil
    }
    
    return list.storage.map {
      $0.rawValue
    }
  }

  @objc
  public var associationValueAsDictionary: [String:String]? {
    guard
      case .association(let association) = variableValue.storage
    else {
      return nil
    }

    // safe to assume truly-unique b/c we're just stripping a newtype
    // wrapper from an underlying, already-existing dictionary
    return [String:String](uniqueKeysWithValues: association.storage.map {
      ($0.key.rawValue, $0.value.rawValue)
    })
  }
  
  @objc(enumerateAssociationPairsUsingBlock:)
  public func enumerateAssociation(
    using block: (String, String, Int, UnsafeMutablePointer<ObjCBool>) -> Void
  ) {
    guard case .association(let association) = variableValue.storage else {
      return
    }
    
    var stop: ObjCBool = false
    for (index,pair) in association.storage.enumerated() {
      block(
        pair.key.rawValue,
        pair.value.rawValue,
        index,
        &stop
      )
      if stop.boolValue {
        return
      }
    }
  }

  // ------------------------------------------------------------------------ //
  // MARK: Designated Initializer
  // ------------------------------------------------------------------------ //

  @nonobjc
  required internal init(variableValue: URIVariableValue) {
    self.variableValue = variableValue
    super.init()
  }

  // ------------------------------------------------------------------------ //
  // MARK: Objective-C Initializers
  // ------------------------------------------------------------------------ //

  @objc(initWithString:)
  public convenience init(string: String) {
    self.init(
      variableValue: .text(string)
    )
  }
  
  @objc(initWithStrings:)
  public convenience init(strings: [String]) {
    self.init(
      variableValue: .list(strings)
    )
  }

  @objc(initWithKey:value:)
  public convenience init(key: String, value: String) {
    self.init(
      variableValue: .association(
        key: key,
        value: value
      )
    )
  }
  
  @objc(initWithKeys:values:)
  public convenience init(keys: [String], values: [String]) {
    precondition(keys.count == values.count)
    self.init(
      variableValue: .association(
        zip(keys,values)
      )
    )
  }

  @objc(initWithDictionary:sortDescriptor:)
  public convenience init(
    dictionary: [String:String],
    comparator: (String, String) -> ComparisonResult) {
    self.init(
      variableValue: .association(
        dictionary.sorted {
          (l,r) -> Bool
          in
          comparator(l.0,r.0) == .orderedAscending
        }
      )
    )
  }

  // ------------------------------------------------------------------------ //
  // MARK: Objective-C Well-Known Values
  // ------------------------------------------------------------------------ //

  @objc(undefinedVariableValue)
  public class var undefined: URIVariableValueWrapper {
    _undefined
  }

  @objc(emptyStringVariableValue)
  public class var emptyString: URIVariableValueWrapper {
    _emptyString
  }
  
  @objc(emptyListVariableValue)
  public class var emptyList: URIVariableValueWrapper {
    _emptyList
  }
  
  @objc(emptyAssociationVariableValue)
  public class var emptyAssociation: URIVariableValueWrapper {
    _emptyAssociation
  }

  // ------------------------------------------------------------------------ //
  // MARK: NSCopying Protocol Methods
  // ------------------------------------------------------------------------ //

  @objc
  public func copy(with zone: NSZone? = nil) -> Any {
    return self
  }
  
  // ------------------------------------------------------------------------ //
  // MARK: NSCoding Protocol Methods
  // ------------------------------------------------------------------------ //

  @objc
  public required init?(coder: NSCoder) {
    guard
      let decoder = coder as? NSKeyedUnarchiver,
      let variableValue = decoder.decodeDecodable(
        URIVariableValue.self,
        forKey: "variableValue"
      )
    else {
      return nil
    }
    
    self.variableValue = variableValue
    super.init()
  }
  
  @objc
  public func encode(with coder: NSCoder) {
    guard let encoder = coder as? NSKeyedArchiver else { return }
    do {
      try encoder.encodeEncodable(
        self.variableValue,
        forKey: "variableValue"
      )
    } catch {
      coder.failWithError(error)
    }
  }

  // ------------------------------------------------------------------------ //
  // MARK: NSSecureCoding Protocol Methods
  // ------------------------------------------------------------------------ //

  @objc
  public class var supportsSecureCoding: Bool { true }
  
  // ------------------------------------------------------------------------ //
  // MARK: Storage For Well-Known Values
  // ------------------------------------------------------------------------ //
  
  @nonobjc
  internal static let _undefined: URIVariableValueWrapper = URIVariableValueWrapper(variableValue: .undefined)
  
  @nonobjc
  internal static let _emptyString: URIVariableValueWrapper = URIVariableValueWrapper(variableValue: .emptyString)
  
  @nonobjc
  internal static let _emptyList: URIVariableValueWrapper = URIVariableValueWrapper(variableValue: .emptyList)
  
  @nonobjc
  internal static let _emptyAssociation: URIVariableValueWrapper = URIVariableValueWrapper(variableValue: .emptyAssociation)

}

// ok to be `Sendable` b/c we're internally-immutable
extension URIVariableValueWrapper: @unchecked Sendable { }
