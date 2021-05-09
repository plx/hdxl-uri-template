//
//  URIValueExpansionTypeTests.swift
//

import Foundation
import XCTest
import HDXLAlgebraicUtilities
import HDXLTestingUtilities
@testable import HDXLURITemplate

class URIValueExpansionTypeTests : XCTestCase {
  
  func testAllCasesOrdering() {
    XCTAssertTrue(URIValueExpansionType.allCases.isOrderedStrictlyAscending)
  }
  
  func testCaseIterableCompleteness() {
    XCTAssertEqual(
      URIValueExpansionType.allCases.count,
      8
    )
    XCTAssertTrue(
      URIValueExpansionType.allCases.contains(
        .simple
      )
    )
    XCTAssertTrue(
      URIValueExpansionType.allCases.contains(
        .reserved
      )
    )
    XCTAssertTrue(
      URIValueExpansionType.allCases.contains(
        .fragment
      )
    )
    XCTAssertTrue(
      URIValueExpansionType.allCases.contains(
        .label
      )
    )
    XCTAssertTrue(
      URIValueExpansionType.allCases.contains(
        .pathSegment
      )
    )
    XCTAssertTrue(
      URIValueExpansionType.allCases.contains(
        .pathParameter
      )
    )
    XCTAssertTrue(
      URIValueExpansionType.allCases.contains(
        .query
      )
    )
    XCTAssertTrue(
      URIValueExpansionType.allCases.contains(
        .queryContinuation
      )
    )
  }
  
  func testEqualityCoherence() {
    HDXLAssertCoherentOrdering(
      forAscendingDistinctValues: URIValueExpansionType.allCases
    )
  }
  
  func testOrderingCoherence() {
    HDXLAssertCoherentOrdering(
      forAscendingDistinctValues: URIValueExpansionType.allCases
    )
  }
  
  func testDistinctValues() {
    HDXLAssertPairwiseDistinctElements(
      URIValueExpansionType.allCases
    )
    HDXLAssertPairwiseDistinctElements(
      URIValueExpansionType.allCases.map() { $0.description }
    )
    HDXLAssertPairwiseDistinctElements(
      URIValueExpansionType.allCases.map() { $0.debugDescription }
    )
    HDXLAssertPairwiseDistinctElements(
      URIValueExpansionType.allCases.map() { $0.formatString }
    )
  }
  
  func testCodableRoundTrip() {
    HDXLAssertCodableRoundTrip(
      URIValueExpansionType.allCases
    )
  }
  
  func testFormatStringRoundTrip() throws {
    for probe in URIValueExpansionType.allCases {
      XCTAssertEqual(
        probe,
        try XCTUnwrap(
          URIValueExpansionType(formatString: probe.formatString)
        )
      )
    }
  }
  
  func testInvalidFormatStringGetsNil() {
    XCTAssertNil(
      URIValueExpansionType(formatString: "foobar")
    )
  }
  
}
