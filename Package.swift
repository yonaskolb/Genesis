// swift-tools-version:5.0
// Managed by ice

import PackageDescription

let package = Package(
    name: "Genesis",
    products: [
        .executable(name: "genesis", targets: ["Genesis"]),
        .library(name: "GenesisKit", targets: ["GenesisKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/SwiftGen/StencilSwiftKit", from: "2.8.0"),
        .package(url: "https://github.com/jpsim/Yams", from: "5.0.0"),
        .package(url: "https://github.com/kylef/PathKit", from: "1.0.1"),
        .package(url: "https://github.com/onevcat/Rainbow", from: "4.0.1"),
        .package(url: "https://github.com/jakeheis/SwiftCLI", from: "6.0.3"),
    ],
    targets: [
        .target(name: "Genesis", dependencies: ["GenesisCLI"]),
        .target(name: "GenesisCLI", dependencies: ["GenesisKit", "SwiftCLI"]),
        .target(name: "GenesisKit", dependencies: ["SwiftCLI", "StencilSwiftKit", "Yams", "PathKit", "Rainbow"]),
        .testTarget(name: "GenesisCLITests", dependencies: ["GenesisCLI"]),
        .testTarget(name: "GenesisKitTests", dependencies: ["GenesisKit"]),
    ]
)
