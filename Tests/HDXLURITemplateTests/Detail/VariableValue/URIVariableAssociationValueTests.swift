//
//  URIVariableAssociationValueTests.swift
//

import Foundation
import XCTest
import HDXLAlgebraicUtilities
import HDXLTestingUtilities
@testable import HDXLURITemplate

class URIVariableAssociationValueTests : XCTestCase {
  
  let keys: [URIVariableTextValue] = [
    "a",
    "ab",
    "abc"
    ].map() {
      URIVariableTextValue(text: $0)
  }
  
  let values: [URIVariableTextValue] = [
    "m",
    "mn",
    "mno"
    ].map() {
      URIVariableTextValue(text: $0)
  }
  
  lazy var pairs: [URIVariablePairValue] = CartesianProduct(self.keys,self.values)
    .asTuples()
    .map() {
      URIVariablePairValue(
        key: $0,
        value: $1
      )
    }.dropLast()

  lazy var probes: [URIVariableAssociationValue] = self.pairs
    .smallPowerSet()
    .map() {
      URIVariableAssociationValue(values: $0)
  }
  
  func testFixtureSetup() {
    XCTAssertTrue(self.keys.isOrderedStrictlyAscending)
    XCTAssertTrue(self.values.isOrderedStrictlyAscending)
    XCTAssertTrue(self.pairs.isOrderedStrictlyAscending)
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
