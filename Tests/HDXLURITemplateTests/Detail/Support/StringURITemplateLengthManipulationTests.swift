//
//  StringURITemplateLengthManipulationTests.swift
//

import Foundation
import XCTest
@testable import HDXLURITemplate

class StringURITemplateLengthManipulationTests : XCTestCase {
  
  let probeStrings = ["", "a", "ab", "abc", "abcd", "abcde"]
  let probeLengths = 0...10
  
  func testProbeStringCodePointCounts() {
    self.haltingOnFirstError {
      for (expectedLength,probe) in self.probeStrings.enumerated() {
        XCTAssertEqual(
          expectedLength,
          probe.codePointCount
        )
      }
    }
  }
  
  func testDegenerateCodePointCountConstraint() {
    // check constraining empty string works:
    self.haltingOnFirstError {
      for length in self.probeLengths {
        XCTAssertEqual(
          "",
          "".constrained(toCodePointCount: length)
        )
      }
    }
    
    // check all strings => "" when constrained to length zero:
    self.haltingOnFirstError {
      for probe in self.probeStrings {
        XCTAssertEqual(
          "",
          probe.constrained(toCodePointCount: 0)
        )
      }
    }
  }
  
  func testCannedConstraintExamples() {
    self.check(
      constraining: "abcdef",
      toCodePointCount: 0,
      yields: ""
    )
    self.check(
      constraining: "abcdef",
      toCodePointCount: 1,
      yields: "a"
    )
    self.check(
      constraining: "abcdef",
      toCodePointCount: 2,
      yields: "ab"
    )
    self.check(
      constraining: "abcdef",
      toCodePointCount: 3,
      yields: "abc"
    )
    self.check(
      constraining: "abcdef",
      toCodePointCount: 4,
      yields: "abcd"
    )
    self.check(
      constraining: "abcdef",
      toCodePointCount: 5,
      yields: "abcde"
    )
    self.check(
      constraining: "abcdef",
      toCodePointCount: 6,
      yields: "abcdef"
    )
    self.check(
      constraining: "abcdef",
      toCodePointCount: 7,
      yields: "abcdef"
    )
  }
  
  func testMutableImmutableCodePointCountConstraintEquivalence() {
    self.haltingOnFirstError {
      for (probe,length) in CartesianProduct(self.probeStrings,self.probeLengths).asTuples() {
        XCTAssertEqual(
          probe.constrained(toCodePointCount: length),
          probe.mutated() {
            $0.constrain(toCodePointCount: length)
          }
        )
      }
    }
  }
  
  func testCodePointCountConstraintSanity() {
    self.haltingOnFirstError {
      for (probe,length) in CartesianProduct(self.probeStrings,0...10).asTuples() {
        XCTAssertEqual(
          min(probe.codePointCount, length),
          probe.constrained(toCodePointCount: length).codePointCount
        )
      }
    }
  }
  
}

fileprivate extension StringURITemplateLengthManipulationTests {
  
  func check(
    constraining target: String,
    toCodePointCount codePointCount: Int,
    yields expectation: String) {
    let result = target.constrained(toCodePointCount: codePointCount)
    XCTAssertEqual(
      expectation,
      result,
      """
      Expected `"\(target)".constrained(toCodePointCount: \(codePointCount)) == "\(expectation)", but got "\(result)" instead!
      """
    )
  }
  
}
