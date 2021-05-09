//
//  String+URIValueExpansion.swift
//

import Foundation
import HDXLCommonUtilities

internal extension String {
  
  @inlinable
  func escaped(forValueExpansionType valueExpansionType: URIValueExpansionType) -> String? {
    return self.addingPercentEncoding(
      withAllowedCharacters: CharacterSet(
        allowedCharactersForValueExpansionType: valueExpansionType
      )
    )
  }
  
}
