import Foundation

// -------------------------------------------------------------------------- //
// MARK: String - URITemplate Chunking
// -------------------------------------------------------------------------- //

extension String {

  internal enum URITemplateChunkingState {
    case literal
    case expression
  }

  internal enum URITemplateChunkRange {
    case literal(Range<String.Index>)
    case expression(Range<String.Index>)
  }

  internal func parseIntoURITemplateComponents() throws -> [URITemplateComponent] {
    try identifyURITemplateChunkRanges().map { chunkRange in
      switch chunkRange {
      case .literal(let literalRange):
        try validateURITemplateLiteral(in: literalRange)
        return .literal(
          try URITemplateLiteralComponent(
            parsing: String(self[literalRange])
          )
        )
      case .expression(let expressionRange):
        try validateURITemplateExpression(in: expressionRange)
        return .expression(
          try URITemplateExpressionComponent(
            parsing: String(self[expressionRange])
          )
        )
      }
    }
  }

  internal func identifyURITemplateChunkRanges() throws -> [URITemplateChunkRange] {
    guard !isEmpty else {
      return []
    }

    var state: URITemplateChunkingState = .literal
    var currentLowerBound: String.Index = startIndex
    var ranges: [URITemplateChunkRange] = []
    for index in unicodeScalars.indices {
      let scalar = unicodeScalars[index]
      #if HEAVY_DEBUG
        // rare, valid usage: we need to be able to advance `index` at least once,
        // and thus it's critical `index` never be `endIndex`. This should be true
        // as long as `enumerateIndices()` is implemented OK, but never hurts
        // to be careful (and to document the requiremnet in case I refactor).
        pedanticPrecondition(index < endIndex)
      #endif
      switch (scalar.value, state) {
      case (0x7B, .literal):
        // finishing a literal, starting a expression;
        // note that empty literal chunks are allowed (they just get discarded)
        if currentLowerBound < index {
          ranges.append(
            .literal(currentLowerBound..<index)
          )
        }
        state = .expression
        currentLowerBound = unicodeScalars.index(after: index)
      // ^ we move `currentLowerBound` so that the upcoming expression chunk
      //   begins *after* the `{`.
      case (0x7B, .expression):
        // encountering unexpected `{` while already within a `{}`-delimited expression chunk:
        throw URITemplateSourceDiagnostic(
          kind: .unexpectedOpeningBrace,
          sourceRange: index..<unicodeScalars.index(after: index)
        )
      case (0x7D, .literal):
        // encountering unexpected `}` within a `.literal` chunk
        throw URITemplateSourceDiagnostic(
          kind: .unexpectedClosingBrace,
          sourceRange: index..<unicodeScalars.index(after: index)
        )
      case (0x7D, .expression):
        // we're finishing a valid .expression chunk
        guard currentLowerBound < index else {
          // whereas empty literals are non-errors (we just ignore them), empty
          // expression clauses are completely forbidden--we error-out if we encounter them
          throw URITemplateSourceDiagnostic(
            kind: .emptyExpression,
            sourceRange: index..<index
          )
        }
        ranges.append(
          .expression(currentLowerBound..<index)
        )
        currentLowerBound = unicodeScalars.index(after: index)
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
      throw URITemplateSourceDiagnostic(
        kind: .unterminatedExpression,
        sourceRange: endIndex..<endIndex
      )
    }
    return ranges
  }

}
