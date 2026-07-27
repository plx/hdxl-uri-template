import Foundation

package struct QA03Arguments {
  private var values: [String: String] = [:]

  package init(_ rawArguments: [String]) throws {
    guard rawArguments.count.isMultiple(of: 2) else {
      throw QA03Error("Every QA-03 option requires one value.")
    }
    var index = 0
    while index < rawArguments.count {
      let name = rawArguments[index]
      let value = rawArguments[index + 1]
      guard name.hasPrefix("--"), values[name] == nil else {
        throw QA03Error("Invalid or duplicate QA-03 option \(name).")
      }
      values[name] = value
      index += 2
    }
  }

  package mutating func seed(named name: String) throws -> UInt64 {
    let rawValue = try required(named: name)
    let digits =
      rawValue.hasPrefix("0x") || rawValue.hasPrefix("0X")
      ? String(rawValue.dropFirst(2))
      : rawValue
    guard let value = UInt64(digits, radix: 16) else {
      throw QA03Error("\(name) must be a hexadecimal UInt64.")
    }
    return value
  }

  package mutating func integer(
    named name: String,
    minimum: Int
  ) throws -> Int {
    guard
      let value = Int(try required(named: name)),
      value >= minimum
    else {
      throw QA03Error("\(name) must be an integer at least \(minimum).")
    }
    return value
  }

  package mutating func optionalInteger(
    named name: String,
    minimum: Int
  ) throws -> Int? {
    guard values[name] != nil else {
      return nil
    }
    return try integer(named: name, minimum: minimum)
  }

  package mutating func url(named name: String) throws -> URL {
    URL(fileURLWithPath: try required(named: name))
  }

  package mutating func optionalURL(named name: String) -> URL? {
    values.removeValue(forKey: name).map(URL.init(fileURLWithPath:))
  }

  package func requireNoUnusedOptions() throws {
    guard values.isEmpty else {
      throw QA03Error(
        "Unknown QA-03 option(s): \(values.keys.sorted().joined(separator: ", "))."
      )
    }
  }

  private mutating func required(named name: String) throws -> String {
    guard
      let value = values.removeValue(forKey: name),
      !value.isEmpty
    else {
      throw QA03Error("Missing required option \(name).")
    }
    return value
  }
}
