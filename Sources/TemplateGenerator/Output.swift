//
//  Output.swift
//  TemplateGenerator
//
//  Created by Yonas Kolb on 2/4/18.
//

import Foundation
import Rainbow

public protocol Output {
    func standard(_ string: String)
    func error(_ string: String)
}

public class PrintOutput: Output {

    public init() {

    }
    public func standard(_ string: String) {
        print(string)
    }

    public func error(_ string: String) {
        print(string.red)
    }
}

public class MockOutput: Output {

    var standardStrings: [String] = []
    var errorStrings: [String] = []

    public init() {

    }
    
    public func standard(_ string: String) {
        standardStrings.append(string)
    }

    public func error(_ string: String) {
        errorStrings.append(string)
    }
}
