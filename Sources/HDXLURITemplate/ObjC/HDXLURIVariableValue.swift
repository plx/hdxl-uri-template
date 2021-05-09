//
//  HDXLURIVariableValue.swift
//

import Foundation
import HDXLCommonUtilities

// -------------------------------------------------------------------------- //
// MARK: HDXLURIVariableValue - Definition
// -------------------------------------------------------------------------- //

/// Objective-C compatible wrapper around the native-Swift `URIVariableValue`.
///
/// Exists to make the package's functionality accessible from Objective-C, and
/// is entirely-unnecessary when used only from Swift.
///
@objc(HDXLURIVariableValue)
public class URIVariableValueWrapper : NSObject, NSCopying, NSCoding, NSSecureCoding  {
  
  // ------------------------------------------------------------------------ //
  // MARK: NSObject Overrides
  // ------------------------------------------------------------------------ //
  
  @objc
  override public func isEqual(_ object: Any?) -> Bool {
    guard let other = object as? URIVariableValueWrapper else {
      return false
    }
    return self === other || self.variableValue == other.variableValue
  }
  
  @objc
  override public var hash: Int {
    get {
      return self.variableValue.hashValue
    }
  }
  
  @objc
  override public var description: String {
    get {
      return "HDXLURIVariableValue(variableValue: \"\(self.variableValue.description)\")"
    }
  }

  @objc
  override public var debugDescription: String {
    get {
      return "HDXLURIVariableValue<\(ObjectIdentifier(self).debugDescription)>(variableValue: \"\(self.variableValue.debugDescription)\")"
    }
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
    get {
      return self.variableValue.valueType
    }
  }

  @objc
  public var isDefinedVariableValue: Bool {
    get {
      return self.variableValue.isDefined
    }
  }

  @objc
  public var isUndefinedVariableValue: Bool {
    get {
      return self.variableValue.isDefined
    }
  }

  @objc
  public var isTextVariableValue: Bool {
    get {
      return self.variableValue.isTextValue
    }
  }

  @objc
  public var isListVariableValue: Bool {
    get {
      return self.variableValue.isListValue
    }
  }

  @objc
  public var isAssociationVariableValue: Bool {
    get {
      return self.variableValue.isAssociationValue
    }
  }
  
  @objc
  public var textValue: String? {
    get {
      switch self.variableValue.storage {
      case .text(let text):
        return text.storage
      default:
        return nil
      }
    }
  }

  @objc
  public var listValue: [String]? {
    get {
      switch self.variableValue.storage {
      case .list(let list):
        return list.storage.map() {
          $0.storage
        }
      default:
        return nil
      }
    }
  }

  @objc
  public var associationValueAsDictionary: [String:String]? {
    get {
      switch self.variableValue.storage {
      case .association(let association):
        var result: [String:String] = [String:String](minimumCapacity: association.count)
        for pair in association.storage {
          result[pair.key.storage] = pair.value.storage
        }
        return result
      default:
        return nil
      }
    }
  }
  
  @objc(enumerateAssociationPairsUsingBlock:)
  func enumerateAssociation(using block: (String, String, Int, UnsafeMutablePointer<ObjCBool>) -> Void) {
    switch self.variableValue.storage {
    case .association(let association):
      var stop: ObjCBool = false
      for (index,pair) in association.storage.enumerated() {
        block(
          pair.key.storage,
          pair.value.storage,
          index,
          &stop
        )
        if stop.boolValue {
          return
        }
      }
    default:
      ();
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
      variableValue: URIVariableValue(from: string)
    )
  }
  
  @objc(initWithStrings:)
  public convenience init(strings: [String]) {
    self.init(
      variableValue: URIVariableValue(from: strings)
    )
  }

  @objc(initWithKey:value:)
  public convenience init(key: String, value: String) {
    self.init(
      variableValue: URIVariableValue(
        from: (key,value)
      )
    )
  }
  
  @objc(initWithKeys:values:)
  public convenience init(keys: [String], values: [String]) {
    precondition(keys.count == values.count)
    self.init(
      variableValue: URIVariableValue(
        from: zip(keys,values)
      )
    )
  }

  @objc(initWithDictionary:sortDescriptor:)
  public convenience init(
    dictionary: [String:String],
    comparator: (String, String) -> ComparisonResult) {
    self.init(
      variableValue: URIVariableValue(
        from: dictionary.sorted() {
          (l,r) -> Bool
          in
          return comparator(l.0,r.0).impliesLessThan
        }
      )
    )
  }

  // ------------------------------------------------------------------------ //
  // MARK: Objective-C Well-Known Values
  // ------------------------------------------------------------------------ //

  @objc(undefinedVariableValue)
  public class var undefined: URIVariableValueWrapper {
    get {
      return self._emptyString
    }
  }

  @objc(emptyStringVariableValue)
  public class var emptyString: URIVariableValueWrapper {
    get {
      return self._emptyString
    }
  }
  
  @objc(emptyListVariableValue)
  public class var emptyList: URIVariableValueWrapper {
    get {
      return self._emptyList
    }
  }
  
  @objc(emptyAssociationVariableValue)
  public class var emptyAssociation: URIVariableValueWrapper {
    get {
      return self._emptyAssociation
    }
  }

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
        forKey: "variableValue") else {
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
        fatalError("Failed to encode our `variableValue` \(self.variableValue.debugDescription) due to error: \(String(reflecting: e))!")
      }
    }
  }

  // ------------------------------------------------------------------------ //
  // MARK: NSSecureCoding Protocol Methods
  // ------------------------------------------------------------------------ //

  @objc
  public class var supportsSecureCoding: Bool {
    get {
      return true
    }
  }
  
}


