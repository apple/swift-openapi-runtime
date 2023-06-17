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

    // MARK: Converter helper methods

    //    | client | set | request path | text | string-convertible | required | renderedRequestPath |
    func test_renderedRequestPath_stringConvertible() throws {
        let renderedPath = try converter.renderedRequestPath(
            template: "/items/{}/detail/{}",
            parameters: [
                1 as Int,
                "foo" as String,
            ]
        )
        XCTAssertEqual(renderedPath, "/items/1/detail/foo")
    }

    //    | client | set | request query | text | string-convertible | both | setQueryItemAsText |
    func test_setQueryItemAsText_stringConvertible() throws {
        var request = testRequest
        try converter.setQueryItemAsText(
            in: &request,
            name: "search",
            value: "foo"
        )
        XCTAssertEqual(request.query, "search=foo")
    }

    func test_setQueryItemAsText_stringConvertible_needsEncoding() throws {
        var request = testRequest
        try converter.setQueryItemAsText(
            in: &request,
            name: "search",
            value: "h%llo"
        )
        XCTAssertEqual(request.query, "search=h%25llo")
    }

    //    | client | set | request query | text | array of string-convertibles | both | setQueryItemAsText |
    func test_setQueryItemAsText_arrayOfStringConvertibles() throws {
        var request = testRequest
        try converter.setQueryItemAsText(
            in: &request,
            name: "search",
            value: ["foo", "bar"]
        )
        XCTAssertEqual(request.query, "search=foo&search=bar")
    }

    //    | client | set | request query | text | date | both | setQueryItemAsText |
    func test_setQueryItemAsText_date() throws {
        var request = testRequest
        try converter.setQueryItemAsText(
            in: &request,
            name: "search",
            value: testDate
        )
        XCTAssertEqual(request.query, "search=2023-01-18T10:04:11Z")
    }

    //    | client | set | request query | text | array of dates | both | setQueryItemAsText |
    func test_setQueryItemAsText_arrayOfDates() throws {
        var request = testRequest
        try converter.setQueryItemAsText(
            in: &request,
            name: "search",
            value: [testDate, testDate]
        )
        XCTAssertEqual(request.query, "search=2023-01-18T10:04:11Z&search=2023-01-18T10:04:11Z")
    }

    //    | client | set | request body | text | string-convertible | optional | setOptionalRequestBodyAsText |
    func test_setOptionalRequestBodyAsText_stringConvertible() throws {
        var headerFields: [HeaderField] = []
        let body = try converter.setOptionalRequestBodyAsText(
            testString,
            headerFields: &headerFields,
            transforming: { value in
                .init(
                    value: value,
                    contentType: "text/plain"
                )
            }
        )
        XCTAssertEqual(body, testStringData)
        XCTAssertEqual(
            headerFields,
            [
                .init(name: "content-type", value: "text/plain")
            ]
        )
    }

    //    | client | set | request body | text | string-convertible | required | setRequiredRequestBodyAsText |
    func test_setRequiredRequestBodyAsText_stringConvertible() throws {
        var headerFields: [HeaderField] = []
        let body = try converter.setRequiredRequestBodyAsText(
            testString,
            headerFields: &headerFields,
            transforming: { value in
                .init(
                    value: value,
                    contentType: "text/plain"
                )
            }
        )
        XCTAssertEqual(body, testStringData)
        XCTAssertEqual(
            headerFields,
            [
                .init(name: "content-type", value: "text/plain")
            ]
        )
    }

    //    | client | set | request body | text | date | optional | setOptionalRequestBodyAsText |
    func test_setOptionalRequestBodyAsText_date() throws {
        var headerFields: [HeaderField] = []
        let body = try converter.setOptionalRequestBodyAsText(
            testDate,
            headerFields: &headerFields,
            transforming: { value in
                .init(
                    value: value,
                    contentType: "text/plain"
                )
            }
        )
        XCTAssertEqual(body, testDateStringData)
        XCTAssertEqual(
            headerFields,
            [
                .init(name: "content-type", value: "text/plain")
            ]
        )
    }

    //    | client | set | request body | text | date | required | setRequiredRequestBodyAsText |
    func test_setRequiredRequestBodyAsText_date() throws {
        var headerFields: [HeaderField] = []
        let body = try converter.setRequiredRequestBodyAsText(
            testDate,
            headerFields: &headerFields,
            transforming: { value in
                .init(
                    value: value,
                    contentType: "text/plain"
                )
            }
        )
        XCTAssertEqual(body, testDateStringData)
        XCTAssertEqual(
            headerFields,
            [
                .init(name: "content-type", value: "text/plain")
            ]
        )
    }

    //    | client | set | request body | JSON | codable | optional | setOptionalRequestBodyAsJSON |
    func test_setOptionalRequestBodyAsJSON_codable() throws {
        var headerFields: [HeaderField] = []
        let body = try converter.setOptionalRequestBodyAsJSON(
            testStruct,
            headerFields: &headerFields,
            transforming: { value in
                .init(
                    value: value,
                    contentType: "application/json"
                )
            }
        )
        XCTAssertEqual(body, testStructPrettyData)
        XCTAssertEqual(
            headerFields,
            [
                .init(name: "content-type", value: "application/json")
            ]
        )
    }

    func test_setOptionalRequestBodyAsJSON_codable_string() throws {
        var headerFields: [HeaderField] = []
        let body = try converter.setOptionalRequestBodyAsJSON(
            testString,
            headerFields: &headerFields,
            transforming: { value in
                .init(
                    value: value,
                    contentType: "application/json"
                )
            }
        )
        XCTAssertEqual(body, testQuotedStringData)
        XCTAssertEqual(
            headerFields,
            [
                .init(name: "content-type", value: "application/json")
            ]
        )
    }

    //    | client | set | request body | JSON | codable | required | setRequiredRequestBodyAsJSON |
    func test_setRequiredRequestBodyAsJSON_codable() throws {
        var headerFields: [HeaderField] = []
        let body = try converter.setRequiredRequestBodyAsJSON(
            testStruct,
            headerFields: &headerFields,
            transforming: { value in
                .init(
                    value: value,
                    contentType: "application/json"
                )
            }
        )
        XCTAssertEqual(body, testStructPrettyData)
        XCTAssertEqual(
            headerFields,
            [
                .init(name: "content-type", value: "application/json")
            ]
        )
    }

    //    | client | set | request body | binary | data | optional | setOptionalRequestBodyAsBinary |
    func test_setOptionalRequestBodyAsBinary_data() throws {
        var headerFields: [HeaderField] = []
        let body = try converter.setOptionalRequestBodyAsBinary(
            testStringData,
            headerFields: &headerFields,
            transforming: { value in
                .init(
                    value: value,
                    contentType: "application/octet-stream"
                )
            }
        )
        XCTAssertEqual(body, testStringData)
        XCTAssertEqual(
            headerFields,
            [
                .init(name: "content-type", value: "application/octet-stream")
            ]
        )
    }

    //    | client | set | request body | binary | data | required | setRequiredRequestBodyAsBinary |
    func test_setRequiredRequestBodyAsBinary_data() throws {
        var headerFields: [HeaderField] = []
        let body = try converter.setRequiredRequestBodyAsBinary(
            testStringData,
            headerFields: &headerFields,
            transforming: { value in
                .init(
                    value: value,
                    contentType: "application/octet-stream"
                )
            }
        )
        XCTAssertEqual(body, testStringData)
        XCTAssertEqual(
            headerFields,
            [
                .init(name: "content-type", value: "application/octet-stream")
            ]
        )
    }

    //    | client | get | response body | text | string-convertible | required | getResponseBodyAsText |
    func test_getResponseBodyAsText_stringConvertible() throws {
        let value: String = try converter.getResponseBodyAsText(
            String.self,
            from: testStringData,
            transforming: { $0 }
        )
        XCTAssertEqual(value, testString)
    }

    //    | client | get | response body | text | date | required | getResponseBodyAsText |
    func test_getResponseBodyAsText_date() throws {
        let value: Date = try converter.getResponseBodyAsText(
            Date.self,
            from: testDateStringData,
            transforming: { $0 }
        )
        XCTAssertEqual(value, testDate)
    }

    //    | client | get | response body | JSON | codable | required | getResponseBodyAsJSON |
    func test_getResponseBodyAsJSON_codable() throws {
        let value: TestPet = try converter.getResponseBodyAsJSON(
            TestPet.self,
            from: testStructData,
            transforming: { $0 }
        )
        XCTAssertEqual(value, testStruct)
    }

    //    | client | get | response body | binary | data | required | getResponseBodyAsBinary |
    func test_getResponseBodyAsBinary_data() throws {
        let value: Data = try converter.getResponseBodyAsBinary(
            Data.self,
            from: testStringData,
            transforming: { $0 }
        )
        XCTAssertEqual(value, testStringData)
    }
}
