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

    @available(*, deprecated)
    func testURLComponents_addStringQueryItem() throws {
        var components = testComponents
        components.addUnescapedStringQueryItem(name: "key", value: "value", explode: true)
        XCTAssertEqualURLString(components.url, "/api?key=value")
    }

    @available(*, deprecated)
    func testURLComponents_addStringQueryItems() throws {
        var components = testComponents
        components.addUnescapedStringQueryItem(name: "key2", value: "value3", explode: true)
        components.addUnescapedStringQueryItem(name: "key", value: "value1", explode: true)
        components.addUnescapedStringQueryItem(name: "key", value: "value2", explode: true)
        XCTAssertEqualURLString(components.url, "/api?key2=value3&key=value1&key=value2")
    }

    @available(*, deprecated)
    func testURLComponents_addStringQueryItems_unexploded() throws {
        var components = testComponents
        components.addUnescapedStringQueryItem(name: "key2", value: "value3", explode: false)
        components.addUnescapedStringQueryItem(name: "key", value: "value1", explode: false)
        components.addUnescapedStringQueryItem(name: "key", value: "value2", explode: false)
        XCTAssertEqualURLString(components.url, "/api?key2=value3&key=value1,value2")
    }
}
