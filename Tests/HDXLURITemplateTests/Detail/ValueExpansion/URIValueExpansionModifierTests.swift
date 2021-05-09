//
//  URIValueExpansionModifierTests.swift
//

import Foundation
import XCTest
import HDXLAlgebraicUtilities
import HDXLTestingUtilities
@testable import HDXLURITemplate

class URIValueExpansionModifierTests : XCTestCase {
  
  // big array and don't want to keep re-constructing it each time:
  let probes = URIValueExpansionModifier.allCases
  
  lazy var reducedProbes: URIValueExpansionModifier.AllCases = Array(self.probes[0..<25])
  
  func testAllCasesOrdering() {
    XCTAssertTrue(self.probes.isOrderedStrictlyAscending)
  }
  
  func testFixtureValidity() {
    self.haltingOnFirstError {
      self.probes.forEach() {
        XCTAssertTrue($0.isValid)
      }
    }
  }
  
  func testCaseIterableCompleteness() {
    XCTAssertEqual(
      self.probes.count,
      2 + URIValueExpansionModifier.rangeOfValidPrefixCodePointCounts.count
    )
    XCTAssertTrue(
      self.probes.contains(
        .unmodified
      )
    )
    XCTAssertTrue(
      self.probes.contains(
        .explode
      )
    )
    self.haltingOnFirstError {
      for codePointCount in URIValueExpansionModifier.rangeOfValidPrefixCodePointCounts {
        XCTAssertTrue(
          self.probes.contains(
            .prefix(codePointCount)
          )
        )
      }
    }
  }
  
  func testEqualityCoherence() {
    HDXLAssertCoherentOrdering(
      forAscendingDistinctValues: self.reducedProbes
    )
  }
  
  func testOrderingCoherence() {
    HDXLAssertCoherentOrdering(
      forAscendingDistinctValues: self.reducedProbes
    )
  }
  
  func testDistinctValues() {
    HDXLAssertPairwiseDistinctElements(
      self.probes
    )
    HDXLAssertPairwiseDistinctElements(
      URIValueExpansionModifier.allCases.map() { $0.description }
    )
    HDXLAssertPairwiseDistinctElements(
      URIValueExpansionModifier.allCases.map() { $0.debugDescription }
    )
    HDXLAssertPairwiseDistinctElements(
      URIValueExpansionModifier.allCases.map() { $0.templateRepresentation }
    )
  }
  
  func testCodableRoundTrip() {
    HDXLAssertCodableRoundTrip(
      URIValueExpansionModifier.allCases
    )
  }
  
  func testInterpretationUtilities() {
    self.haltingOnFirstError {
      for probe in probes {
        switch probe {
        case .unmodified:
          XCTAssertFalse(probe.requiresAction)
          XCTAssertTrue(probe.isUnmodifiedType)
          XCTAssertFalse(probe.isExplodeType)
          XCTAssertFalse(probe.isPrefixType)
          XCTAssertEqual(
            probe.modifierType,
            .unmodified
          )
        case .explode:
          XCTAssertTrue(probe.requiresAction)
          XCTAssertFalse(probe.isUnmodifiedType)
          XCTAssertTrue(probe.isExplodeType)
          XCTAssertFalse(probe.isPrefixType)
          XCTAssertEqual(
            probe.modifierType,
            .explode
          )
        case .prefix(_):
          XCTAssertTrue(probe.requiresAction)
          XCTAssertFalse(probe.isUnmodifiedType)
          XCTAssertFalse(probe.isExplodeType)
          XCTAssertTrue(probe.isPrefixType)
          XCTAssertEqual(
            probe.modifierType,
            .prefix
          )
        }
      }
    }
  }
  
}
