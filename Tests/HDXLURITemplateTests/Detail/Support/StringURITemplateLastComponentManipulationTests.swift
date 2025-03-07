//
//  StringURITemplateLastComponentManipulationTests.swift
//

import Foundation
import XCTest
@testable import HDXLURITemplate

class StringURITemplateLastComponentManipulationTests : XCTestCase {
  
  func testDegenerateScenarios() {
    // all-empty
    self.checkLastComponent(
      of: "",
      forSeparator: "",
      yields: nil
    )
    self.checkRemovingLastComponent(
      of: "",
      forSeparator: "",
      yields: ""
    )
    
    // empty-target
    self.checkLastComponent(
      of: "",
      forSeparator: ",",
      yields: nil
    )
    self.checkRemovingLastComponent(
      of: "",
      forSeparator: ",",
      yields: ""
    )
    
    // empty-separator
    self.checkLastComponent(
      of: "abc",
      forSeparator: "",
      yields: nil
    )
    self.checkRemovingLastComponent(
      of: "abc",
      forSeparator: "",
      yields: "abc"
    )
    

  }
  
}

fileprivate extension StringURITemplateLastComponentManipulationTests {
  
  func checkLastComponent(
    of target: String,
    forSeparator separator: String,
    yields expectation: String?) {
    let result = target.lastComponent(forSeparator: separator)
    XCTAssertEqual(
      result,
      expectation,
      """
      Expected `"\(target)".lastComponent(forSeparator: "\(separator)") == "\(expectation ?? "<nil>")"`, but got "\(result ?? "<nil>")" instead!
      """
    )
  }
  
  func checkRemovingLastComponent(
    of target: String,
    forSeparator separator: String,
    yields expectation: String) {
    let result = target.removingLastComponent(forSeparator: separator)
    XCTAssertEqual(
      result,
      expectation,
      """
      Expected `"\(target)".removingLastComponent(forSeparator: "\(separator)") == "\(expectation)"`, but got "\(result)" instead!
      """
    )
  }
  
}
