//
//  Genesis.swift
//  GenesisCLI
//
//  Created by Yonas Kolb on 7/4/18.
//

import Foundation
import SwiftCLI

public class GenesisCLI {

    public let version: String = "0.1.0"
    let cli: CLI

    public init() {
        let generateCommand = GenerateCommand()
        cli = CLI(name: "genesis", version: version, description: "genesis templater", commands: [
            generateCommand
        ])
        cli.router = SingleCommandRouter(command: generateCommand)
    }

    public func run(arguments: String? = nil) -> Int32 {
        if let arguments = arguments {
            return cli.debugGo(with: arguments)
        } else {
            return cli.go()
        }
    }
}



