// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AutomergeSwiftAdditions",
    platforms: [.iOS(.v14), .macOS(.v12)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "AutomergeSwiftAdditions",
            targets: ["AutomergeSwiftAdditions"]
        ),
        .executable(name: "AMInspector", targets: ["AMInspector"]),
    ],
    dependencies: [
        .package(url: "https://github.com/automerge/automerge-swift", branch: "alpha0.5.0"),
        .package(url: "https://github.com/onevcat/Rainbow", from: "4.0.0"),
        .package(url: "https://github.com/outfoxx/PotentCodables", from: "3.1.0"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "AutomergeSwiftAdditions",
            dependencies: [
                .product(name: "Automerge", package: "automerge-swift"),
            ]
        ),
        .testTarget(
            name: "AutomergeSwiftAdditionsTests",
            dependencies: [
                "AutomergeSwiftAdditions",
                .product(name: "Automerge", package: "automerge-swift"),
            ]
        ),
        .executableTarget(
            name: "AMInspector",
            dependencies: [
                .product(name: "Automerge", package: "automerge-swift"),
                .product(name: "Rainbow", package: "Rainbow"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "PotentCodables", package: "PotentCodables"),
            ]
        ),
    ]
)
