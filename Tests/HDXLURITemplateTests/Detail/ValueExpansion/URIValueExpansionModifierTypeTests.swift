//
//  URIValueExpansionModifierTypeTests.swift
//

import Foundation
import XCTest
import HDXLAlgebraicUtilities
import HDXLTestingUtilities
@testable import HDXLURITemplate

class URIValueExpansionModifierTypeTests : XCTestCase {
  
  func testAllCasesOrdering() {
    XCTAssertTrue(URIValueExpansionModifierType.allCases.isOrderedStrictlyAscending)
  }
  
  func testCaseIterableCompleteness() {
    XCTAssertEqual(
      URIValueExpansionModifierType.allCases.count,
      3
    )
    XCTAssertTrue(
      URIValueExpansionModifierType.allCases.contains(
        .unmodified
      )
    )
    XCTAssertTrue(
      URIValueExpansionModifierType.allCases.contains(
        .explode
      )
    )
    XCTAssertTrue(
      URIValueExpansionModifierType.allCases.contains(
        .prefix
      )
    )
  }
  
  func testEqualityCoherence() {
    HDXLAssertCoherentOrdering(
      forAscendingDistinctValues: URIValueExpansionModifierType.allCases
    )
  }
  
  func testOrderingCoherence() {
    HDXLAssertCoherentOrdering(
      forAscendingDistinctValues: URIValueExpansionModifierType.allCases
    )
  }
  
  func testDistinctValues() {
    HDXLAssertPairwiseDistinctElements(
      URIValueExpansionModifierType.allCases
    )
    HDXLAssertPairwiseDistinctElements(
      URIValueExpansionModifierType.allCases.map() { $0.description }
    )
    HDXLAssertPairwiseDistinctElements(
      URIValueExpansionModifierType.allCases.map() { $0.debugDescription }
    )
  }
  
  func testCodableRoundTrip() {
    HDXLAssertCodableRoundTrip(
      URIValueExpansionModifierType.allCases
    )
  }
  
}
