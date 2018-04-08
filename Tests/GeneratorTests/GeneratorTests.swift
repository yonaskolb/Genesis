import XCTest
@testable import Generator
@testable import GenesisTemplate
import PathKit

public class GeneratorTests: XCTestCase {

    func testOptionPassing() throws {
        let options = [Option(name: "name")]
        let files = [File(type: .contents("name: {{ name }}"), path: "{{ name }}.swift")]
        let expectedFiles = [GeneratedFile(path: "test.swift", contents: "name: test")]
        try expectGeneration(options: options, files: files, passedOptions: ["name": "test"], expectedFiles: expectedFiles)
    }

    func testDefaultValues() throws {
        let options = [Option(name: "name", value: "test")]
        let files = [File(type: .contents("name: {{ name }}"), path: "{{ name }}.swift")]
        let expectedFiles = [GeneratedFile(path: "test.swift", contents: "name: test")]
        try expectGeneration(options: options, files: files, passedOptions: [:], expectedFiles: expectedFiles)
    }

    func testUsePassedOptionOverDefaultValues() throws {
        let options = [Option(name: "name", value: "default")]
        let files = [File(type: .contents("name: {{ name }}"), path: "{{ name }}.swift")]
        let expectedFiles = [GeneratedFile(path: "test.swift", contents: "name: test")]
        try expectGeneration(options: options, files: files, passedOptions: ["name": "test"], expectedFiles: expectedFiles)
    }

    func expectGeneration(templateString: String, passedOptions: [String: Any] = [:], expectedFiles: [GeneratedFile], file: StaticString = #file, line: UInt = #line) throws {
        let template = try GenesisTemplate(path: "", string: templateString)
        try expectGeneration(template: template, passedOptions: passedOptions, expectedFiles: expectedFiles, file: file, line: line)
    }

    func expectGeneration(options: [Option], files: [File], passedOptions: [String: Any], expectedFiles: [GeneratedFile], file: StaticString = #file, line: UInt = #line) throws {
        let template = GenesisTemplate(path: "", section: TemplateSection(files: files, options: options))
        try expectGeneration(template: template, passedOptions: passedOptions, expectedFiles: expectedFiles, file: file, line: line)
    }

    func expectGeneration(template: GenesisTemplate, passedOptions: [String: Any], expectedFiles: [GeneratedFile], file: StaticString = #file, line: UInt = #line) throws {
        let generator = try TemplateGenerator(template: template, interactive: false)
        let generationResult = try generator.generate(path: "", options: passedOptions)
        let generatedFiles = generationResult.files
        XCTAssertEqual(generatedFiles.count, expectedFiles.count, file: file, line: line)
        for (generatedFile, expectedFile) in zip(expectedFiles, generatedFiles) {
            XCTAssertEqual(generatedFile,
                           expectedFile,
                           "\nGENERATED:\n  \(generatedFile.contents.replacingOccurrences(of: "\n", with: "\n  "))\nEXPECTED:\n  \(expectedFile.contents.replacingOccurrences(of: "\n", with: "\n  "))",
                    file: file,
                    line: line)
        }

    }
}
