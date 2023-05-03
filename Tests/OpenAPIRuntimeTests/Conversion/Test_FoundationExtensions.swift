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
@testable import OpenAPIRuntime

final class Test_FoundationExtensions: Test_Runtime {

    func testURLComponents_addQueryItem_losslessStringConvertible_string() throws {
        var components = testComponents
        components.addQueryItem(name: "key", value: "value")
        XCTAssertEqualURLString(components.url, "/api?key=value")
    }

    func testURLComponents_addQueryItem_losslessStringConvertible_nil() throws {
        var components = testComponents
        let value: String? = nil
        components.addQueryItem(name: "key", value: value)
        XCTAssertEqualURLString(components.url, "/api")
    }

    func testURLComponents_addQueryItem_arrayOfLosslessStringConvertible_strings() throws {
        var components = testComponents
        components.addQueryItem(name: "key", value: ["1", "2"])
        XCTAssertEqualURLString(components.url, "/api?key=1&key=2")
    }

    func testURLComponents_addQueryItem_arrayOfLosslessStringConvertible_nil() throws {
        var components = testComponents
        let values: [String]? = nil
        components.addQueryItem(name: "key", value: values)
        XCTAssertEqualURLString(components.url, "/api")
    }
}
