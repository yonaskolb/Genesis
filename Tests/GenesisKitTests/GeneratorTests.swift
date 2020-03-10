@testable import GenesisKit
import struct GenesisKit.Option
import PathKit
@testable import SwiftCLI
import XCTest

public class GeneratorTests: XCTestCase {

    func expectGeneration(
        options: [Option] = [],
        files: [File] = [],
        context: Context = [:],
        expectedFiles: [GeneratedFile]? = nil,
        expectedContext: Context? = nil,
        expectedAnswers: [Answer]? = nil,
        inputs: [String]? = nil,
        file: StaticString = #file,
        line: UInt = #line
    ) throws {
        if let inputs = inputs {
            var inputIndex = -1
            ReadInput.read = {
                inputIndex += 1
                return inputs[inputIndex]
            }
        }
        let template = GenesisTemplate(path: "", section: TemplateSection(files: files, options: options))
        let generator = try TemplateGenerator(template: template)
        let generationResult = try generator.generate(context: context, interactive: inputs != nil)
        if let expectedFiles = expectedFiles {
            let generatedFiles = generationResult.files.sorted { $0.path < $1.path }
            let expectedFiles = expectedFiles.sorted { $0.path < $1.path }
            XCTAssertEqual(generatedFiles.count, expectedFiles.count, file: file, line: line)
            for (generatedFile, expectedFile) in zip(expectedFiles, generatedFiles) {
                if let generatedFileContents = generatedFile.contents,
                    let expectedFileContents = expectedFile.contents {
                    XCTAssertEqual(
                        generatedFile,
                        expectedFile,
                        "\nGENERATED:\n  \(generatedFileContents.replacingOccurrences(of: "\n", with: "\n  "))\nEXPECTED:\n  \(expectedFileContents.replacingOccurrences(of: "\n", with: "\n  "))",
                        file: file,
                        line: line
                    )
                } else {
                    XCTAssertNil(generatedFile.contents, "What was generated is a directory, not a file.")
                    XCTAssertNil(expectedFile.contents, "What was expected is a directory, not a file.")
                }
            }
        }
        if let expectedContext = expectedContext {
            XCTAssertTrue(NSDictionary(dictionary: expectedContext).isEqual(to: generationResult.context), "Context\n\(generationResult.context)\ndoes not equal\n\(expectedContext)", file: file, line: line)
        }
        if let expectedAnswers = expectedAnswers {
            XCTAssertEqual(generationResult.answers, expectedAnswers, file: file, line: line)
        }
    }

    func testOptionPassing() throws {
        let options = [Option(name: "name")]
        let files = [File(type: .contents("name: {{ name }}"), path: "{{ name }}.swift")]
        let expectedFiles = [GeneratedFile(path: "test.swift", contents: "name: test")]
        try expectGeneration(options: options, files: files, context: ["name": "test"], expectedFiles: expectedFiles)
    }

    func testDefaultValues() throws {
        let options = [Option(name: "name", value: "test")]
        let files = [File(type: .contents("name: {{ name }}"), path: "{{ name }}.swift")]
        let expectedFiles = [GeneratedFile(path: "test.swift", contents: "name: test")]
        try expectGeneration(options: options, files: files, context: [:], expectedFiles: expectedFiles)
    }

    func testFileInclude() throws {
        let options = [
            Option(name: "type"),
            Option(name: "includeFileC", type: .boolean),
            Option(name: "includeFileD", type: .boolean),
        ]
        let files = [
            File(type: .contents("a"), path: "a", include: "type == 'a'"),
            File(type: .contents("b"), path: "b", include: "type == 'b'"),
            File(type: .contents("c"), path: "c", include: "includeFileC"),
            File(type: .contents("d"), path: "d", include: "includeFileD"),
        ]
        let expectedFiles = [
            GeneratedFile(path: "a", contents: "a"),
            GeneratedFile(path: "c", contents: "c"),
        ]
        let context: Context = ["type": "a", "includeFileC": true, "includeFileD": false]
        try expectGeneration(options: options, files: files, context: context, expectedFiles: expectedFiles)
    }

    func testAskForOption() throws {
        let options = [Option(name: "name", required: true)]
        let files = [File(type: .contents("name: {{ name }}"), path: "{{ name }}.swift")]
        let expectedFiles = [GeneratedFile(path: "test.swift", contents: "name: test")]

        try expectGeneration(options: options, files: files, context: [:], expectedFiles: expectedFiles, inputs: ["test"])
    }

