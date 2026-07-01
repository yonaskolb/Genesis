@testable import GenesisCLI
import SwiftCLI
import XCTest

public class CLITests: XCTestCase {

    func testCLI() {
        let cli = GenesisCLI()
        XCTAssertEqual(cli.run(arguments: [""]), 1)
        XCTAssertEqual(cli.run(arguments: ["invalid"]), 1)
        XCTAssertEqual(cli.run(arguments: ["help"]), 0)
    }

    func testOptionsParserParsesSingleScalarOption() throws {
        let context = try CommandLineOptionsParser.parse("name: Foo")

        XCTAssertEqual(context["name"] as? String, "Foo")
    }

    func testOptionsParserParsesMultipleScalarOptions() throws {
        let context = try CommandLineOptionsParser.parse("name: Foo, enabled: true")

        XCTAssertEqual(context["name"] as? String, "Foo")
        XCTAssertEqual(context["enabled"] as? String, "true")
    }

    func testOptionsParserParsesBracketArrayOption() throws {
        let context = try CommandLineOptionsParser.parse("actions: [tap, refresh, dismiss]")

        XCTAssertEqual(context["actions"] as? [String], ["tap", "refresh", "dismiss"])
    }

    func testOptionsParserPreservesColonInValue() throws {
        let context = try CommandLineOptionsParser.parse("url: https://example.com/path:segment, name: Foo")

        XCTAssertEqual(context["url"] as? String, "https://example.com/path:segment")
        XCTAssertEqual(context["name"] as? String, "Foo")
    }

    func testOptionsParserPreservesEscapedCommaInValue() throws {
        let context = try CommandLineOptionsParser.parse("title: Hello\\, world, name: Foo")

        XCTAssertEqual(context["title"] as? String, "Hello, world")
        XCTAssertEqual(context["name"] as? String, "Foo")
    }

    func testOptionsParserThrowsForMalformedEntry() {
        XCTAssertThrowsError(try CommandLineOptionsParser.parse("name: Foo, malformed")) { error in
            XCTAssertEqual(error as? CommandLineOptionsParserError, .malformedOption("malformed"))
        }
    }

    func testOptionsParserThrowsForDuplicateKey() {
        XCTAssertThrowsError(try CommandLineOptionsParser.parse("actions: tap, actions: refresh")) { error in
            XCTAssertEqual(error as? CommandLineOptionsParserError, .duplicateKey("actions"))
        }
    }
}
