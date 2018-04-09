import Foundation
import SwiftCLI

public class GenesisCLI {

    public let version = "0.2.0"
    let cli: CLI
    let stream: Streams

    public init(stream: Streams = .default) {
        self.stream = stream
        let generateCommand = GenerateCommand(stream: stream)
        cli = CLI(name: "genesis", version: version, description: "genesis templater", commands: [
            generateCommand,
        ])
//        cli.router = SingleCommandRouter(command: generateCommand)
    }

    public func run(arguments: String? = nil) -> Int32 {
        if let arguments = arguments {
            return cli.debugGo(with: arguments)
        } else {
            return cli.go()
        }
    }
}
