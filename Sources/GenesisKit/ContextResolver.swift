//
//  OptionResolver.swift
//  GenesisKit
//
//  Created by Yonas Kolb on 4/3/19.
//

import Foundation
import SwiftCLI
import PathKit
import Yams

public class ContextResolver {

    var answers: [Answer] = []
    let renderer: Renderer
    let template: Template
    var interactive = true

    public init(template: Template, interactive: Bool, renderer: Renderer? = nil) {
        self.template = template
        self.interactive = interactive
        self.renderer = renderer ?? stencilRenderer(templatePaths: [])
    }

    public enum Source {
        case env
        case optionFile(Path)
        case template(Template)
    }

    public func resolve(sources: [Source]) -> Context {
        var context = Context()
        for source in sources {
            switch source {
            case .env:
                context = mergeContext(resolveEnvironmentVariables(), onto: context)
            }
        }
        return context
    }

    public func resolveOptions(context: Context) throws -> Context {
        answers = []
        var context = context
        try resolveSection(template.section, context: &context)
        return context
    }

    public func resolveEnvironmentVariables() -> Context {
        return ProcessInfo.processInfo.environment
    }

    public func resolveOptionFile(_ optionFile: Path) throws -> Context {
        if !optionFile.exists {
            throw GeneratorError.optionFileMissing(optionFile)
        }
        let string: String = try optionFile.read()
        let data: Any?
        do {
            data = try Yams.load(yaml: string)
        }
        catch {
            throw GeneratorError.optionFileParsingError(error)
        }
        let dictionary = data as? [String: Any] ?? [:]
        return dictionary
    }

    private func mergeContext(_ context: Context, onto: Context) -> Context {
        var resolvedContext = onto
        for (key, value) in context {
            resolvedContext[key] = value
        }
        return context
    }

    private func resolveSection(_ section: TemplateSection, context: inout Context) throws {
        for option in section.options {
            try getOptionValue(option, context: &context)
        }
    }

    fileprivate func getOptionValue(_ option: Option, context: inout Context) throws {
        var context = context
        if let value = context[option.name] {
            // found existing option
            return
        }

        if let value = option.value {
            // found default option
            context[option.name] = try renderer.renderTemplate(string: value, context: context)
            return
        }

        if !interactive {
            if option.required {
                throw GeneratorError.missingOption(option)
            } else {
                return
            }
        }

        let question = try option.question.flatMap { try renderer.renderTemplate(string: $0, context: context) } ?? option.name

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
    case missingOption(Option)
    case optionFileMissing(Path)
    case optionFileParsingError(Error)
}
