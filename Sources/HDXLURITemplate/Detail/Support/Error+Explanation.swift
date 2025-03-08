import Foundation

extension Error {
  
  @usableFromInline
  internal var bestAvailableExplanation: String {
    guard let localizedError = self as? LocalizedError else {
      return String(reflecting: self)
    }
    return localizedError.localizedDescription
  }
  
}
