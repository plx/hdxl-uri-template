//
//  URITemplateVariableTests.swift
//

import Foundation
import XCTest
import HDXLAlgebraicUtilities
import HDXLTestingUtilities
@testable import HDXLURITemplate

class URITemplateVariableTests : XCTestCase {
  
  lazy var probeStrings: [String] = [
    "a",
    "ab",
    "abc",
    "abcde"
  ]
  
  lazy var probes: [URITemplateVariable] =
    CartesianProduct(
      self.probeStrings,
      URIValueExpansionModifier.allCases[0...10]
    )
    .asTuples()
    .map() {
    URITemplateVariable(
      variableName: URITemplateVariableName(storage: $0),
      expansionModifier: $1
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
  
  func testTemplateRepresentationDistinctness() {
    self.haltingOnFirstError {
      HDXLAssertPairwiseDistinctElements(
        self.probes.map() {
          $0.templateRepresentation
        }
      )
    }
  }
  
  func testCodableRoundTrips() {
    HDXLAssertCodableRoundTrip(
      self.probes
    )
  }
  
}
