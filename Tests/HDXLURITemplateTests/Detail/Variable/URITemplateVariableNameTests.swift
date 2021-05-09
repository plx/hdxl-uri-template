//
//  URITemplateVariableNameTests.swift
//

import Foundation
import XCTest
import HDXLAlgebraicUtilities
import HDXLTestingUtilities
@testable import HDXLURITemplate

class URITemplateVariableNameTests : XCTestCase {
  
  lazy var probeStrings: [String] = [
    "a",
    "ab",
    "abc",
    "abcde"
  ]
  
  lazy var probes: [URITemplateVariableName] = self.probeStrings.map() {
    URITemplateVariableName(storage: $0)
  }
  
  func testAAARegularExpressionCompiles() {
    XCTAssertNoThrow(
      try URITemplateVariableName.prepareValidationRegularExpression()
    )
  }
  
  func testFixtureSetup() {
    XCTAssertTrue(self.probeStrings.isOrderedStrictlyAscending)
    XCTAssertTrue(self.probes.isOrderedStrictlyAscending)
  }
  
  func testProbesPassValidation() {
    self.haltingOnFirstError {
      for probe in self.probes {
        XCTAssertTrue(
          probe.isValid,
          "Unexpectedly got invalid `probe`: \(probe.debugDescription)"
        )
      }
    }
  }
  
  func testProbeDistinctness() {
    HDXLAssertPairwiseDistinctElements(
      self.probes
    )
  }
  
  func testEqualityCoherence() {
    HDXLAssertCoherentEquality(
      forDistinctValues: self.probes
    )
  }
  
  func testOrderingCoherence() {
    HDXLAssertCoherentOrdering(
      forAscendingDistinctValues: self.probes
    )
  }
  
  func testDescriptionDistinctness() {
    HDXLAssertPairwiseDistinctElements(
      self.probes.map() {
        $0.description
        
      }
    )
  }
  
  func testDebugDescriptionDistinctness() {
    HDXLAssertPairwiseDistinctElements(
      self.probes.map() {
        $0.debugDescription
      }
    )
  }
  
  func testDescriptionDebugDescriptionDifferent() {
    self.haltingOnFirstError {
      for probe in self.probes {
        XCTAssertNotEqual(
          probe.description,
          probe.debugDescription
        )
      }
    }
  }
  
  func testCodableRoundTrips() {
    HDXLAssertCodableRoundTrip(
      self.probes
    )
  }
  
}
