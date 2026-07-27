import Foundation

internal struct URITemplateSourceDiagnostic: Error, Sendable {
  internal let kind: URITemplate.ParseError.Kind

  internal let sourceRange: Range<String.Index>

  internal init(
    kind: URITemplate.ParseError.Kind,
    sourceRange: Range<String.Index>
  ) {
    self.kind = kind
    self.sourceRange = sourceRange
  }
}

extension String {
  internal func utf8OffsetRange(
    for sourceRange: Range<Index>
  ) -> Range<Int> {
    let lowerBound = utf8.distance(
      from: utf8.startIndex,
      to: sourceRange.lowerBound
    )
    let upperBound = utf8.distance(
      from: utf8.startIndex,
      to: sourceRange.upperBound
    )
    return lowerBound..<upperBound
  }

  internal func validateURITemplateLiteral(
    in sourceRange: Range<Index>
  ) throws {
    let scalars = unicodeScalars
    var index = sourceRange.lowerBound

    while index < sourceRange.upperBound {
      let scalar = scalars[index]
      if scalar.value == 0x25 {
        guard
          let endIndex = percentEncodedTripletEnd(
            startingAt: index,
            before: sourceRange.upperBound
          )
        else {
          throw URITemplateSourceDiagnostic(
            kind: .malformedPercentEncoding,
            sourceRange: malformedPercentRange(
              startingAt: index,
              before: sourceRange.upperBound
            )
          )
        }
        index = endIndex
        continue
      }

      guard Self.isAllowedURITemplateLiteralScalar(scalar.value) else {
        throw URITemplateSourceDiagnostic(
          kind: .invalidLiteral,
          sourceRange: index..<scalars.index(after: index)
        )
      }
      index = scalars.index(after: index)
    }
  }

  internal func validateURITemplateExpression(
    in sourceRange: Range<Index>
  ) throws {
    var variableListRange = sourceRange
    guard !variableListRange.isEmpty else {
      throw URITemplateSourceDiagnostic(
        kind: .emptyExpression,
        sourceRange: sourceRange
      )
    }

    let firstIndex = variableListRange.lowerBound
    let firstScalar = unicodeScalars[firstIndex]
    if Self.isSupportedURITemplateOperator(firstScalar.value) {
      variableListRange =
        unicodeScalars.index(after: firstIndex)..<variableListRange.upperBound
    } else if Self.isReservedURITemplateOperator(firstScalar.value) {
      throw URITemplateSourceDiagnostic(
        kind: .invalidOperator,
        sourceRange:
          firstIndex..<unicodeScalars.index(after: firstIndex)
      )
    }

    guard !variableListRange.isEmpty else {
      throw URITemplateSourceDiagnostic(
        kind: .emptyVariableSpecification,
        sourceRange:
          variableListRange.upperBound..<variableListRange.upperBound
      )
    }

    var variableLowerBound = variableListRange.lowerBound
    var index = variableListRange.lowerBound
    while true {
      if index == variableListRange.upperBound
        || unicodeScalars[index].value == 0x2C
      {
        guard variableLowerBound < index else {
          throw URITemplateSourceDiagnostic(
            kind: .emptyVariableSpecification,
            sourceRange: index..<index
          )
        }
        try validateURITemplateVariableSpecification(
          in: variableLowerBound..<index
        )
        guard index < variableListRange.upperBound else {
          return
        }
        index = unicodeScalars.index(after: index)
        variableLowerBound = index
      } else {
        index = unicodeScalars.index(after: index)
      }
    }
  }

  internal func validateURITemplateVariableSpecification(
    in sourceRange: Range<Index>
  ) throws {
    let scalarView = unicodeScalars
    var nameRange = sourceRange
    var index = sourceRange.lowerBound
    var starIndex: Index?
    var colonIndex: Index?

    while index < sourceRange.upperBound {
      switch scalarView[index].value {
      case 0x2A:
        starIndex = starIndex ?? index
      case 0x3A:
        colonIndex = colonIndex ?? index
      default:
        break
      }
      index = scalarView.index(after: index)
    }

    if let starIndex {
      let afterStar = scalarView.index(after: starIndex)
      guard
        afterStar == sourceRange.upperBound,
        colonIndex == nil
      else {
        let modifierLowerBound = colonIndex ?? starIndex
        throw URITemplateSourceDiagnostic(
          kind: .invalidModifier,
          sourceRange: modifierLowerBound..<sourceRange.upperBound
        )
      }
      nameRange = sourceRange.lowerBound..<starIndex
    } else if let colonIndex {
      let modifierRange = colonIndex..<sourceRange.upperBound
      guard validPrefixModifier(in: modifierRange) else {
        throw URITemplateSourceDiagnostic(
          kind: .invalidModifier,
          sourceRange: modifierRange
        )
      }
      nameRange = sourceRange.lowerBound..<colonIndex
    }

    guard !nameRange.isEmpty else {
      throw URITemplateSourceDiagnostic(
        kind: .emptyVariableSpecification,
        sourceRange: nameRange
      )
    }
    try validateURITemplateVariableName(in: nameRange)
  }

