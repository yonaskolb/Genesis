@testable import CLITests
@testable import GeneratorTests
@testable import TemplateTests
import XCTest

XCTMain([
    testCase(GenesisKitTests.allTests),
    testCase(GenesisCLITests.allTests),
])
