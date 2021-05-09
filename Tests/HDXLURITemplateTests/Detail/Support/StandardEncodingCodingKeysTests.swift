//
//  StandardEncodingCodingKeysTests.swift
//

import Foundation
import XCTest
import HDXLCommonUtilities
import HDXLTestingUtilities
@testable import HDXLURITemplate

class StandardEncodingCodingKeysTests : XCTestCase {
  
  func testCodingKeyIntValueSanity() {
    XCTAssertNotNil(StandardEnumerationCodingKeys.type.intValue)
    XCTAssertNotNil(StandardEnumerationCodingKeys.data.intValue)
    XCTAssertNotEqual(
      StandardEnumerationCodingKeys.type.intValue,
      StandardEnumerationCodingKeys.data.intValue
    )
  }
  
  func testCodingKeyIntValueRoundTrips() {
    XCTAssertNoThrow(
      try self.checkRoundTrip(for: .type)
    )
    XCTAssertNoThrow(
      try self.checkRoundTrip(for: .data)
    )
  }
    
}

fileprivate extension StandardEncodingCodingKeysTests {
  
  func checkRoundTrip(for value: StandardEnumerationCodingKeys) throws {
    let intValue = try XCTUnwrap(value.intValue)
    let roundTrip = try XCTUnwrap(
      StandardEnumerationCodingKeys(intValue: intValue)
    )
    XCTAssertEqual(
      value,
      roundTrip
    )
  }
  
}
