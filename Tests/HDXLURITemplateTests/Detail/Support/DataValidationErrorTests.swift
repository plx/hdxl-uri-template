import Testing
import Foundation
@testable import HDXLURITemplate

extension Tag {
  @Tag
  static var dataValidationError: Self
}

@Suite(.tags(.dataValidationError))
struct DataValidationErrorTests {

  // MARK: - Construction Tests

  @Test
  func `constructs with all parameters`() {
    let error = DataValidationError(
      forType: String.self,
      problemDescription: "The string is invalid",
      repairDescription: "Use a default string",
      repairSuggestion: "default"
    )
    #expect(error.repairSuggestion == "default")
  }

  @Test
  func `constructs with minimal parameters`() {
    let error = DataValidationError(
      forType: Int.self,
      problemDescription: nil,
      repairDescription: nil,
      repairSuggestion: nil
    )
    #expect(error.repairSuggestion == nil)
  }

  @Test
  func `constructs without repair suggestion`() {
    let error = DataValidationError(
      forType: Double.self,
      problemDescription: "Invalid value",
      repairDescription: nil,
      repairSuggestion: nil
    )
    #expect(error.repairSuggestion == nil)
  }

  @Test
  func `constructs with only problem description`() {
    let error = DataValidationError<String>(
      forType: String.self,
      problemDescription: "Something went wrong"
    )
    #expect(error.repairSuggestion == nil)
  }

  // MARK: - Repair Suggestion Tests

  @Test
  func `repair suggestion is accessible`() {
    let suggestion = "repaired value"
    let error = DataValidationError(
      forType: String.self,
      problemDescription: "Invalid",
      repairDescription: "Here's a fix",
      repairSuggestion: suggestion
    )
    #expect(error.repairSuggestion == suggestion)
  }

  @Test
  func `repair suggestion with complex type`() {
    struct ComplexType: Sendable, Equatable {
      let id: Int
      let name: String
    }

    let suggestion = ComplexType(id: 1, name: "fixed")
    let error = DataValidationError(
      forType: ComplexType.self,
      problemDescription: "Invalid complex type",
      repairDescription: "Use default",
      repairSuggestion: suggestion
    )
    #expect(error.repairSuggestion == suggestion)
  }

  // MARK: - Error Protocol Conformance Tests

  @Test
  func `conforms to Error protocol`() {
    let error: any Error = DataValidationError(
      forType: String.self,
      problemDescription: "test"
    )
    #expect(error is DataValidationError<String>)
  }

  @Test
  func `can be thrown and caught`() {
    do {
      throw DataValidationError(
        forType: Int.self,
        problemDescription: "Invalid integer"
      )
    } catch is DataValidationError<Int> {
      // Expected
    } catch {
      Issue.record("Expected DataValidationError<Int>, got \(type(of: error))")
    }
  }

  @Test
  func `can be thrown and caught with repair`() throws {
    let repairValue = 42
    do {
      throw DataValidationError(
        forType: Int.self,
        problemDescription: "Invalid",
        repairDescription: "Use 42",
        repairSuggestion: repairValue
      )
    } catch let error as DataValidationError<Int> {
      #expect(error.repairSuggestion == repairValue)
    }
  }

  // MARK: - Various Types Tests

  @Test
  func `works with array type`() {
    let error = DataValidationError(
      forType: [String].self,
      problemDescription: "Invalid array",
      repairDescription: "Use empty array",
      repairSuggestion: []
    )
    #expect(error.repairSuggestion?.isEmpty == true)
  }

  @Test
  func `works with optional repair suggestion`() {
    let error: DataValidationError<String?> = DataValidationError(
      forType: (String?).self,
      problemDescription: "Invalid optional",
      repairDescription: "Use nil",
      repairSuggestion: nil
    )
    #expect(error.repairSuggestion == nil)
  }

  @Test
  func `works with URIVariableValue type`() {
    let error = DataValidationError(
      forType: URIVariableValue.self,
      problemDescription: "Invalid variable value",
      repairDescription: "Use undefined",
      repairSuggestion: .undefined
    )
    #expect(error.repairSuggestion == .undefined)
  }

  @Test
  func `works with URIValueExpansionModifier type`() {
    let error = DataValidationError(
      forType: URIValueExpansionModifier.self,
      problemDescription: "Invalid prefix value",
      repairDescription: "Use minimum prefix",
      repairSuggestion: .prefix(1)
    )
    #expect(error.repairSuggestion == .prefix(1))
  }

}
