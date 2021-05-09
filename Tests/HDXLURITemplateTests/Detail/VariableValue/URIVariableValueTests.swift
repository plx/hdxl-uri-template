//
//  URIVariableValueTests.swift
//

import Foundation
import XCTest
import HDXLAlgebraicUtilities
import HDXLTestingUtilities
@testable import HDXLURITemplate

class URIVariableValueTests : XCTestCase {
  
  let undefined: [URIVariableValue] = [.undefined]
  
  let texts: [URIVariableValue] = [
    "a",
    "ab",
    "abc",
    "abcde",
    "abcdef"
    ].map() {
      URIVariableValue(
        storage: .text(URIVariableTextValue(text: $0))
      )
  }
  
  lazy var lists: [URIVariableValue] = [
    "a",
    "ab",
    "abc",
    "abcde",
    "abcdef"
    ].map() {
      URIVariableTextValue(text: $0)
  }
  .smallPowerSet()
  .map() {
    URIVariableValue(
      storage: .list(URIVariableListValue(values: $0))
    )
  }
  
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
  
  lazy var associations: [URIVariableValue] = self.pairs
    .smallPowerSet()
    .map() {
      URIVariableValue(
        storage: .association(URIVariableAssociationValue(values: $0))
      )
  }
  
  lazy var probes: [URIVariableValue] = ChainCollection(
    self.undefined,
    self.texts,
    self.lists,
    self.associations
  ).map({ $0 }) // <- pointless map to get to an array
    
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
  
  func testCharacterizationWorksOK() {
    self.haltingOnFirstError {
      for probe in self.probes {
        XCTAssertEqual(
          probe.isUndefined,
          !probe.isDefined
        )
        XCTAssertEqual(
          probe.isUndefined,
          probe.isUndefinedValue
        )
        XCTAssertEqual(
          probe.isUndefined,
          self.undefined.contains(probe)
        )
        XCTAssertEqual(
          probe.isDefined,
          !self.undefined.contains(probe)
        )
        XCTAssertEqual(
          probe.isTextValue,
          self.texts.contains(probe)
        )
        XCTAssertEqual(
          probe.isListValue,
          self.lists.contains(probe)
        )
        XCTAssertEqual(
          probe.isAssociationValue,
          self.associations.contains(probe)
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