  internal func validateURITemplateVariableName(
    in sourceRange: Range<Index>
  ) throws {
    let scalarView = unicodeScalars
    var index = sourceRange.lowerBound
    var segmentContainsValue = false

    while index < sourceRange.upperBound {
      let scalar = scalarView[index]
      switch scalar.value {
      case 0x25:
        guard
          let endIndex = percentEncodedTripletEnd(
            startingAt: index,
            before: sourceRange.upperBound
          )
        else {
          throw URITemplateSourceDiagnostic(
            kind: .malformedPercentEncoding,
            sourceRange: malformedPercentRange(
              startingAt: index,
              before: sourceRange.upperBound
            )
          )
        }
        segmentContainsValue = true
        index = endIndex
      case 0x2E:
        guard segmentContainsValue else {
          throw URITemplateSourceDiagnostic(
            kind: .invalidVariableName,
            sourceRange: index..<scalarView.index(after: index)
          )
        }
        segmentContainsValue = false
        index = scalarView.index(after: index)
      case 0x30...0x39, 0x41...0x5A, 0x5F, 0x61...0x7A:
        segmentContainsValue = true
        index = scalarView.index(after: index)
      default:
        throw URITemplateSourceDiagnostic(
          kind: .invalidVariableName,
          sourceRange: index..<scalarView.index(after: index)
        )
      }
    }

    guard segmentContainsValue else {
      let lastIndex = scalarView.index(before: sourceRange.upperBound)
      throw URITemplateSourceDiagnostic(
        kind: .invalidVariableName,
        sourceRange: lastIndex..<sourceRange.upperBound
      )
    }
  }

  internal func validPrefixModifier(
    in sourceRange: Range<Index>
  ) -> Bool {
    let scalarView = unicodeScalars
    var index = scalarView.index(after: sourceRange.lowerBound)
    guard index < sourceRange.upperBound else {
      return false
    }

    let firstValue = scalarView[index].value
    guard (0x31...0x39).contains(firstValue) else {
      return false
    }

    var digitCount = 1
    index = scalarView.index(after: index)
    while index < sourceRange.upperBound {
      guard
        digitCount < 4,
        (0x30...0x39).contains(scalarView[index].value)
      else {
        return false
      }
      digitCount += 1
      index = scalarView.index(after: index)
    }
    return true
  }

  internal func percentEncodedTripletEnd(
    startingAt percentIndex: Index,
    before upperBound: Index
  ) -> Index? {
    let scalarView = unicodeScalars
    let firstHexIndex = scalarView.index(after: percentIndex)
    guard
      firstHexIndex < upperBound,
      Self.isASCIIHexDigit(scalarView[firstHexIndex].value)
    else {
      return nil
    }
    let secondHexIndex = scalarView.index(after: firstHexIndex)
    guard
      secondHexIndex < upperBound,
      Self.isASCIIHexDigit(scalarView[secondHexIndex].value)
    else {
      return nil
    }
    return scalarView.index(after: secondHexIndex)
  }

  internal func malformedPercentRange(
    startingAt percentIndex: Index,
    before upperBound: Index
  ) -> Range<Index> {
    let scalarView = unicodeScalars
    var endIndex = percentIndex
    for _ in 0..<3 where endIndex < upperBound {
      endIndex = scalarView.index(after: endIndex)
    }
    return percentIndex..<endIndex
  }

  internal static func isASCIIHexDigit(_ value: UInt32) -> Bool {
    switch value {
    case 0x30...0x39, 0x41...0x46, 0x61...0x66:
      true
    default:
      false
    }
  }

  internal static func isSupportedURITemplateOperator(
    _ value: UInt32
  ) -> Bool {
    switch value {
    case 0x23, 0x26, 0x2B, 0x2E, 0x2F, 0x3B, 0x3F:
      true
    default:
      false
    }
  }

  internal static func isReservedURITemplateOperator(
    _ value: UInt32
  ) -> Bool {
    switch value {
    case 0x21, 0x3D, 0x40, 0x7C:
      true
    default:
      false
    }
  }

  internal static func isAllowedURITemplateLiteralScalar(
    _ value: UInt32
  ) -> Bool {
    switch value {
    case 0x21,
      0x23...0x24,
      0x26...0x3B,
      0x3D,
      0x3F...0x5B,
      0x5D,
      0x5F,
      0x61...0x7A,
      0x7E,
      0xA0...0xD7FF,
      0xE000...0xF8FF,
      0xF900...0xFDCF,
      0xFDF0...0xFFEF,
      0x10000...0x1FFFD,
      0x20000...0x2FFFD,
      0x30000...0x3FFFD,
      0x40000...0x4FFFD,
      0x50000...0x5FFFD,
      0x60000...0x6FFFD,
      0x70000...0x7FFFD,
      0x80000...0x8FFFD,
      0x90000...0x9FFFD,
      0xA0000...0xAFFFD,
      0xB0000...0xBFFFD,
      0xC0000...0xCFFFD,
      0xD0000...0xDFFFD,
      0xE1000...0xEFFFD,
      0xF0000...0xFFFFD,
      0x100000...0x10FFFD:
      true
    default:
      false
    }
  }
}
