//
//  StringURITemplatePrefixManipulationTests.swift
//

import Foundation
import XCTest
import HDXLCommonUtilities
import HDXLTestingUtilities
import HDXLAlgebraicUtilities
@testable import HDXLURITemplate

class StringURITemplatePrefixManipulationTests : XCTestCase {
  
  func testDegenerateScenarios() {
    // all empty
    self.checkRemoval(
      ofPrefix: "",
      from: "",
      yields: ""
    )
    // empty-prefix
    self.checkRemoval(
      ofPrefix: "",
      from: "a",
      yields: "a"
    )
    self.checkRemoval(
      ofPrefix: "",
      from: "abc",
      yields: "abc"
    )
    
    // empty-target
    self.checkRemoval(
      ofPrefix: "ab",
      from: "",
      yields: ""
    )
    self.checkRemoval(
      ofPrefix: "abc",
      from: "",
      yields: ""
    )
  }
  
  func testCannedExamples() {
    self.checkRemoval(
      ofPrefix: "?",
      from: "?foo",
      yields: "foo"
    )
    self.checkRemoval(
      ofPrefix: "?",
      from: "??foo",
      yields: "?foo"
    )
    self.checkRemoval(
      ofPrefix: "??",
      from: "??foo",
      yields: "foo"
    )
    self.checkRemoval(
      ofPrefix: "?",
      from: "?foo?",
      yields: "foo?"
    )
    self.checkRemoval(
      ofPrefix: "?",
      from: "foo?",
      yields: "foo?"
    )
  }
  
  func testProgrammaticMixtureOfCases() {
    // note use of non-overlapping character sets to ensure not prefixes:
    let prefixes: [String] = ["a", "b", "c", "ab", "ac", "bc", "abc"]
    let targets: [String] = ["x", "y", "z", "xy", "xz", "yz", "xyz"]
    self.haltingOnFirstError {
      for (prefix,target) in CartesianProduct(prefixes,targets).asTuples() {
        // verify it's not a prefix:
        XCTAssertFalse(target.hasPrefix(prefix))
        // this should thus be a no-op:
        self.checkRemoval(
          ofPrefix: prefix,
          from: target,
          yields: target
        )
        // this, too, should thus be a no-op:
        XCTAssertFalse((target + prefix).hasPrefix(prefix))
        self.checkRemoval(
          ofPrefix: prefix,
          from: (target + prefix),
          yields: (target + prefix)
        )
        // whereas this *will* remove the unwanted prefix:
        XCTAssertTrue((prefix+target).hasPrefix(prefix))
        self.checkRemoval(
          ofPrefix: prefix,
          from: (prefix + target),
          yields: target
        )
      }
    }
  }
  
}

fileprivate extension StringURITemplatePrefixManipulationTests {
  
  func checkRemoval(
    ofPrefix prefix: String,
    from target: String,
    yields expectation: String) {
    let result = target.conditionallyRemoving(
      prefix: prefix
    )
    XCTAssertEqual(
      result,
      expectation,
      """
      Expected `"\(target)".conditionallyRemoving(prefix: "\(prefix)") == "\(expectation)"`, but got "\(result)" instead!
      """
    )
    let mutableResult = target.mutated() {
      $0.conditionallyRemove(prefix: prefix)
    }
    XCTAssertEqual(
      expectation,
      mutableResult,
      """
      Got unexpected mutable/immutable discrepancy when removing "\(prefix)" from "\(target)": immutable got "\(result)", mutable got "\(mutableResult)", and we expected "\(expectation)"!
      """
    )
  }
  
}
