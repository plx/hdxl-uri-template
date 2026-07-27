//
//  Scanner+URITemplateParsing.swift
//

import Foundation
//internal extension Scanner {
//
//  enum CharacterScanOutcomeInterpretation {
//    case .alreadyAtEnd
//    case .exhaustedBeforeSeparator(String)
//    case .terminatesWithSeparator(String)
//    case .reachedSeparatorMoreToCome(String)
//  }
//
//  func interpretedScanUpToSeparator(separator character: String) -> CharacterScanOutcomeInterpretation {
//    precondition(character.count == 1)
//    guard !self.isAtEnd else {
//      return .alreadyAtEnd
//    }
//    switch self.scanUpToString(character) {
//    case .some(let result):
//      switch self.isAtEnd {
//      case true:
//        return .exhausted(result)
//      case false:
//        guard let separatorCharacter = self.scanCharacter() else {
//          fatalError("Expected to scan up to \(character), but something went wrong.")
//        }
//        precondition(character == String(separatorCharacter))
//        switch self.isAtEnd {
//        case true:
//          return .terminatesWithSeparator(result)
//        case false:
//          return .reachedSeparatorMoreToCome(result)
//        }
//      }
//    case .none:
//      precondition(!self.isAtEnd)
//      return .alreadyAtEnd
//    }
//    guard let result =  else
//  }
//
//}
