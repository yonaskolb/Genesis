@testable import GenesisKit
import struct GenesisKit.Option
import PathKit
import XCTest

public class WritingTests: XCTestCase {

    func testFixtureGeneration() throws {
        let template = try GenesisTemplate(path: fixturePath + "template.yml")
        let generator = try TemplateGenerator(template: template)
        let context: Context = [
            "project": "MyProject",
            "files":
                [
                    [
                        "name": "MyFile",
                        "type": "swift",
                        "generate": "true",
                    ]
                ],
            "path": "App/Child",
        ]
        let result = try generator.generate(context: context, interactive: false)
        try result.writeFiles(path: fixturePath + "generated")
    }
}
