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

final class Test_Deprecated: Test_Runtime {
    // Tests for deprecated code goes here.

    func testDeprecatedValueSetter_valueContainer() throws {
        var container = try OpenAPIValueContainer()
        container.value = "hello"
        XCTAssertEqual(container.value as? String, "hello")
    }

    func testDeprecatedValueSetter_objectContainer() {
        var container = OpenAPIObjectContainer()
        container.value = ["hello": "world"]
        XCTAssertEqual(container.value["hello"] as? String, "world")
        container.value["key"] = 123
        XCTAssertEqual(container.value["key"] as? Int, 123)
    }

    func testDeprecatedValueSetter_arrayContainer() {
        var container = OpenAPIArrayContainer()
        container.value = ["hello", 123]
        XCTAssertEqual(container.value.count, 2)
        XCTAssertEqual(container.value[0] as? String, "hello")
        XCTAssertEqual(container.value[1] as? Int, 123)
    }
}
