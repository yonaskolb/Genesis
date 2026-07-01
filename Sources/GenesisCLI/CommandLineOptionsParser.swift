import Foundation
import GenesisKit

enum CommandLineOptionsParserError: Error, CustomStringConvertible, LocalizedError, Equatable {
    case malformedOption(String)
    case emptyKey(String)
    case emptyArrayItem(String)
    case duplicateKey(String)
    case danglingEscape(String)
    case unmatchedClosingBracket(String)
    case unterminatedArray(String)

    var description: String {
        switch self {
        case .malformedOption(let option):
            return "Malformed option '\(option)'. Expected 'key: value'."
        case .emptyKey(let option):
            return "Malformed option '\(option)'. Option keys cannot be empty."
        case .emptyArrayItem(let option):
            return "Malformed option '\(option)'. Array items cannot be empty."
        case .duplicateKey(let key):
            return "Duplicate option '\(key)'. Use bracket array syntax for array values."
        case .danglingEscape(let option):
            return "Malformed option '\(option)'. Escape character must be followed by a value."
        case .unmatchedClosingBracket(let option):
            return "Malformed option '\(option)'. Found ']' without a matching '['."
        case .unterminatedArray(let option):
            return "Malformed option '\(option)'. Array value is missing a closing ']'."
        }
    }

    var errorDescription: String? {
        return description
    }
}

struct CommandLineOptionsParser {

    static func parse(_ string: String) throws -> Context {
        var context: Context = [:]
        let optionList = try splitTopLevel(string, separator: ",")

        for option in optionList {
            let trimmedOption = option.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedOption.isEmpty {
                throw CommandLineOptionsParserError.malformedOption(option)
            }

            let (key, value) = try parseOption(trimmedOption)
            guard context[key] == nil else {
                throw CommandLineOptionsParserError.duplicateKey(key)
            }
            context[key] = value
        }

        return context
    }

    private static func parseOption(_ option: String) throws -> (String, Any) {
        guard let separatorIndex = try firstUnescapedColon(in: option) else {
            throw CommandLineOptionsParserError.malformedOption(option)
        }

        let key = String(option[..<separatorIndex]).trimmingCharacters(in: .whitespacesAndNewlines)
        if key.isEmpty {
            throw CommandLineOptionsParserError.emptyKey(option)
        }

        let valueStart = option.index(after: separatorIndex)
        let value = String(option[valueStart...]).trimmingCharacters(in: .whitespacesAndNewlines)
        return (key, try parseValue(value, option: option))
    }

    private static func parseValue(_ value: String, option: String) throws -> Any {
        if value.hasPrefix("[") {
            guard value.hasSuffix("]") else {
                throw CommandLineOptionsParserError.unterminatedArray(option)
            }

            let start = value.index(after: value.startIndex)
            let end = value.index(before: value.endIndex)
            let arrayString = String(value[start..<end])
            if arrayString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return [String]()
            }

            return try splitTopLevel(arrayString, separator: ",").map { item -> String in
                let trimmedItem = item.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmedItem.isEmpty {
                    throw CommandLineOptionsParserError.emptyArrayItem(option)
                }
                return try unescape(trimmedItem, option: option)
            }
        }

        return try unescape(value, option: option)
    }

    private static func firstUnescapedColon(in string: String) throws -> String.Index? {
        var isEscaping = false

        for index in string.indices {
            let character = string[index]
            if isEscaping {
                isEscaping = false
            } else if character == "\\" {
                isEscaping = true
            } else if character == ":" {
                return index
            }
        }

        if isEscaping {
            throw CommandLineOptionsParserError.danglingEscape(string)
        }

        return nil
    }

    private static func splitTopLevel(_ string: String, separator: Character) throws -> [String] {
        var parts: [String] = []
        var current = ""
        var bracketDepth = 0
        var isEscaping = false

        for character in string {
            if isEscaping {
                current.append("\\")
                current.append(character)
                isEscaping = false
            } else if character == "\\" {
                isEscaping = true
            } else if character == "[" {
                bracketDepth += 1
                current.append(character)
            } else if character == "]" {
                guard bracketDepth > 0 else {
                    throw CommandLineOptionsParserError.unmatchedClosingBracket(string)
                }
                bracketDepth -= 1
                current.append(character)
            } else if character == separator && bracketDepth == 0 {
                parts.append(current)
                current = ""
            } else {
                current.append(character)
            }
        }

        if isEscaping {
            throw CommandLineOptionsParserError.danglingEscape(string)
        }

        if bracketDepth > 0 {
            throw CommandLineOptionsParserError.unterminatedArray(string)
        }

        parts.append(current)
        return parts
    }

    private static func unescape(_ string: String, option: String) throws -> String {
        var result = ""
        var isEscaping = false

        for character in string {
            if isEscaping {
                result.append(character)
                isEscaping = false
            } else if character == "\\" {
                isEscaping = true
            } else {
                result.append(character)
            }
        }

        if isEscaping {
            throw CommandLineOptionsParserError.danglingEscape(option)
        }

        return result
    }
}
