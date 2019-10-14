import GenesisCLI
import SwiftCLI
import XCTest

public class CLITests: XCTestCase {

    func testCLI() {
        let cli = GenesisCLI()
        XCTAssertEqual(cli.run(arguments: ["genesis"]), 1)
        XCTAssertEqual(cli.run(arguments: ["genesis", "invalid"]), 1)
        XCTAssertEqual(cli.run(arguments: ["generate", "-h"]), 0)
    }
}
