//
//  StringURITemplateSuffixManipulationTests.swift
//

import Foundation
import XCTest
@testable import HDXLURITemplate

class StringURITemplateSuffixManipulationTests : XCTestCase {
  
  func testDegenerateScenarios() {
    // all empty
    self.checkRemoval(
      ofSuffix: "",
      from: "",
      yields: ""
    )
    // empty-suffix
    self.checkRemoval(
      ofSuffix: "",
      from: "a",
      yields: "a"
    )
    self.checkRemoval(
      ofSuffix: "",
      from: "abc",
      yields: "abc"
    )
    
    // empty-target
    self.checkRemoval(
      ofSuffix: "ab",
      from: "",
      yields: ""
    )
    self.checkRemoval(
      ofSuffix: "abc",
      from: "",
      yields: ""
    )
  }
  
  func testCannedExamples() {
    self.checkRemoval(
      ofSuffix: "?",
      from: "foo?",
      yields: "foo"
    )
    self.checkRemoval(
      ofSuffix: "?",
      from: "foo??",
      yields: "foo?"
    )
    self.checkRemoval(
      ofSuffix: "??",
      from: "foo??",
      yields: "foo"
    )
    self.checkRemoval(
      ofSuffix: "?",
      from: "?foo?",
      yields: "?foo"
    )
    self.checkRemoval(
      ofSuffix: "?",
      from: "?foo",
      yields: "?foo"
    )
  }
  
  func testProgrammaticMixtureOfCases() {
    // note use of non-overlapping character sets to ensure not suffixes:
    let suffixes: [String] = ["a", "b", "c", "ab", "ac", "bc", "abc"]
    let targets: [String] = ["x", "y", "z", "xy", "xz", "yz", "xyz"]
    self.haltingOnFirstError {
      for (suffix,target) in CartesianProduct(suffixes,targets).asTuples() {
        // verify it's not a suffix:
        XCTAssertFalse(target.hasSuffix(suffix))
        // this should thus be a no-op:
        self.checkRemoval(
          ofSuffix: suffix,
          from: target,
          yields: target
        )
        // this, too, should thus be a no-op:
        XCTAssertFalse((suffix+target).hasSuffix(suffix))
        self.checkRemoval(
          ofSuffix: suffix,
          from: (suffix + target),
          yields: (suffix + target)
        )
        // whereas this *will* remove the unwanted suffix:
        XCTAssertTrue((target + suffix).hasSuffix(suffix))
        self.checkRemoval(
          ofSuffix: suffix,
          from: (target + suffix),
          yields: target
        )
      }
    }
  }
  
}

fileprivate extension StringURITemplateSuffixManipulationTests {
  
  func checkRemoval(
    ofSuffix suffix: String,
    from target: String,
    yields expectation: String) {
    let result = target.conditionallyRemoving(
      suffix: suffix
    )
    XCTAssertEqual(
      result,
      expectation,
      """
      Expected `"\(target)".conditionallyRemoving(suffix: "\(suffix)") == "\(expectation)"`, but got "\(result)" instead!
      """
    )
    let mutableResult = target.mutated() {
      $0.conditionallyRemove(suffix: suffix)
    }
    XCTAssertEqual(
      expectation,
      mutableResult,
      """
      Got unexpected mutable/immutable discrepancy when removing "\(suffix)" from "\(target)": immutable got "\(result)", mutable got "\(mutableResult)", and we expected "\(expectation)"!
      """
    )
  }
  
}
