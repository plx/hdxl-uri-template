//
//  HDXLURITemplate.swift
//

import Foundation
import os.log
import HDXLCommonUtilities

// ------------------------------------------------------------------------ //
// MARK: HDXLURITemplate - Definition
// ------------------------------------------------------------------------ //

/// Objective-C compatible wrapper around the Swift-native `URITemplate`.
///
/// Exists to make the package's functionality accessible from Objective-C, and
/// is entirely-unnecessary when used only from Swift.
///
@objc(HDXLURITemplate)
public class URITemplateWrapper : NSObject, NSCopying, NSCoding, NSSecureCoding {
  
  // ------------------------------------------------------------------------ //
  // MARK: NSObject Overrides
  // ------------------------------------------------------------------------ //
  
  @objc
  override public func isEqual(_ object: Any?) -> Bool {
    guard let other = object as? URITemplateWrapper else {
      return false
    }
    return self === other || self.template == other.template
  }
  
  @objc
  override public var hash: Int {
    get {
      return self.template.hashValue
    }
  }
  
  @objc
  override public var description: String {
    get {
      return "HDXLURITemplate(template: \"\(self.template.description)\")"
    }
  }
  
  @objc
  override public var debugDescription: String {
    get {
      return "HDXLURITemplate<\(ObjectIdentifier(self).debugDescription)>(template: \"\(self.template.debugDescription)\")"
    }
  }
  
  // ------------------------------------------------------------------------ //
  // MARK: Stored Properties
  // ------------------------------------------------------------------------ //
  
  internal let template: URITemplate
  
  // ------------------------------------------------------------------------ //
  // MARK: Derived Properties
  // ------------------------------------------------------------------------ //
  
  @objc
  public var templateRepresentation: String {
    get {
      return self.template.templateRepresentation
    }
  }
  
  /// The names of the variables within the template (as `String`s).
  @objc
  public var templateVariableNames: Set<String> {
    get {
      return self.template.variableNames
    }
  }

  // ------------------------------------------------------------------------ //
  // MARK: Designated Initializer
  // ------------------------------------------------------------------------ //
  
  @nonobjc
  required internal init(template: URITemplate) {
    self.template = template
    super.init()
  }
  
  // ------------------------------------------------------------------------ //
  // MARK: Objective-C Initializers
  // ------------------------------------------------------------------------ //
  
  @objc(initWithURITemplate:)
  public convenience init?(template: String) {
    do {
      self.init(
        template: try URITemplate(parsing: template)
      )
    }
    catch let e {
      // TODO: log somewhere useful
      os_log(
        "Invalid URI-template detected: \"%{private}@\", with error: %{private}@",
        template,
        String(reflecting: e)
      )
      return nil
    }
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
      let template = decoder.decodeDecodable(
        URITemplate.self,
        forKey: "template") else {
          return nil
    }
    self.template = template
    super.init()
  }
  
  @objc
  public func encode(with coder: NSCoder) {
    if let encoder = coder as? NSKeyedArchiver {
      do {
        try encoder.encodeEncodable(
          self.template,
          forKey: "template"
        )
      }
      catch let e {
        fatalError("Failed to encode our `template` \(self.template.debugDescription) due to error: \(String(reflecting: e))!")
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
