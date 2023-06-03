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
@_spi(Generated)@testable import OpenAPIRuntime

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

    func testBodyGetStruct_strategyCodable_success() throws {
        let body = try converter.bodyGet(
            TestPet.self,
            from: testStructData,
            strategy: .codable,
            transforming: { $0 }
        )
        XCTAssertEqual(body, testStruct)
    }

    func testBodyGetData_strategyData_success() throws {
        let body = try converter.bodyGet(
            Data.self,
            from: testStructData,
            strategy: .data,
            transforming: { $0 }
        )
        XCTAssertEqual(body, testStructData)
    }

    func testBodyGetString_strategyData_success() throws {
        let body = try converter.bodyGet(
            String.self,
            from: testQuotedStringData,
            strategy: .data,
            transforming: { $0 }
        )
        XCTAssertEqual(body, testString)
    }

    func testBodyGetString_strategyCodable_success() throws {
        let body = try converter.bodyGet(
            String.self,
            from: testQuotedStringData,
            strategy: .codable,
            transforming: { $0 }
        )
        XCTAssertEqual(body, testString)
    }

    func testBodyGetString_strategyString_success() throws {
        let body = try converter.bodyGet(
            String.self,
            from: testStringData,
            strategy: .string,
            transforming: { $0 }
        )
        XCTAssertEqual(body, testString)
    }

    func testBodyGetString_strategyInt_failure() throws {
        XCTAssertThrowsError(
            try converter.bodyGet(
                Int.self,
                from: testStringData,
                strategy: .string,
                transforming: { $0 }
            ),
            "Was expected to throw error on invalid int",
            { error in
                guard
                    let err = error as? RuntimeError,
                    case .failedToDecodeBody(let type) = err
                else {
                    XCTFail("Unexpected kind of error thrown")
                    return
                }
                XCTAssertEqual("\(type)", "\(Int.self)")
            }
        )
    }

    func testBodyAddComplexOptional_success() throws {
        var headerFields: [HeaderField] = []
        let data = try converter.bodyAddOptional(
            testStruct,
            headerFields: &headerFields,
            transforming: {
                .init(
                    value: $0,
                    contentType: "application/json",
                    strategy: .codable
                )
            }
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
            transforming: {
                .init(
                    value: $0,
                    contentType: "application/json",
                    strategy: .codable
                )
            }
        )
        XCTAssertEqual(data, testStructPrettyData)
        XCTAssertEqual(
            headerFields,
            [
                .init(name: "content-type", value: "application/json")
            ]
        )
    }

    func testBodyAddDataOptional_success() throws {
        var headerFields: [HeaderField] = []
        let data = try converter.bodyAddOptional(
            testStructPrettyData,
            headerFields: &headerFields,
            transforming: {
                .init(
                    value: $0,
                    contentType: "application/octet-stream",
                    strategy: .data
                )
            }
        )
        XCTAssertEqual(data, testStructPrettyData)
        XCTAssertEqual(
            headerFields,
            [
                .init(name: "content-type", value: "application/octet-stream")
            ]
        )
    }

    func testBodyAddDataOptional_nil() throws {
        let value: Data? = nil
        var headerFields: [HeaderField] = []
        let data = try converter.bodyAddOptional(
            value,
            headerFields: &headerFields,
            transforming: { _ -> EncodableBodyContent<Data> in fatalError("Unreachable") }
        )
        XCTAssertNil(data)
        XCTAssertEqual(headerFields, [])
    }

    func testBodyAddDataRequired_success() throws {
        var headerFields: [HeaderField] = []
        let data = try converter.bodyAddRequired(
            testStructPrettyData,
            headerFields: &headerFields,
            transforming: {
                .init(
                    value: $0,
                    contentType: "application/octet-stream",
                    strategy: .data
                )
            }
        )
        XCTAssertEqual(data, testStructPrettyData)
        XCTAssertEqual(
            headerFields,
            [
                .init(name: "content-type", value: "application/octet-stream")
            ]
        )
    }

    func testBodyAddStringOptional_strategyString_success() throws {
        var headerFields: [HeaderField] = []
        let data = try converter.bodyAddOptional(
            testString,
            headerFields: &headerFields,
            transforming: {
                .init(
                    value: $0,
                    contentType: "text/plain",
                    strategy: .string
                )
            }
        )
        XCTAssertEqual(data, testStringData)
        XCTAssertEqual(
            headerFields,
            [
                .init(name: "content-type", value: "text/plain")
            ]
        )
    }

    func testBodyAddStringOptional_strategyCodable_success() throws {
        var headerFields: [HeaderField] = []
        let data = try converter.bodyAddOptional(
            testString,
            headerFields: &headerFields,
            transforming: {
                .init(
                    value: $0,
                    contentType: "text/plain",
                    strategy: .codable
                )
            }
        )
        XCTAssertEqual(data, testQuotedStringData)
        XCTAssertEqual(
            headerFields,
            [
                .init(name: "content-type", value: "text/plain")
            ]
        )
    }

    func testBodyAddStringRequired_strategyString_success() throws {
        var headerFields: [HeaderField] = []
        let data = try converter.bodyAddRequired(
            testString,
            headerFields: &headerFields,
            transforming: {
                .init(
                    value: $0,
                    contentType: "text/plain",
                    strategy: .string
                )
            }
        )
        XCTAssertEqual(data, testStringData)
        XCTAssertEqual(
            headerFields,
            [
                .init(name: "content-type", value: "text/plain")
            ]
        )
    }

    func testBodyAddStringRequired_strategyCodable_success() throws {
        var headerFields: [HeaderField] = []
        let data = try converter.bodyAddRequired(
            testString,
            headerFields: &headerFields,
            transforming: {
                .init(
                    value: $0,
                    contentType: "text/plain",
                    strategy: .codable
                )
            }
        )
        XCTAssertEqual(data, testQuotedStringData)
        XCTAssertEqual(
            headerFields,
            [
                .init(name: "content-type", value: "text/plain")
            ]
        )
    }
}
