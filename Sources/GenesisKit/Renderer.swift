//
//  Renderer.swift
//  GenesisKit
//
//  Created by Yonas Kolb on 21/2/19.
//

import Foundation
import Stencil
import PathKit

public protocol Renderer {

    func renderTemplate(name: String, context: Context?) throws -> String
    func renderTemplate(string: String, context: Context?) throws -> String
}

public func stencilRenderer(templatePaths: [Path]) -> Environment {
    let stencilSwiftKitExtension = Extension()
    stencilSwiftKitExtension.registerStencilSwiftExtensions()
    return Environment(
        loader: FileSystemLoader(paths: templatePaths),
        extensions: [stencilSwiftKitExtension],
        templateClass: StencilTemplate.self)
}

extension Environment: Renderer { }

