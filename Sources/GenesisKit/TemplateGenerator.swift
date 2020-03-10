import Foundation
import PathKit
import Stencil
import StencilSwiftKit
import SwiftCLI

public typealias Context = [String: Any]
public class TemplateGenerator {

    let template: GenesisTemplate
    let environment: Environment
    var interactive = true
    var answers: [Answer] = []

    public init(template: GenesisTemplate, environment: Environment? = nil) throws {
        self.template = template
        if let environment = environment {
            self.environment = environment
        } else {
            var environment = stencilSwiftEnvironment()
            environment.loader = FileSystemLoader(paths: [template.path.parent()])
            self.environment = environment
        }
    }

    public func generate(context: Context, interactive: Bool) throws -> GenerationResult {
        self.interactive = interactive
        answers = []
        var context: Context = context
        let generatedFiles = try generateSection(template.section, context: &context)
        return GenerationResult(files: generatedFiles, context: context, answers: answers)
    }

    fileprivate func getOptionValue(_ option: Option, context: inout Context) throws {
        if let value = context[option.name] {
            // found existing option
            return
        }

        if let value = option.value {
            // found default option
            context[option.name] = try replaceString(value, context: context)
            return
        }

        if !interactive {
            if option.required {
                throw GeneratorError.missingOption(option)
            } else {
                return
            }
        }

        let question = try option.question.flatMap { try replaceString($0, context: context) } ?? option.name

        switch option.type {
        case .choice: context[option.name] = Input.readOption(options: option.choices, prompt: question)
        case .string: context[option.name] = Input.readLine(prompt: question)
        case .boolean: context[option.name] = Input.readBool(prompt: question)
        case .array:
            var array: [Context] = []
            func addItem() throws {
                if Input.readBool(prompt: question) {
                    var childContext = Context()
                    for childOption in option.options {
                        try getOptionValue(childOption, context: &childContext)
                    }
                    array.append(childContext)
                    context[option.name] = array
                    try addItem()
                }
            }
            try addItem()
        }

        answers.append(Answer(question: question, answer: context[option.name] as Any))

        //        if let branch = option.branch[answerString] {
        //            var branchContext: Context = [:]
        //
        //            try generateSection(branch, path: path, context: &branchContext)
        //            switch option.set {
        //            case .name:
        //                break
        //            case .array:
        //                var array = context[option.name] as! [Context]
        //                array.append(branchContext)
        //                context[option.name] = array
        //            }
        //        }
        //        if let repeatAnswer = option.repeatAnswer, answerString == repeatAnswer {
        //            try checkOption(option, path: path, context: &context)
        //        }
    }

    func replaceString(_ string: String, context: Context) throws -> String {
        if string.contains("{") {
            return try environment.renderTemplate(string: string, context: context)
        } else {
            return string
        }
    }

    func generateSection(_ section: TemplateSection, context: inout Context) throws -> [GeneratedFile] {
        for option in section.options {
            try getOptionValue(option, context: &context)
        }

        var generatedFiles: [GeneratedFile] = []

        func generateFile(_ file: File, context: Context) throws {

            if let include = file.include {
                let expression = "{% if \(include) %}true{% endif %}"
                let parsedIf = try replaceString(expression, context: context)
                if parsedIf == "" {
                    return
                }
            }
            let fileContents: String?
            switch file.type {
            case let .template(path): fileContents = try environment.renderTemplate(name: path, context: context)
            case let .contents(string): fileContents = try replaceString(string, context: context)
            case .directory: fileContents = nil
            }
            let replacedPath = try replaceString(file.path, context: context)
            let generatedFile = GeneratedFile(path: Path(replacedPath), contents: fileContents)
            generatedFiles.append(generatedFile)
        }

        for file in section.files {
            if let fileContextPath = file.context, let fileContext = context[fileContextPath] {
                if let array = fileContext as? [Context] {
                    for element in array {
                        try generateFile(file, context: element)
                    }
                } else if let context = fileContext as? Context {
                    try generateFile(file, context: context)
                } else {
                    try generateFile(file, context: context)
                }
            } else {
                try generateFile(file, context: context)
            }
        }

        return generatedFiles
    }
}

public struct Answer: Equatable {
    public let question: String
    public let answer: Any

    public static func == (lhs: Answer, rhs: Answer) -> Bool {
        return lhs.question == rhs.question &&
            String(describing: lhs.answer) == String(describing: rhs.answer)
    }
}

public enum GeneratorError: Error {
    case templateSyntax(TemplateSyntaxError)
    case missingTemplate(TemplateDoesNotExist)
    case missingOption(Option)
}

public struct GenerationResult {
    public let files: [GeneratedFile]
    public let context: Context
    public let answers: [Answer]

    public func writeFiles(path: Path) throws {

        for file in files {
            let filePath = path + file.path
            if let contents = file.contents {
                try filePath.parent().mkpath()
                try filePath.write(contents)
            } else {
                try filePath.mkpath()
            }
        }
    }
}

public struct GeneratedFile: Equatable, CustomStringConvertible {
    public let path: Path
    public let contents: String?

    public var description: String {
        return path.string
    }
}
