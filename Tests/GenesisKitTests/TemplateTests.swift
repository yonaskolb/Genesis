import XCTest
import GenesisKit
import PathKit

public class TemplateTests: XCTestCase {

    let fixturePath = Path(#file).parent().parent() + "Fixtures"

    func testTemplateParsing() throws {
        let templateFixture = fixturePath + "template.yml"
        let parsedTemplate = try GenesisTemplate(path: templateFixture)

        let expectedFiles: [File] = [
            File(type: .template("Project.stencil"), path: "{{ name }}.swift"),
            File(type: .contents("File {{ name }} of type {{ type }}"), path: "{{ name }}.{{ type }}", include: "generate", context: "files"),
        ]
        let expectedOptions: [Option] = [
            Option(name: "project", description: "The name of the project", value: "Project", type: .string, question: "What is the name of your project?", required: true),
            Option(name: "files", description: "The list of files", type: .array, question: "Do you wish to add a file?", options: [
                Option(name: "name", question: "What's the name of the file?"),
                Option(name: "type", type: .choice, question: "What sort of file?", choices: ["stencil", "swift"]),
                Option(name: "generate", value: "true", type: .boolean, question: "Should this be generated?"),
                ])
        ]
        let expectedTemplate = GenesisTemplate(path: templateFixture,
                                               section: TemplateSection(files: expectedFiles, options: expectedOptions))

        XCTAssertEqual(expectedTemplate, parsedTemplate)
    }
}
