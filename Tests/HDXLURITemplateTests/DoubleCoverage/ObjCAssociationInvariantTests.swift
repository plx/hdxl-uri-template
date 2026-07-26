import Foundation
import HDXLURITemplateObjCInterop
import Testing

@testable import HDXLURITemplate

@Test("A real Objective-C caller receives controlled association errors")
private func objectiveCAssociationConstructionIsControlled() throws {
  let duplicateError = try #require(
    HDXLObjCDuplicateAssociationConstructionError()
  ) as NSError
  #expect(
    duplicateError.domain
      == URIVariableValue.AssociationError.errorDomain
  )
  #expect(duplicateError.code == 1)
  #expect(
    duplicateError.userInfo[
      "HDXLURITemplateFirstAssociationKeyIndex"
    ] as? Int == 0
  )
  #expect(
    duplicateError.userInfo[
      "HDXLURITemplateDuplicateAssociationKeyIndex"
    ] as? Int == 1
  )
  let duplicateDiagnostic = duplicateError.description
    + duplicateError.userInfo.description
  #expect(!duplicateDiagnostic.contains("private"))

  let mismatchError = try #require(
    HDXLObjCMismatchedAssociationConstructionError()
  ) as NSError
  expectAssociationCountMismatch(
    mismatchError,
    keyCount: 1,
    valueCount: 0
  )

  let reverseMismatchError = try #require(
    HDXLObjCReverseMismatchedAssociationConstructionError()
  ) as NSError
  expectAssociationCountMismatch(
    reverseMismatchError,
    keyCount: 0,
    valueCount: 1
  )
}

@Test("A real Objective-C caller preserves valid association behavior")
private func objectiveCAssociationBehaviorRemainsOrderedAndTotal() throws {
  #expect(
    HDXLObjCValidAssociationEnumeration()
      == ["b=2:0", "a=1:1"]
  )
  #expect(
    HDXLObjCValidAssociationDictionary()
      == ["a": "1", "b": "2"]
  )
  #expect(HDXLObjCAssociationEnumerationStopsEarly())
  #expect(HDXLObjCAssociationSecureCodingRoundTrips())
}

private func expectAssociationCountMismatch(
  _ error: NSError,
  keyCount: Int,
  valueCount: Int
) {
  #expect(
    error.domain
      == URIVariableValue.AssociationError.errorDomain
  )
  #expect(error.code == 2)
  #expect(
    error.userInfo[
      "HDXLURITemplateAssociationKeyCount"
    ] as? Int == keyCount
  )
  #expect(
    error.userInfo[
      "HDXLURITemplateAssociationValueCount"
    ] as? Int == valueCount
  )
  let diagnostic = error.description
    + error.userInfo.description
  #expect(!diagnostic.contains("private"))
}
