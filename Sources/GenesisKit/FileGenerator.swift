import Foundation
import PathKit
import StencilSwiftKit
import SwiftCLI

public class FileGenerator {

    let renderer: Renderer
    let template: Template

    public init(template: Template, renderer: Renderer? = nil) {
        self.template = template
        self.renderer = renderer ?? stencilRenderer(templatePaths: [template.path.parent()])
    }

    public func generate(context: Context) throws -> [GeneratedFile] {
        return try generateSection(template.section, context: context)
    }

    func replaceString(_ string: String, context: Context) throws -> String {
        if string.contains("{") {
            return try renderer.renderTemplate(string: string, context: context)
        } else {
            return string
        }
    }

    func generateSection(_ section: TemplateSection, context: Context) throws -> [GeneratedFile] {

        var generatedFiles: [GeneratedFile] = []

        func generateFile(_ file: File, context: Context) throws {

            if let include = file.include {
                let expression = "{% if \(include) %}true{% endif %}"
                let parsedIf = try replaceString(expression, context: context)
                if parsedIf == "" {
                    return
                }
            }
            let fileContents: String
            switch file.type {
            case let .template(path): fileContents = try renderer.renderTemplate(name: path, context: context)
            case let .contents(string): fileContents = try replaceString(string, context: context)
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

public struct GeneratedFile: Equatable, CustomStringConvertible, CustomDebugStringConvertible {
    public let path: Path
    public let contents: String

    init(path: Path, contents: String) {
        self.path = path
        self.contents = contents
    }

    public var description: String {
        return path.string
    }

    public var debugDescription: String {
        return "Path: \(path.string)\nContents:\n\(contents)"
    }
}
