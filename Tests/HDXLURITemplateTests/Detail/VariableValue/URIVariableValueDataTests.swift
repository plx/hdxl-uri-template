//
//  URIVariableValueDataTests.swift
//

import Foundation
import XCTest
import HDXLAlgebraicUtilities
import HDXLTestingUtilities
@testable import HDXLURITemplate

class URIVariableValueDataTests : XCTestCase {
  
  let undefined: [URIVariableValueData] = [.undefined]
  
  let texts: [URIVariableValueData] = [
    "a",
    "ab",
    "abc",
    "abcde",
    "abcdef"
    ].map() {
      .text(URIVariableTextValue(text: $0))
    }
  
  lazy var lists: [URIVariableValueData] = [
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
      .list(URIVariableListValue(values: $0))
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
  
  lazy var associations: [URIVariableValueData] = self.pairs
    .smallPowerSet()
    .map() {
      .association(URIVariableAssociationValue(values: $0))
  }
    
  lazy var probes: [URIVariableValueData] = ChainCollection(
    self.undefined,
    self.texts,
    self.lists,
    self.associations
  ).map({ $0 }) // <- pointless map to get to an array
  
  func testFixtureSetup() {
    XCTAssertTrue(self.texts.isOrderedStrictlyAscending)
    XCTAssertTrue(self.lists.isOrderedStrictlyAscending)
    XCTAssertTrue(self.associations.isOrderedStrictlyAscending)
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
  
  func testCaseOrderingAsExpected() {
    self.haltingOnFirstError {
      for (undefined,text) in CartesianProduct(self.undefined,self.texts).asTuples() {
        XCTAssertLessThan(undefined, text)
      }
      for (undefined,list) in CartesianProduct(self.undefined,self.lists).asTuples() {
        XCTAssertLessThan(undefined, list)
      }
      for (undefined,association) in CartesianProduct(self.undefined,self.associations).asTuples() {
        XCTAssertLessThan(undefined, association)
      }
      for (text,list) in CartesianProduct(self.texts,self.lists).asTuples() {
        XCTAssertLessThan(text,list)
      }
      for (text,association) in CartesianProduct(self.texts,self.associations).asTuples() {
        XCTAssertLessThan(text,association)
      }
      for (list,association) in CartesianProduct(self.lists,self.associations).asTuples() {
        XCTAssertLessThan(list,association)
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
