//
//  TemplateRunner.swift
//  PathKit
//
//  Created by Yonas Kolb on 1/4/18.
//

import Foundation
import PathKit
import GenesisTemplate
import Stencil
import SwiftCLI
import struct GenesisTemplate.Option

public typealias Context = [String: Any]
public class TemplateGenerator {

    let template: GenesisTemplate
    let environment: Environment
    var interactive: Bool

    public init(template: GenesisTemplate, interactive: Bool) throws {
        self.template = template
        self.interactive = interactive
        self.environment = Environment(loader: FileSystemLoader(paths: [template.path.parent()]), extensions: nil, templateClass: Template.self)
    }

    public func generate(path: Path, context: Context) throws -> GenerationResult {
        var context: Context = context
        return try generateSection(template.section, path: path, context: &context)
    }

    fileprivate func getOptionValue(_ option: Option, path: Path, context: inout Context) throws {
        if let value = context[option.name] {
            // found existing option
            return
        }
        
        if let value = option.value {
            // found default option
            context[option.name] = value
            return
        }

        if !interactive {
            if option.required {
                print("Missing value for required \(option.name) option")
                throw GeneratorError.missingOption(option)
            } else {
                return
            }
        }

        let question = option.question ?? option.name

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
                        try getOptionValue(childOption, path: path, context: &childContext)
                    }
                    array.append(childContext)
                    context[option.name] = array
                    try addItem()
                }
            }
            try addItem()
        }

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

    func generateSection(_ section: TemplateSection, path: Path, context: inout Context) throws -> GenerationResult {
        for option in section.options {
            try getOptionValue(option, path: path, context: &context)
        }

        // print("Template Context: \(context)")

        var generatedFiles: [GeneratedFile] = []

        func generateFile(_ file: File, path: Path, context: Context) throws  {

            if let include = file.include {
                let expression = "{% if \(include) %}true{% endif %}"
                let parsedIf = try environment.renderTemplate(string: expression, context: context)
                if parsedIf == "" {
                    return
                }
            }
            let fileContents: String
            switch file.type {
            case .contents(let string): fileContents = try environment.renderTemplate(string: string, context: context)
            case .template(let path): fileContents = try environment.renderTemplate(name: path, context: context)
            }
            let replacedPath = try environment.renderTemplate(string: file.path, context: context)
            let generatedFile = GeneratedFile(path: Path(replacedPath), contents: fileContents)
            generatedFiles.append(generatedFile)
        }

        for file in section.files {
            if let fileContextPath = file.context, let fileContext = context[fileContextPath] {
                if let array = fileContext as? [Context] {
                    for element in array {
                        try generateFile(file, path: path, context: element)
                    }
                } else if let context = fileContext as? Context {
                    try generateFile(file, path: path, context: context)
                } else {
                    try generateFile(file, path: path, context: context)
                }
            } else {
                try generateFile(file, path: path, context: context)
            }
        }

        return GenerationResult(files: generatedFiles, context: context)
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
}

public struct GeneratedFile: Equatable, CustomStringConvertible {
    public let path: Path
    public let contents: String

    public var description: String {
         return path.string
    }
}
