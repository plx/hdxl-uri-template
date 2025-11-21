import Foundation
import HDXLURITemplate

// MARK: HDXLURITemplate

/// Objective-C compatible wrapper around the Swift-native `URITemplate`.
///
/// Exists to make the package's functionality accessible from Objective-C, and
/// is entirely-unnecessary when used only from Swift.
///
@objc(HDXLURITemplate)
public final class URITemplateWrapper : NSObject, NSCopying, NSCoding, NSSecureCoding {
  
  // MARK: - NSObject Overrides
    
  @objc
  override public func isEqual(_ object: Any?) -> Bool {
    guard let other = object as? URITemplateWrapper else {
      return false
    }
    return self === other || template == other.template
  }
  
  @objc
  override public var hash: Int {
    template.hashValue
  }
  
  @objc
  override public var description: String {
    "HDXLURITemplate(template: \"\(template.description)\")"
  }
  
  @objc
  override public var debugDescription: String {
    "HDXLURITemplate<\(ObjectIdentifier(self).debugDescription)>(template: \"\(template.debugDescription)\")"
  }
  
  // MARK: - Stored Properties
    
  package let template: URITemplate
  
  // MARK: - Derived Properties
    
  @objc
  public var templateRepresentation: String {
    template.templateRepresentation
  }
  
  /// The names of the variables within the template (as `String`s).
  @objc
  public var templateVariableNames: Set<String> {
    template.variableNames
  }

  // MARK: - Designated Initializer
    
  @nonobjc
  required package init(template: URITemplate) {
    self.template = template
    super.init()
  }
  
  // MARK: - Objective-C Initializers
    
  @objc(initWithURITemplate:)
  public convenience init?(templateString: String) {
    // TODO: parse-failure hook? not sure objective-c support super-high priority in 2025
    guard let parsedTemplate = try? URITemplate(parsing: templateString) else {
      return nil
    }
    
    self.init(template: parsedTemplate)
  }
    
  // MARK: - NSCopying
    
  @objc
  public func copy(with zone: NSZone? = nil) -> Any { self }
  
  // MARK: - NSCoding
    
  @objc
  public required init?(coder: NSCoder) {
    guard
      let decoder = coder as? NSKeyedUnarchiver,
      let template = decoder.decodeDecodable(
        URITemplate.self,
        forKey: "template"
      )
    else {
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
          template,
          forKey: "template"
        )
      }
      catch let e {
        // TODO: what's a good way to handle this failure in 2025?
        fatalError("Failed to encode our `template` \(template.debugDescription) due to error: \(String(reflecting: e))!")
      }
    }
  }
  
  // MARK: - NSSecureCoding
    
  @objc
  public class var supportsSecureCoding: Bool { true }

}
