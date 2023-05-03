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
@_spi(Generated) import OpenAPIRuntime

final class Test_ClientConverterExtensions: Test_Runtime {

    // MARK: Query - LosslessStringConvertible

    func testQueryAdd_string() throws {
        var request = testRequest
        try converter.queryAdd(
            in: &request,
            name: "search",
            value: "foo"
        )
        XCTAssertEqual(request.query, "search=foo")
    }

    func testQueryAdd_string_needsEncoding() throws {
        var request = testRequest
        try converter.queryAdd(
            in: &request,
            name: "search",
            value: "h%llo"
        )
        XCTAssertEqual(request.query, "search=h%25llo")
    }

    // MARK: Query - Date

    func testQueryAdd_date() throws {
        var request = testRequest
        try converter.queryAdd(
            in: &request,
            name: "since",
            value: testDate
        )
        XCTAssertEqual(request.query, "since=2023-01-18T10:04:11Z")
    }

    // MARK: Query - Array of LosslessStringConvertibles

    func testQueryAdd_arrayOfStrings() throws {
        var request = testRequest
        try converter.queryAdd(
            in: &request,
            name: "id",
            value: ["1", "2"]
        )
        XCTAssertEqual(request.query, "id=1&id=2")
    }

    // MARK: Body

    func testBodyGetComplex_success() throws {
        let body = try converter.bodyGet(
            TestPet.self,
            from: testStructData,
            transforming: { $0 }
        )
        XCTAssertEqual(body, testStruct)
    }

    func testBodyAddComplexOptional_success() throws {
        var headerFields: [HeaderField] = []
        let data = try converter.bodyAddOptional(
            testStruct,
            headerFields: &headerFields,
            transforming: { .init(value: $0, contentType: "application/json") }
        )
        XCTAssertEqual(data, testStructPrettyData)
        XCTAssertEqual(
            headerFields,
            [
                .init(name: "content-type", value: "application/json")
            ]
        )
    }

    func testBodyAddComplexOptional_nil() throws {
        let value: TestPet? = nil
        var headerFields: [HeaderField] = []
        let data = try converter.bodyAddOptional(
            value,
            headerFields: &headerFields,
            transforming: { _ -> EncodableBodyContent<TestPet> in fatalError("Unreachable") }
        )
        XCTAssertNil(data)
        XCTAssertEqual(headerFields, [])
    }

    func testBodyAddComplexRequired_success() throws {
        var headerFields: [HeaderField] = []
        let data = try converter.bodyAddRequired(
            testStruct,
            headerFields: &headerFields,
            transforming: { .init(value: $0, contentType: "application/json") }
        )
        XCTAssertEqual(data, testStructPrettyData)
        XCTAssertEqual(
            headerFields,
            [
                .init(name: "content-type", value: "application/json")
            ]
        )
    }
}
