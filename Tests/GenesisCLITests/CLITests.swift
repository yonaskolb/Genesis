import GenesisCLI
import SwiftCLI
import XCTest

public class CLITests: XCTestCase {

    func testCLI() {
        let cli = GenesisCLI()
        XCTAssertEqual(cli.run(arguments: [""]), 1)
        XCTAssertEqual(cli.run(arguments: ["invalid"]), 1)
        XCTAssertEqual(cli.run(arguments: ["help"]), 0)
    }
}
