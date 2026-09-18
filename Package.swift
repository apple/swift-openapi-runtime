// swift-tools-version: 6.1
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftOpenAPIGenerator open source project
//
// Copyright (c) 2023 Apple Inc. and the SwiftOpenAPIGenerator project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftOpenAPIGenerator project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
import PackageDescription

let package = Package(
    name: "swift-openapi-runtime",
    platforms: [
        .macOS(.v10_15), .macCatalyst(.v13), .iOS(.v13), .tvOS(.v13), .watchOS(.v6), .visionOS(.v1)
    ],
    products: [
        .library(
            name: "OpenAPIRuntime",
            targets: ["OpenAPIRuntime"]
        )
    ],
    traits: [
        .trait(name: "FullFoundation"),
        .trait(name: "OTelSemanticConventions"),
        .trait(name: "Logging", enabledTraits: ["OTelSemanticConventions"]),
        .default(enabledTraits: ["FullFoundation", "Logging"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-http-types", from: "1.0.0"),
        // 1.14.0 is the first release with the task-local `Logger.current`.
        .package(url: "https://github.com/apple/swift-log.git", from: "1.14.0"),
        // 1.34.0 is the earliest release; it already defines every attribute the middlewares log.
        .package(url: "https://github.com/swift-otel/swift-otel-semantic-conventions.git", from: "1.34.0"),
    ],
    targets: [
        .target(
            name: "OpenAPIRuntime",
            dependencies: [
                .product(name: "HTTPTypes", package: "swift-http-types"),
                .product(name: "Logging", package: "swift-log", condition: .when(traits: ["Logging"])),
                .product(name: "OTelSemanticConventions", package: "swift-otel-semantic-conventions", condition: .when(traits: ["OTelSemanticConventions"])),
            ]
        ),
        .testTarget(
            name: "OpenAPIRuntimeTests",
            dependencies: [
                "OpenAPIRuntime",
                .product(name: "Logging", package: "swift-log"),
            ]
        ),
    ]
)

for target in package.targets {
    var settings = target.swiftSettings ?? []

    // https://github.com/apple/swift-evolution/blob/main/proposals/0335-existential-any.md
    // Require `any` for existential types.
    settings.append(.enableUpcomingFeature("ExistentialAny"))

    // https://github.com/swiftlang/swift-evolution/blob/main/proposals/0444-member-import-visibility.md
    settings.append(.enableUpcomingFeature("MemberImportVisibility"))

    // https://github.com/swiftlang/swift-evolution/blob/main/proposals/0409-access-level-on-imports.md
    settings.append(.enableUpcomingFeature("InternalImportsByDefault"))

    target.swiftSettings = settings
}
