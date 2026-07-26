import Foundation

extension URIVariableValue {

  /// A controlled failure encountered while constructing an association value.
  ///
  /// The error reports only positions or counts. It intentionally omits keys
  /// and values so diagnostics cannot expose caller-provided association data.
  public enum AssociationError: Error, Equatable, Sendable {

    /// A key at `duplicateIndex` compares equal to the key at `firstIndex`.
    case duplicateKey(
      firstIndex: Int,
      duplicateIndex: Int
    )

    /// Parallel key and value collections contain different numbers of items.
    case mismatchedKeyValueCounts(
      keyCount: Int,
      valueCount: Int
    )
  }
}

extension URIVariableValue.AssociationError: CustomNSError {

  public static var errorDomain: String {
    "HDXLURITemplate.URIVariableValue.AssociationError"
  }

  public var errorCode: Int {
    switch self {
    case .duplicateKey:
      1
    case .mismatchedKeyValueCounts:
      2
    }
  }

  public var errorUserInfo: [String: Any] {
    switch self {
    case .duplicateKey(let firstIndex, let duplicateIndex):
      [
        NSLocalizedDescriptionKey:
          "Association keys must be unique.",
        "HDXLURITemplateFirstAssociationKeyIndex": firstIndex,
        "HDXLURITemplateDuplicateAssociationKeyIndex": duplicateIndex
      ]
    case .mismatchedKeyValueCounts(let keyCount, let valueCount):
      [
        NSLocalizedDescriptionKey:
          "Association key and value collections must have equal counts.",
        "HDXLURITemplateAssociationKeyCount": keyCount,
        "HDXLURITemplateAssociationValueCount": valueCount
      ]
    }
  }
}
