//
//  URIVariableValueTypeTests.swift
//

import Foundation
import XCTest
import HDXLAlgebraicUtilities
import HDXLTestingUtilities
@testable import HDXLURITemplate

class URIVariableValueTypeTests : XCTestCase {
  
  func testAllCasesOrdering() {
    XCTAssertTrue(URIVariableValueType.allCases.isOrderedStrictlyAscending)
  }
  
  func testCaseIterableCompleteness() {
    XCTAssertEqual(
      URIVariableValueType.allCases.count,
      4
    )
    XCTAssertTrue(
      URIVariableValueType.allCases.contains(
        .undefined
      )
    )
    XCTAssertTrue(
      URIVariableValueType.allCases.contains(
        .text
      )
    )
    XCTAssertTrue(
      URIVariableValueType.allCases.contains(
        .list
      )
    )
    XCTAssertTrue(
      URIVariableValueType.allCases.contains(
        .association
      )
    )
  }
  
  func testEqualityCoherence() {
    HDXLAssertCoherentOrdering(
      forAscendingDistinctValues: URIVariableValueType.allCases
    )
  }
  
  func testOrderingCoherence() {
    HDXLAssertCoherentOrdering(
      forAscendingDistinctValues: URIVariableValueType.allCases
    )
  }
  
  func testDistinctValues() {
    HDXLAssertPairwiseDistinctElements(
      URIVariableValueType.allCases
    )
    HDXLAssertPairwiseDistinctElements(
      URIVariableValueType.allCases.map() { $0.description }
    )
    HDXLAssertPairwiseDistinctElements(
      URIVariableValueType.allCases.map() { $0.debugDescription }
    )
  }
  
  func testCodableRoundTrip() {
    HDXLAssertCodableRoundTrip(
      URIVariableValueType.allCases
    )
  }
  
}
