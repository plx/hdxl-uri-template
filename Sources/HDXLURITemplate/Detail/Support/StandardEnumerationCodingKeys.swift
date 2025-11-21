import Foundation

@usableFromInline
package enum StandardEnumerationCodingKeys : String, CodingKey, CaseIterable {
  
  case type = "type"
  case data = "data"
  
  @inlinable
  package var intValue: Int? {
    get {
      switch self {
      case .type:
        0
      case .data:
        1
      }
    }
  }
  
  @inlinable
  package init?(intValue: Int) {
    switch intValue {
    case 0:
      self = .type
    case 1:
      self = .data
    default:
      return nil
    }
  }
  
  @usableFromInline
  package typealias AllCases = [StandardEnumerationCodingKeys]
  
  @usableFromInline
  package static let allCases: AllCases = [ .type, .data ]
  
}
