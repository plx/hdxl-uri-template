//
//  URIVariableListValueTests.swift
//

import Foundation
import XCTest
import HDXLAlgebraicUtilities
import HDXLTestingUtilities
@testable import HDXLURITemplate

class URIVariableListValueTests : XCTestCase {
  
  lazy var probeStrings: [String] = [
    "",
    "a",
    "ab",
    "abc",
    "abcd",
    "abcde",
    "abcdef",
    "abcdefg"
  ]
  
  lazy var probes: [URIVariableListValue] = self.probeStrings
    .smallPowerSet()
    .map() {
      (strings: [String]) -> URIVariableListValue
      in
      URIVariableListValue(
        values: strings.map() {
          URIVariableTextValue(text: $0)
        }
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

  func testIsEmptyCoherence() {
    self.haltingOnFirstError {
      for probe in self.probes {
        XCTAssertEqual(
          probe.isEmpty,
          probe.storage.isEmpty
        )
        XCTAssertEqual(
          probe.isEmpty,
          probe.count == 0
        )
      }
    }
  }

  func testCountCoherence() {
    self.haltingOnFirstError {
      for probe in self.probes {
        XCTAssertEqual(
          probe.count,
          probe.storage.count
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
