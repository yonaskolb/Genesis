
import Foundation
import SwiftCLI

extension Input {

    public static func readOption(options: [String], prompt: String) -> String {
        let optionsString = options.enumerated()
            .map { "  \($0.offset + 1). \($0.element)" }
            .joined(separator: "\n")

        let prompt = "\(prompt)\n\(optionsString)"

        let validation: InputReader<String>.Validation = { input in
            if let index = Int(input), index > 0, index <= options.count {
                return true
            }
            return options.contains(input)
        }
        let errorResponse: InputReader<String>.ErrorResponse = { _ in
            printError("You must respond with one of the following:\n\(optionsString)")
        }
        return readObject(prompt: prompt, secure: false, validation: validation, errorResponse: errorResponse)
    }
    
}
