import Foundation

extension String {
  
  @inlinable
  internal func escaped(forValueExpansionType valueExpansionType: URIValueExpansionType) -> String? {
    addingPercentEncoding(
      withAllowedCharacters: CharacterSet(
        allowedCharactersForValueExpansionType: valueExpansionType
      )
    )
  }
  
}
