import XCTest
import GenesisCLI
import SwiftCLI

public class CLITests: XCTestCase {

    func testCLI() {
        let cli = GenesisCLI()
        XCTAssertEqual(cli.run(arguments: "genesis"), 1)
        XCTAssertEqual(cli.run(arguments: "genesis invalid"), 1)
        XCTAssertEqual(cli.run(arguments: "genesis -h"), 0)
    }
}

