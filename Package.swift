// swift-tools-version: 5.9
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

// General Swift-settings for all targets.
let swiftSettings: [SwiftSetting] = [
    // https://github.com/apple/swift-evolution/blob/main/proposals/0335-existential-any.md
    // Require `any` for existential types.
    .enableUpcomingFeature("ExistentialAny")
]

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
    dependencies: [
        .package(url: "https://github.com/apple/swift-http-types", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "OpenAPIRuntime",
            dependencies: [
                .product(name: "HTTPTypes", package: "swift-http-types")
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "OpenAPIRuntimeTests",
            dependencies: ["OpenAPIRuntime"],
            swiftSettings: swiftSettings
        ),
    ]
)
