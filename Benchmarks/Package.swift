// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "swift-openapi-runtime-benchmarks",
    platforms: [ .macOS("14") ],
    dependencies: [
        .package(name: "swift-openapi-runtime", path: "../"),
        .package(url: "https://github.com/ordo-one/package-benchmark.git", from: "1.22.0"),
    ],
    targets: [
        .executableTarget(
            name: "OpenAPIRuntimeBenchmarks",
            dependencies: [
                .product(name: "Benchmark", package: "package-benchmark"),
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
            ],
            path: "Benchmarks/OpenAPIRuntimeBenchmarks",
            plugins: [
                .plugin(name: "BenchmarkPlugin", package: "package-benchmark")
            ]
        ),
    ]
)
