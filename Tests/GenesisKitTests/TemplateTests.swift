import XCTest
import GenesisKit
import PathKit

public class TemplateTests: XCTestCase {

    let fixturePath = Path(#file).parent().parent() + "Fixtures"

    func testTemplateParsing() throws {
        let templateFixture = fixturePath + "template.yml"
        let template = try GenesisTemplate(path: templateFixture)

        XCTAssertEqual(template.section.options.count, 2)
        XCTAssertEqual(template.section.files.count, 2)
    }
}
