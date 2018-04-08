@testable import CLITests
@testable import GeneratorTests
@testable import TemplateTests
import XCTest

XCTMain([
    testCase(GeneratorTests.allTests),
    testCase(CLITests.allTests),
    testCase(TemplateTests.allTests),
])
