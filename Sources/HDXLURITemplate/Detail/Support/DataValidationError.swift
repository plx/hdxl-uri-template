//
//  DataValidationError.swift
//

import Foundation
import HDXLCommonUtilities

// -------------------------------------------------------------------------- //
// MARK: DataValidationError - Definition
// -------------------------------------------------------------------------- //

/// Error to throw when a `Validatable` is initialized with invalid data.
/// Intended use is e.g. to throw if a `Codable` implementation deserializes
/// invalid data--it should provide a chance to recover automatically.
///
/// Will likely get moved into `HDXLCommonUtilities` if it proves general-enough.
///
/// It's *modeled* on the `LocalizableError` protocol but *doesn't conform to it*,
/// because `LocalizableError` is for errors that *can* be presented to the user
/// (e.g. "Abort/Retry/Fail", but with better UX). This is aimed at (1) giving code
/// enough information to log the issue for investigation and (2) providing probable
/// good-enough repairs *whenever* such a value can be provided.
///
/// For example, a type with semantics like "value in [0, 1]" could conceivably
/// repair non-nan/infinte values by clipping them to that bound (while still
/// failing unconditionally on nan/inf)...whereas a non-empty string newtype might
/// just fail, b/c there's no obvious choice of a default non-empty string.
public struct DataValidationError<T> : Error {
  
  @usableFromInline
  internal var _repairSuggestion: T?
  
  @inlinable
  public var repairSuggestion: T? {
    get {
      return self._repairSuggestion
    }
  }
  
  @usableFromInline
  internal var _problemDescription: String?

  @usableFromInline
  internal var _repairDescription: String?
  
  @inlinable
  internal init(
    forType type: T.Type,
    problemDescription: String? = nil,
    repairDescription: String? = nil,
    repairSuggestion: T? = nil) {
    self._problemDescription = problemDescription
    self._repairDescription = repairDescription
    self._repairSuggestion = repairSuggestion
  }
  
}


