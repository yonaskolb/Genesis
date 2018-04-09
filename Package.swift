// swift-tools-version:4.0
// Managed by ice

import PackageDescription

let package = Package(
    name: "Genesis",
    products: [
        .executable(name: "genesis", targets: ["Genesis"]),
        .library(name: "GenesisKit", targets: ["GenesisKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/kylef/Stencil", from: "0.11.0"),
        .package(url: "https://github.com/jpsim/Yams", from: "0.7.0"),
        .package(url: "https://github.com/kylef/PathKit", from: "0.8.0"),
        .package(url: "https://github.com/onevcat/Rainbow", from: "3.1.1"),
        .package(url: "https://github.com/jakeheis/SwiftCLI", from: "4.2.0"),
        .package(url: "https://github.com/kylef/Spectre", from: "0.8.0"),
    ],
    targets: [
        .target(name: "Genesis", dependencies: ["GenesisCLI"]),
        .target(name: "GenesisCLI", dependencies: ["GenesisKit", "SwiftCLI"]),
        .target(name: "GenesisKit", dependencies: ["SwiftCLI", "Stencil", "Yams", "PathKit", "Rainbow"]),
        .testTarget(name: "GenesisCLITests", dependencies: ["GenesisCLI", "Spectre"]),
        .testTarget(name: "GenesisKitTests", dependencies: ["GenesisKit", "Spectre"]),
    ]
)
