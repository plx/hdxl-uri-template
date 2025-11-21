import Foundation
import HDXLURITemplate

// MARK: HDXLURIVariableValue

/// Objective-C compatible wrapper around the native-Swift `URIVariableValue`.
///
/// Exists to make the package's functionality accessible from Objective-C, and
/// is entirely-unnecessary when used only from Swift.
///
@objc(HDXLURIVariableValue)
public final class URIVariableValueWrapper : NSObject, NSCopying, NSCoding, NSSecureCoding  {
  
  // MARK: - NSObject Overrides
    
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

  // MARK: - Stored Properties
  
  internal let variableValue: URIVariableValue
  
  // MARK: - Derived Properties
    
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
    variableValue.isDefined
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

  @discardableResult
  @objc(enumerateListValuesUsingBlock:)
  public func enumerateAssociation(
    using block: (String, Int, UnsafeMutablePointer<ObjCBool>) -> Void
  ) -> Bool {
    guard case .list(let listValue) = variableValue.storage else {
      return false
    }
    
    var stop: ObjCBool = false
    for (index,stringValue) in listValue.storage.enumerated() {
      block(
        stringValue.rawValue,
        index,
        &stop
      )
      if stop.boolValue {
        return true
      }
    }
    
    return true
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
  
  @discardableResult
  @objc(enumerateAssociationPairsUsingBlock:)
  public func enumerateAssociation(
    using block: (String, String, Int, UnsafeMutablePointer<ObjCBool>) -> Void
  ) -> Bool {
    guard case .association(let association) = variableValue.storage else {
      return false
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
        return true
      }
    }
    
    return true
  }

  // MARK: - Designated Initializer
  
  @nonobjc
  required public init(variableValue: URIVariableValue) {
    self.variableValue = variableValue
    super.init()
  }

  // MARK: - Objective-C Initializers
  
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

  @objc(initWithDictionary:sortDescriptorForKeys:)
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

  // MARK: - Objective-C Well-Known Values
  
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

  // MARK: - NSCopying
  
  @objc
  public func copy(with zone: NSZone? = nil) -> Any {
    return self
  }
  
  // MARK: - NSCoding
  
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
    if let encoder = coder as? NSKeyedArchiver {
      do {
        try encoder.encodeEncodable(
          self.variableValue,
          forKey: "variableValue"
        )
      }
      catch let e {
        // TODO: just fail quietly? What's best in 2025?
        fatalError("Failed to encode our `variableValue` \(self.variableValue.debugDescription) due to error: \(String(reflecting: e))!")
      }
    }
  }

    // MARK: - NSSecureCoding Protocol Methods
  
  @objc
  public class var supportsSecureCoding: Bool { true }
  
  // MARK: - Storage For Well-Known Values
    
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

// MARK: - Integer Conveniences

extension URIVariableValueWrapper {
  
  @objc(variableValueWithInteger:)
  public class func make(wrapping value: Int) -> Self {
    Self(
      variableValue: URIVariableValue.integer(value)
    )
  }

  @objc(variableValueWithChar:)
  public class func make(wrapping value: Int8) -> Self {
    Self(
      variableValue: URIVariableValue.integer(value)
    )
  }

  @objc(variableValueWithShort:)
  public class func make(wrapping value: Int16) -> Self {
    Self(
      variableValue: URIVariableValue.integer(value)
    )
  }

  @objc(variableValueWithLong:)
  public class func make(wrapping value: Int32) -> Self {
    Self(
      variableValue: URIVariableValue.integer(value)
    )
  }

  @objc(variableValueWithLongLong:)
  public class func make(wrapping value: Int64) -> Self {
    Self(
      variableValue: URIVariableValue.integer(value)
    )
  }

  @objc(variableValueWithInt:)
  public class func __make(wrapping value: Int32) -> Self {
    Self(
      variableValue: URIVariableValue.integer(value)
    )
  }
  
}

// MARK: - Unsigned Integer Conveniences

extension URIVariableValueWrapper {
  
  @objc(variableValueWithUnsignedInteger:)
  public class func make(wrapping value: UInt) -> Self {
    Self(
      variableValue: URIVariableValue.integer(value)
    )
  }

  @objc(variableValueWithUnsignedChar:)
  public class func make(wrapping value: UInt8) -> Self {
    Self(
      variableValue: URIVariableValue.integer(value)
    )
  }
  
  @objc(variableValueWithUnsignedShort:)
  public class func make(wrapping value: UInt16) -> Self {
    Self(
      variableValue: URIVariableValue.integer(value)
    )
  }
  
  @objc(variableValueWithUnsignedLong:)
  public class func make(wrapping value: UInt32) -> Self {
    Self(
      variableValue: URIVariableValue.integer(value)
    )
  }
  
  @objc(variableValueWithUnsignedLongLong:)
  public class func make(wrapping value: UInt64) -> Self {
    Self(
      variableValue: URIVariableValue.integer(value)
    )
  }
 
  @objc(variableValueWithUnsignedInt:)
  public class func __make(wrapping value: UInt32) -> Self {
    Self(
      variableValue: URIVariableValue.integer(value)
    )
  }
  
}

// MARK: - Boolean-Value Conveniences

extension URIVariableValueWrapper {
  
  // MARK: - Yes-or-No
  
  @objc(yesOrNoVariableValue:)
  public class func makeYesOrNo(wrapping boolValue: Bool) -> Self {
    makeYesOrNo(
      wrapping: boolValue,
      capitalization: .lowercase
    )
  }

  @objc(yesOrNoVariableValue:capitalization:)
  public class func makeYesOrNo(
    wrapping boolValue: Bool,
    capitalization: URIVariableValue.BooleanCapitalization
  ) -> Self {
    Self(
      variableValue: URIVariableValue.yesOrNo(
        boolValue: boolValue,
        capitalization: capitalization
      )
    )
  }

  // MARK: - Y-or-N
  
  @objc(yOrNVariableValue:)
  public class func makeYOrN(wrapping boolValue: Bool) -> Self {
    makeYOrN(
      wrapping: boolValue,
      capitalization: .allCaps
    )
  }
  
  @objc(yOrNVariableValue:capitalization:)
  public class func makeYOrN(
    wrapping boolValue: Bool,
    capitalization: URIVariableValue.BooleanCapitalization
  ) -> Self {
    Self(
      variableValue: URIVariableValue.trueOrFalse(
        boolValue: boolValue,
        capitalization: capitalization
      )
    )
  }

  // MARK: - True-or-False
  
  @objc(trueOrFalseVariableValue:)
  public class func makeTrueOrFalse(wrapping boolValue: Bool) -> Self {
    makeTrueOrFalse(
      wrapping: boolValue,
      capitalization: .lowercase
    )
  }
  
  @objc(trueOrFalseVariableValue:capitalization:)
  public class func makeTrueOrFalse(
    wrapping boolValue: Bool,
    capitalization: URIVariableValue.BooleanCapitalization
  ) -> Self {
    Self(
      variableValue: URIVariableValue.trueOrFalse(
        boolValue: boolValue,
        capitalization: capitalization
      )
    )
  }

  // MARK: - Zero-or-One

  @objc(zeroOrOne:)
  public class func zeroOrOne(wrapping boolValue: Bool) -> Self {
    Self(
      variableValue: URIVariableValue.zeroOrOne(
        boolValue: boolValue
      )
    )
  }

}
