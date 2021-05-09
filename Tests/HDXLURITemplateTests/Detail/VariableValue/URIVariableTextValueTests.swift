//
//  URIVariableTextValueTests.swift
//

import Foundation
import XCTest
import HDXLAlgebraicUtilities
import HDXLTestingUtilities
@testable import HDXLURITemplate

class URIVariableTextValueTests : XCTestCase {
  
  lazy var probeStrings: [String] = [
    "",
    "a",
    "ab",
    "abc",
    "abcde"
  ]
  
  lazy var probes: [URIVariableTextValue] = self.probeStrings.map() {
    URIVariableTextValue(text: $0)
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

  func testIsEmptyCoherence() {
    self.haltingOnFirstError {
      for (ps,p) in zip(self.probeStrings,self.probes) {
        XCTAssertEqual(
          ps.isEmpty,
          p.isEmpty
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
