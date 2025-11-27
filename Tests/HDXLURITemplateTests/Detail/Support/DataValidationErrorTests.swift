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
  func `construction`() {
    // with all parameters
    let withAll = DataValidationError(
      forType: String.self,
      problemDescription: "The string is invalid",
      repairDescription: "Use a default string",
      repairSuggestion: "default"
    )
    #expect(withAll.repairSuggestion == "default")

    // with minimal parameters
    let minimal = DataValidationError(
      forType: Int.self,
      problemDescription: nil,
      repairDescription: nil,
      repairSuggestion: nil
    )
    #expect(minimal.repairSuggestion == nil)

    // without repair suggestion
    let withoutRepair = DataValidationError(
      forType: Double.self,
      problemDescription: "Invalid value",
      repairDescription: nil,
      repairSuggestion: nil
    )
    #expect(withoutRepair.repairSuggestion == nil)

    // with only problem description
    let problemOnly = DataValidationError<String>(
      forType: String.self,
      problemDescription: "Something went wrong"
    )
    #expect(problemOnly.repairSuggestion == nil)
  }

  // MARK: - Repair Suggestion Tests

  @Test
  func `repair suggestion`() {
    // simple type
    let suggestion = "repaired value"
    let simple = DataValidationError(
      forType: String.self,
      problemDescription: "Invalid",
      repairDescription: "Here's a fix",
      repairSuggestion: suggestion
    )
    #expect(simple.repairSuggestion == suggestion)

    // complex type
    struct ComplexType: Sendable, Equatable {
      let id: Int
      let name: String
    }

    let complexSuggestion = ComplexType(id: 1, name: "fixed")
    let complex = DataValidationError(
      forType: ComplexType.self,
      problemDescription: "Invalid complex type",
      repairDescription: "Use default",
      repairSuggestion: complexSuggestion
    )
    #expect(complex.repairSuggestion == complexSuggestion)
  }

  // MARK: - Error Protocol Conformance Tests

  @Test
  func `error protocol conformance`() throws {
    // conforms to Error
    let error: any Error = DataValidationError(
      forType: String.self,
      problemDescription: "test"
    )
    #expect(error is DataValidationError<String>)

    // can be thrown and caught
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

    // can be thrown and caught with repair suggestion
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
  func `various types`() {
    // array type
    let arrayError = DataValidationError(
      forType: [String].self,
      problemDescription: "Invalid array",
      repairDescription: "Use empty array",
      repairSuggestion: []
    )
    #expect(arrayError.repairSuggestion?.isEmpty == true)

    // optional type
    let optionalError: DataValidationError<String?> = DataValidationError(
      forType: (String?).self,
      problemDescription: "Invalid optional",
      repairDescription: "Use nil",
      repairSuggestion: nil
    )
    #expect(optionalError.repairSuggestion == nil)

    // URIVariableValue type
    let variableValueError = DataValidationError(
      forType: URIVariableValue.self,
      problemDescription: "Invalid variable value",
      repairDescription: "Use undefined",
      repairSuggestion: .undefined
    )
    #expect(variableValueError.repairSuggestion == .undefined)

    // URIValueExpansionModifier type
    let modifierError = DataValidationError(
      forType: URIValueExpansionModifier.self,
      problemDescription: "Invalid prefix value",
      repairDescription: "Use minimum prefix",
      repairSuggestion: .prefix(1)
    )
    #expect(modifierError.repairSuggestion == .prefix(1))
  }

}