    func testAskForChoiceOption() throws {
        let options = [Option(name: "name", type: .choice, required: true, choices: ["one", "two"])]
        let files = [File(type: .contents("name: {{ name }}"), path: "{{ name }}.swift")]
        let expectedFiles = [GeneratedFile(path: "one.swift", contents: "name: one")]

        try expectGeneration(options: options, files: files, context: [:], expectedFiles: expectedFiles, inputs: ["one"])
        try expectGeneration(options: options, files: files, context: [:], expectedFiles: expectedFiles, inputs: ["1"])
    }

    func testFailsOnMissingRequiredOption() throws {
        let options = [Option(name: "name", required: true)]

        let template = GenesisTemplate(path: "", section: TemplateSection(files: [], options: options))
        let generator = try TemplateGenerator(template: template)
        XCTAssertThrowsError(try generator.generate(context: [:], interactive: false))
    }

    func testFailsOnMissingFiles() throws {
        let files = [File(type: .template("invalid"), path: "file")]

        let template = GenesisTemplate(path: "", section: TemplateSection(files: files, options: []))
        let generator = try TemplateGenerator(template: template)
        XCTAssertThrowsError(try generator.generate(context: [:], interactive: false))
    }

    func testUsePassedOptionOverDefaultValues() throws {
        let options = [Option(name: "name", value: "default")]
        let files = [File(type: .contents("name: {{ name }}"), path: "{{ name }}.swift")]
        let expectedFiles = [GeneratedFile(path: "test.swift", contents: "name: test")]
        try expectGeneration(options: options, files: files, context: ["name": "test"], expectedFiles: expectedFiles)
    }

    func testArrayOptions() throws {
        let options = [Option(name: "targets", type: .array, required: true)]
        let files = [
            File(type: .contents("name: {{ name }}"), path: "{{ name }}.swift", context: "targets"),
            File(type: .contents("header"), path: "{{ name }}.h", include: "name == 'framework'", context: "targets"),
        ]
        let expectedFiles = [
            GeneratedFile(path: "app.swift", contents: "name: app"),
            GeneratedFile(path: "framework.swift", contents: "name: framework"),
            GeneratedFile(path: "framework.h", contents: "header"),
        ]
        let context: Context = ["targets": [["name": "app"], ["name": "framework"]]]
        try expectGeneration(options: options, files: files, context: context, expectedFiles: expectedFiles)
    }

    func testArrayOptionsInput() throws {
        let inputs = [
            "y",
            "app",
            "y",
            "framework",
            "n",
        ]
        let nameOption = Option(name: "name")
        let options = [Option(name: "targets", type: .array, required: true, options: [nameOption])]
        let files = [File(type: .contents("name: {{ name }}"), path: "{{ name }}.swift", context: "targets")]
        let expectedFiles = [
            GeneratedFile(path: "app.swift", contents: "name: app"),
            GeneratedFile(path: "framework.swift", contents: "name: framework"),
        ]
        try expectGeneration(options: options, files: files, context: [:], expectedFiles: expectedFiles, inputs: inputs)
    }

    func testReplaceQuestion() throws {
        let options = [
            Option(name: "name"),
            Option(name: "red", type: .boolean, question: "Should {{ name }} be red?"),
        ]
        let expectedAnswers = [Answer(question: "name", answer: Optional("wall") as Any), Answer(question: "Should wall be red?", answer: Optional(true) as Any)]
        try expectGeneration(options: options, files: [], context: [:], expectedAnswers: expectedAnswers, inputs: ["wall", "y"])
    }

    func testSetContext() throws {
        let options = [Option(name: "color", value: "red")]
        try expectGeneration(options: options, files: [], context: [:], expectedContext: ["color": "red"])
    }

    func testReplaceDefaultValue() throws {
        let options = [
            Option(name: "color", required: true),
            Option(name: "isRed", value: "{% if color == 'red' %}true{% endif %}"),
        ]
        try expectGeneration(options: options, files: [], context: [:], expectedContext: ["color": "red", "isRed": "true"], inputs: ["red"])
    }

    func testStencilFormatting() throws {

        let stencil = """

        {% if name %}
        let name = {{ name }}
        {% endif %}

        {% for color in colors %}
          - {{ color }}
        {% endfor %}

        """
        let expectedOutput = """

        let name = hello

          - red
          - blue

        """
        let context: Context = ["name": "hello", "colors": ["red", "blue"]]
        try expectGeneration(files: [File(type: .contents(stencil), path: "")], context: context, expectedFiles: [GeneratedFile(path: "", contents: expectedOutput)])
    }
}
