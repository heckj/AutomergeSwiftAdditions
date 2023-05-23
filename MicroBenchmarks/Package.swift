// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "AutomergeMicroBenchmarks",
    platforms: [.macOS(.v13)],

    products: [
        .library(
            name: "AutomergeMicroBenchmarks",
            targets: ["AutomergeMicroBenchmarks"]
        ),
    ],

    dependencies: [
        .package(url: "https://github.com/ordo-one/package-benchmark", .upToNextMajor(from: "1.4.0")),
        .package(path: "../"),
    ],

    targets: [
        .target(
            name: "AutomergeMicroBenchmarks",
            dependencies: []
        )
    ]
)

// Benchmark of CodableBenchmarks
package.targets += [
    .executableTarget(
        name: "CodableBenchmarks",
        dependencies: [
            .product(name: "Benchmark", package: "package-benchmark"),
            .product(name: "BenchmarkPlugin", package: "package-benchmark")
        ],
        path: "Benchmarks/CodableBenchmarks"
    ),
]
