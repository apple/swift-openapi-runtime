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

final class Test_CurrencyExtensions: Test_Runtime {

    func testHeaderFields_add_string() throws {
        var headerFields: [HeaderField] = []
        headerFields.add(name: "foo", value: "bar")
        XCTAssertEqual(
            headerFields,
            [
                .init(name: "foo", value: "bar")
            ]
        )
    }

    func testHeaderFields_add_nil() throws {
        var headerFields: [HeaderField] = []
        let value: String? = nil
        headerFields.add(name: "foo", value: value)
        XCTAssertEqual(headerFields, [])
    }

    func testHeaderFields_firstValue_found() throws {
        let headerFields: [HeaderField] = [
            .init(name: "foo", value: "bar")
        ]
        XCTAssertEqual(headerFields.firstValue(name: "foo"), "bar")
    }

    func testHeaderFields_firstValue_nil() throws {
        let headerFields: [HeaderField] = []
        XCTAssertNil(headerFields.firstValue(name: "foo"))
    }

    func testHeaderFields_values() throws {
        let headerFields: [HeaderField] = [
            .init(name: "foo", value: "bar"),
            .init(name: "foo", value: "baz"),
        ]
        XCTAssertEqual(headerFields.values(name: "foo"), ["bar", "baz"])
    }

    func testHeaderFields_removeAll_noMatches() throws {
        var headerFields: [HeaderField] = [
            .init(name: "one", value: "one"),
            .init(name: "two", value: "two"),
        ]
        headerFields.removeAll(named: "three")
        XCTAssertEqual(headerFields.map(\.name), ["one", "two"])
    }

    func testHeaderFields_removeAll_oneMatch() throws {
        var headerFields: [HeaderField] = [
            .init(name: "one", value: "one"),
            .init(name: "two", value: "two"),
            .init(name: "three", value: "three"),
        ]
        headerFields.removeAll(named: "three")
        XCTAssertEqual(headerFields.map(\.name), ["one", "two"])
    }

    func testHeaderFields_removeAll_manyMatches() throws {
        var headerFields: [HeaderField] = [
            .init(name: "one", value: "one"),
            .init(name: "three", value: "3"),
            .init(name: "two", value: "two"),
            .init(name: "three", value: "three"),
        ]
        headerFields.removeAll(named: "three")
        XCTAssertEqual(headerFields.map(\.name), ["one", "two"])
    }
}
