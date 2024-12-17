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
    // https://github.com/swiftlang/swift-evolution/blob/main/proposals/0335-existential-any.md
    .enableUpcomingFeature("ExistentialAny"),
    // https://github.com/swiftlang/swift-evolution/blob/main/proposals/0409-access-level-on-imports.md
    .enableUpcomingFeature("InternalImportsByDefault"),
    .enableExperimentalFeature("AccessLevelOnImport"),
    // https://github.com/swiftlang/swift-evolution/blob/main/proposals/0444-member-import-visibility.md
    .enableUpcomingFeature("MemberImportVisibility"),
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

// ---    STANDARD CROSS-REPO SETTINGS DO NOT EDIT   --- //
for target in package.targets {
    if target.type != .plugin {
        var settings = target.swiftSettings ?? []
        // https://github.com/swiftlang/swift-evolution/blob/main/proposals/0444-member-import-visibility.md
        settings.append(.enableUpcomingFeature("MemberImportVisibility"))
        target.swiftSettings = settings
    }
}
// --- END: STANDARD CROSS-REPO SETTINGS DO NOT EDIT --- //
