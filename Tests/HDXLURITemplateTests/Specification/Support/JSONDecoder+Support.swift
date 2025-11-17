import Foundation

extension JSONDecoder {
  
  static let referenceExampleJSONDecoder: JSONDecoder = {
    var decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return decoder
  }()
}
