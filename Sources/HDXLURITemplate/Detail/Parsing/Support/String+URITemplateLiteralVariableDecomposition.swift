//
//  String+URITemplateLiteralVariableDecomposition.swift
//

import Foundation
import HDXLCommonUtilities
import HDXLAlgebraicUtilities

// -------------------------------------------------------------------------- //
// MARK: String - URITemplate Chunking
// -------------------------------------------------------------------------- //

internal extension String {

  @usableFromInline
  enum URITemplateChunkingError : Error {
    case emptyVariableChunk(String)
    case strayOpenBracketWithinVariableChunk(String)
    case unexpectedCloseBracketWithinLiteralChunk(String)
    case endedWithUnterminatedVariableClause(String)
  }
  
  @usableFromInline
  enum URITemplateChunkingState {
    case literal
    case expression
  }

  @usableFromInline
  enum URITemplateChunkRange {
    case literal(Range<String.Index>)
    case expression(Range<String.Index>)
  }
  
  @inlinable
  func parseIntoURITemplateComponents() throws -> [URITemplateComponent] {
    let ranges = try self.identifyURITemplateChunkRanges()
    return try ranges.map() {
      (chunkRange) throws -> URITemplateComponent
      in
      switch chunkRange {
      case .literal(let literalRange):
        return .literal(
          try URITemplateLiteralComponent(
            parsing: String(self[literalRange])
          )
        )
      case .expression(let expressionRange):
        return .expression(
          try URITemplateExpressionComponent(
            parsing: String(self[expressionRange])
          )
        )
      }
    }
  }

  @inlinable
  func identifyURITemplateChunkRanges() throws -> [URITemplateChunkRange] {
    guard !self.isEmpty else {
      return []
    }
    var state: URITemplateChunkingState = .literal
    var currentLowerBound: String.Index = self.startIndex
    var ranges: [URITemplateChunkRange] = []
    for (index,character) in self.enumeratingIndicesByIndex() {
      // ///////////////////////////////////////////////////////////////////////
      // rare, valid usage: we need to be able to advance `index` at least once,
      // and thus it's critical `index` never be `endIndex`. This should be true
      // as long as `self.enumerateIndices()` is implemented OK, but never hurts
      // to be careful (and to document the requiremnet in case I refactor).
      pedantic_precondition(index < self.endIndex)
      // ///////////////////////////////////////////////////////////////////////
      switch (character, state) {
      case ("{", .literal):
        // finishing a literal, starting a expression;
        // note that empty literal chunks are allowed (they just get discarded)
        if currentLowerBound < index {
          ranges.append(
            .literal(currentLowerBound..<index)
          )
        }
        state = .expression
        currentLowerBound = self.index(after: index)
        // ^ we move `currentLowerBound` so that the upcoming expression chunk
        //   begins *after* the `{`.
      case ("{", .expression):
        // encountering unexpected `{` while already within a `{}`-delimited expression chunk:
        throw URITemplateChunkingError.strayOpenBracketWithinVariableChunk(self)
      case ("}", .literal):
        // encountering unexpected `}` within a `.literal` chunk
        throw URITemplateChunkingError.unexpectedCloseBracketWithinLiteralChunk(self)
      case ("}", .expression):
        // we're finishing a valid .expression chunk
        guard currentLowerBound < index else {
          // whereas empty literals are non-errors (we just ignore them), empty
          // expression clauses are completely forbidden--we error-out if we encounter them
          throw URITemplateChunkingError.emptyVariableChunk(self)
        }
        ranges.append(
          .expression(currentLowerBound..<index)
        )
        currentLowerBound = self.index(after: index)
        // ^ once again we move our `currentLowerBound` past the "}" we just found,
      //   because that's where our next chunk begins.
      default:
        continue
      }
    }
    switch state {
    case .literal:
      if currentLowerBound < self.endIndex {
        ranges.append(
          .literal(currentLowerBound..<self.endIndex)
        )
      }
    case .expression:
      throw URITemplateChunkingError.endedWithUnterminatedVariableClause(self)
    }
    return ranges
  }
  
}

