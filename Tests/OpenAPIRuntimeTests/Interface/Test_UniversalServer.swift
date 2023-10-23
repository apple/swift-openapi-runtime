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
import XCTest
@_spi(Generated) @testable import OpenAPIRuntime

final class Test_UniversalServer: Test_Runtime {

    struct MockHandler: Sendable {}

    func testApiPathComponentsWithServerPrefix_noPrefix() throws {
        let server = UniversalServer(
            handler: MockHandler()
        )
        let components = "/foo/{bar}"
        let prefixed = try server.apiPathComponentsWithServerPrefix(components)
        // When no server path prefix, components stay the same
        XCTAssertEqual(prefixed, components)
    }

    func testApiPathComponentsWithServerPrefix_withPrefix() throws {
        let server = UniversalServer(
            serverURL: try serverURL,
            handler: MockHandler()
        )
        let components = "/foo/{bar}"
        let prefixed = try server.apiPathComponentsWithServerPrefix(components)
        let expected = "/api/foo/{bar}"
        XCTAssertEqual(prefixed, expected)
    }
}
