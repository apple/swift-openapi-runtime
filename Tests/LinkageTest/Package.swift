// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "linkage-test",
    platforms: [
        .macOS(.v10_15), .macCatalyst(.v13), .iOS(.v13), .tvOS(.v13), .watchOS(.v6), .visionOS(.v1)
    ],
    dependencies: [
        // Disable default traits to show that it's possible to link the core library without full Foundation on Linux.
        .package(name: "swift-openapi-runtime", path: "../..", traits: [])
    ],
    targets: [
        .executableTarget(
            name: "linkageTest",
            dependencies: [
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime")
            ]
        )
    ]
)