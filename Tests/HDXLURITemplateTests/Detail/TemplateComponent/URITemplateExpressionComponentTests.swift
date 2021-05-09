//
//  URITemplateExpressionComponentTests.swift
//

import Foundation
import XCTest
import HDXLAlgebraicUtilities
import HDXLTestingUtilities
@testable import HDXLURITemplate

class URITemplateExpressionComponentTests : XCTestCase {
  
  let probeStrings: [String] = [
    "a",
    "ab",
    "abc"
  ]
  
  lazy var variableNames: [URITemplateVariableName] = self
    .probeStrings
    .map() {
      URITemplateVariableName(storage: $0)
  }
  
  lazy var variableSubsets: [[URITemplateVariable]] =
    CartesianProduct(
      self.variableNames.smallPowerSet(),
      URIValueExpansionModifier.allCases[0..<5]
    )
      .asTuples()
      .map() {
        (names,modifier)
        in
        names.map() {
          URITemplateVariable(
            variableName: $0,
            expansionModifier: modifier
          )
        }
      }
    .sorted() {
      $0.lexicographicallyPrecedes($1)
    }

  lazy var probes: [URITemplateExpressionComponent] =
    CartesianProduct(
      URIValueExpansionType.allCases,
      self.variableSubsets
    )
      .asTuples()
      .map() {
        URITemplateExpressionComponent(
          expansionType: $0,
          variables: $1
        )
  }
  
  func testFixtureSetup() {
    XCTAssertTrue(self.probeStrings.isOrderedStrictlyAscending)
    XCTAssertTrue(self.variableNames.isOrderedStrictlyAscending)
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
