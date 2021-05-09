//
//  Error+Explanation.swift
//

import Foundation
import HDXLCommonUtilities

internal extension Error {
  
  @usableFromInline
  var bestAvailableExplanation: String {
    get {
      guard let localizedError = self as? LocalizedError else {
        return String(reflecting: self)
      }
      return localizedError.localizedDescription
    }
  }
  
}
