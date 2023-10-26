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

final class Test_ServerVariable: Test_Runtime {

    func testOnlyConstants() throws {
        XCTAssertEqual(
            try URL(
                validatingOpenAPIServerURL: "https://example.com",
                variables: []
            )
            .absoluteString,
            "https://example.com"
        )
        XCTAssertEqual(
            try URL(
                validatingOpenAPIServerURL: "https://example.com/api",
                variables: []
            )
            .absoluteString,
            "https://example.com/api"
        )
        XCTAssertEqual(
            try URL(
                validatingOpenAPIServerURL: "/api",
                variables: []
            )
            .absoluteString,
            "/api"
        )
    }

    func testVariables() throws {
        XCTAssertEqual(
            try URL(
                validatingOpenAPIServerURL: "https://{subdomain}.example.com:{port}/{baseURL}",
                variables: [
                    .init(name: "subdomain", value: "test"),
                    .init(name: "port", value: "443", allowedValues: ["443", "8443"]),
                    .init(name: "baseURL", value: "v1"),
                ]
            )
            .absoluteString,
            "https://test.example.com:443/v1"
        )
        XCTAssertThrowsError(
            try URL(
                validatingOpenAPIServerURL: "https://{subdomain}.example.com:{port}/{baseURL}",
                variables: [
                    .init(name: "subdomain", value: "test"),
                    .init(name: "port", value: "foo", allowedValues: ["443", "8443"]),
                    .init(name: "baseURL", value: "v1"),
                ]
            ),
            "Should have thrown an error",
            { error in
                guard
                    case let .invalidServerVariableValue(name: name, value: value, allowedValues: allowedValues) = error
                        as? RuntimeError
                else {
                    XCTFail("Expected error, but not this: \(error)")
                    return
                }
                XCTAssertEqual(name, "port")
                XCTAssertEqual(value, "foo")
                XCTAssertEqual(allowedValues, ["443", "8443"])
            }
        )
    }
}
