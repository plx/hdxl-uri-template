//
//  URITemplateComponentTypeTests.swift
//

import Foundation
import XCTest
import HDXLAlgebraicUtilities
import HDXLTestingUtilities
@testable import HDXLURITemplate

class URITemplateComponentTypeTests : XCTestCase {
  
  func testAllCasesOrdering() {
    XCTAssertTrue(URITemplateComponentType.allCases.isOrderedStrictlyAscending)
  }
  
  func testCaseIterableCompleteness() {
    XCTAssertEqual(
      URITemplateComponentType.allCases.count,
      2
    )
    XCTAssertTrue(
      URITemplateComponentType.allCases.contains(
        .literal
      )
    )
    XCTAssertTrue(
      URITemplateComponentType.allCases.contains(
        .expression
      )
    )
  }
  
  func testEqualityCoherence() {
    HDXLAssertCoherentOrdering(
      forAscendingDistinctValues: URITemplateComponentType.allCases
    )
  }
  
  func testOrderingCoherence() {
    HDXLAssertCoherentOrdering(
      forAscendingDistinctValues: URITemplateComponentType.allCases
    )
  }
  
  func testDistinctValues() {
    HDXLAssertPairwiseDistinctElements(
      URITemplateComponentType.allCases
    )
    HDXLAssertPairwiseDistinctElements(
      URITemplateComponentType.allCases.map() { $0.description }
    )
    HDXLAssertPairwiseDistinctElements(
      URITemplateComponentType.allCases.map() { $0.debugDescription }
    )
  }
  
  func testCodableRoundTrip() {
    HDXLAssertCodableRoundTrip(
      URITemplateComponentType.allCases
    )
  }
  
}
