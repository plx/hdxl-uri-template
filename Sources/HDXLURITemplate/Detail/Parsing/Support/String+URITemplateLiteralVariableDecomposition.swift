import Foundation

// MARK: String - URITemplate Chunking

extension String {

  /// Errors that can occur when chunking a URI template string into components.
  @usableFromInline
  internal enum URITemplateChunkingError : Error {
    /// An empty variable chunk `{}` was encountered.
    case emptyVariableChunk(String)
    /// A `{` was found inside an already-open expression.
    case strayOpenBracketWithinVariableChunk(String)
    /// A `}` was found outside of any expression.
    case unexpectedCloseBracketWithinLiteralChunk(String)
    /// The string ended with an unclosed `{`.
    case endedWithUnterminatedVariableClause(String)
  }

  /// The current state during template string chunking.
  @usableFromInline
  internal enum URITemplateChunkingState {
    /// Currently within a literal portion.
    case literal
    /// Currently within an expression (between `{` and `}`).
    case expression
  }

  /// A range within the template string identifying a chunk type.
  @usableFromInline
  internal enum URITemplateChunkRange {
    /// A literal text range.
    case literal(Range<String.Index>)
    /// An expression range (contents between `{` and `}`).
    case expression(Range<String.Index>)
  }

  /// Parses this string into an array of URI template components.
  ///
  /// - Returns: An array of literal and expression components.
  ///
  /// - Throws: `URITemplateChunkingError` if the template syntax is invalid.
  @inlinable
  internal func parseIntoURITemplateComponents() throws -> [URITemplateComponent] {
    try identifyURITemplateChunkRanges().map() { chunkRange in
      switch chunkRange {
      case .literal(let literalRange):
        .literal(
          try URITemplateLiteralComponent(
            parsing: String(self[literalRange])
          )
        )
      case .expression(let expressionRange):
        .expression(
          try URITemplateExpressionComponent(
            parsing: String(self[expressionRange])
          )
        )
      }
    }
  }

  /// Identifies the ranges of literal and expression chunks within this template string.
  ///
  /// - Returns: An array of chunk ranges, alternating between literals and expressions.
  ///
  /// - Throws: `URITemplateChunkingError` if the template syntax is invalid.
  @inlinable
  internal func identifyURITemplateChunkRanges() throws -> [URITemplateChunkRange] {
    guard !isEmpty else {
      return []
    }
    
    var state: URITemplateChunkingState = .literal
    var currentLowerBound: String.Index = startIndex
    var ranges: [URITemplateChunkRange] = []
    for index in indices {
      let character = self[index]
      // rare, valid usage: we need to be able to advance `index` at least once,
      // and thus it's critical `index` never be `endIndex`. This should be true
      // as long as `enumerateIndices()` is implemented OK, but never hurts
      // to be careful (and to document the requiremnet in case I refactor).
      assert(index < endIndex)
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
        state = .literal
        // ^ once again we move our `currentLowerBound` past the "}" we just found,
      //   because that's where our next chunk begins.
      default:
        continue
      }
    }
    switch state {
    case .literal:
      if currentLowerBound < endIndex {
        ranges.append(
          .literal(currentLowerBound..<endIndex)
        )
      }
    case .expression:
      throw URITemplateChunkingError.endedWithUnterminatedVariableClause(self)
    }
    return ranges
  }
  
}

