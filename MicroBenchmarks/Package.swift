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
        .package(url: "https://github.com/ordo-one/package-benchmark.git", .upToNextMajor(from: "1.4.0")),
        .package(url: "https://github.com/heckj/AutomergeSwiftAdditions.git", branch: "main"),
    ],

    targets: [
        .target(
            name: "AutomergeMicroBenchmarks",
            dependencies: [
                .product(name: "AutomergeSwiftAdditions", package: "AutomergeSwiftAdditions"),
            ]
        ),
    ]
)

// Benchmark of CodableBenchmarks
package.targets += [
    .executableTarget(
        name: "CodableBenchmarks",
        dependencies: [
            .product(name: "AutomergeSwiftAdditions", package: "AutomergeSwiftAdditions"),
            .product(name: "Benchmark", package: "package-benchmark"),
            .product(name: "BenchmarkPlugin", package: "package-benchmark"),
            .target(name: "AutomergeMicroBenchmarks"),
        ],
        path: "Benchmarks/CodableBenchmarks"
    ),
]
