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

final class Test_CommonConverterExtensions: Test_Runtime {

    // MARK: Miscs

    func testValidateContentType_match() throws {
        let headerFields: [HeaderField] = [
            .init(name: "content-type", value: "application/json")
        ]
        XCTAssertNoThrow(
            try converter.validateContentTypeIfPresent(
                in: headerFields,
                substring: "application/json"
            )
        )
    }

    func testValidateContentType_match_substring() throws {
        let headerFields: [HeaderField] = [
            .init(name: "content-type", value: "application/json; charset=utf-8")
        ]
        XCTAssertNoThrow(
            try converter.validateContentTypeIfPresent(
                in: headerFields,
                substring: "application/json"
            )
        )
    }

    func testValidateContentType_missing() throws {
        let headerFields: [HeaderField] = []
        XCTAssertNoThrow(
            try converter.validateContentTypeIfPresent(
                in: headerFields,
                substring: "application/json"
            )
        )
    }

    func testValidateContentType_mismatch() throws {
        let headerFields: [HeaderField] = [
            .init(name: "content-type", value: "text/plain")
        ]
        XCTAssertThrowsError(
            try converter.validateContentTypeIfPresent(
                in: headerFields,
                substring: "application/json"
            ),
            "Was expected to throw error on mismatch",
            { error in
                guard
                    let err = error as? RuntimeError,
                    case .unexpectedContentTypeHeader(let contentType) = err
                else {
                    XCTFail("Unexpected kind of error thrown")
                    return
                }
                XCTAssertEqual(contentType, "text/plain")
            }
        )
    }

    // MARK: Converter helper methods

    //    | common | set | header field | text | string-convertible | both | setHeaderFieldAsText |
    func test_setHeaderFieldAsText_stringConvertible() throws {
        var headerFields: [HeaderField] = []
        try converter.setHeaderFieldAsText(
            in: &headerFields,
            name: "foo",
            value: "bar"
        )
        XCTAssertEqual(
            headerFields,
            [
                .init(name: "foo", value: "bar")
            ]
        )
    }

    //    | common | set | header field | text | array of string-convertibles | both | setHeaderFieldAsText |
    func test_setHeaderFieldAsText_arrayOfStringConvertible() throws {
        var headerFields: [HeaderField] = []
        try converter.setHeaderFieldAsText(
            in: &headerFields,
            name: "foo",
            value: ["bar", "baz"] as [String]
        )
        XCTAssertEqual(
            headerFields,
            [
                .init(name: "foo", value: "bar"),
                .init(name: "foo", value: "baz"),
            ]
        )
    }

    //    | common | set | header field | text | date | both | setHeaderFieldAsText |
    func test_setHeaderFieldAsText_date() throws {
        var headerFields: [HeaderField] = []
        try converter.setHeaderFieldAsText(
            in: &headerFields,
            name: "foo",
            value: testDate
        )
        XCTAssertEqual(
            headerFields,
            [
                .init(name: "foo", value: testDateString)
            ]
        )
    }

    //    | common | set | header field | text | array of dates | both | setHeaderFieldAsText |
    func test_setHeaderFieldAsText_arrayOfDates() throws {
        var headerFields: [HeaderField] = []
        try converter.setHeaderFieldAsText(
            in: &headerFields,
            name: "foo",
            value: [testDate, testDate]
        )
        XCTAssertEqual(
            headerFields,
            [
                .init(name: "foo", value: testDateString),
                .init(name: "foo", value: testDateString),
            ]
        )
    }

    //    | common | set | header field | JSON | codable | both | setHeaderFieldAsJSON |
    func test_setHeaderFieldAsJSON_codable() throws {
        var headerFields: [HeaderField] = []
        try converter.setHeaderFieldAsJSON(
            in: &headerFields,
            name: "foo",
            value: testStruct
        )
        XCTAssertEqual(
            headerFields,
            [
                .init(name: "foo", value: testStructString)
            ]
        )
    }

    func test_setHeaderFieldAsJSON_codable_string() throws {
        var headerFields: [HeaderField] = []
        try converter.setHeaderFieldAsJSON(
            in: &headerFields,
            name: "foo",
            value: "hello"
        )
        XCTAssertEqual(
            headerFields,
            [
                .init(name: "foo", value: "\"hello\"")
            ]
        )
    }

    //    | common | get | header field | text | string-convertible | optional | getOptionalHeaderFieldAsText |
    func test_getOptionalHeaderFieldAsText_stringConvertible() throws {
        let headerFields: [HeaderField] = [
            .init(name: "foo", value: "bar")
        ]
        let value = try converter.getOptionalHeaderFieldAsText(
            in: headerFields,
            name: "foo",
            as: String.self
        )
        XCTAssertEqual(value, "bar")
    }

    //    | common | get | header field | text | string-convertible | required | getRequiredHeaderFieldAsText |
    func test_getRequiredHeaderFieldAsText_stringConvertible() throws {
        let headerFields: [HeaderField] = [
            .init(name: "foo", value: "bar")
        ]
        let value = try converter.getRequiredHeaderFieldAsText(
            in: headerFields,
            name: "foo",
            as: String.self
        )
        XCTAssertEqual(value, "bar")
    }

    //    | common | get | header field | text | array of string-convertibles | optional | getOptionalHeaderFieldAsText |
    func test_getOptionalHeaderFieldAsText_arrayOfStringConvertibles() throws {
        let headerFields: [HeaderField] = [
            .init(name: "foo", value: "bar"),
            .init(name: "foo", value: "baz"),
        ]
        let value = try converter.getOptionalHeaderFieldAsText(
            in: headerFields,
            name: "foo",
            as: [String].self
        )
        XCTAssertEqual(value, ["bar", "baz"])
    }

    //    | common | get | header field | text | array of string-convertibles | required | getRequiredHeaderFieldAsText |
    func test_getRequiredHeaderFieldAsText_arrayOfStringConvertibles() throws {
        let headerFields: [HeaderField] = [
            .init(name: "foo", value: "bar"),
            .init(name: "foo", value: "baz"),
        ]
        let value = try converter.getRequiredHeaderFieldAsText(
            in: headerFields,
            name: "foo",
            as: [String].self
        )
        XCTAssertEqual(value, ["bar", "baz"])
    }

    //    | common | get | header field | text | date | optional | getOptionalHeaderFieldAsText |
    func test_getOptionalHeaderFieldAsText_date() throws {
        let headerFields: [HeaderField] = [
            .init(name: "foo", value: testDateString)
        ]
        let value = try converter.getOptionalHeaderFieldAsText(
            in: headerFields,
            name: "foo",
            as: Date.self
        )
        XCTAssertEqual(value, testDate)
    }

    //    | common | get | header field | text | date | required | getRequiredHeaderFieldAsText |
    func test_getRequiredHeaderFieldAsText_date() throws {
        let headerFields: [HeaderField] = [
            .init(name: "foo", value: testDateString)
        ]
        let value = try converter.getRequiredHeaderFieldAsText(
            in: headerFields,
            name: "foo",
            as: Date.self
        )
        XCTAssertEqual(value, testDate)
    }

    //    | common | get | header field | text | array of dates | optional | getOptionalHeaderFieldAsText |
    func test_getOptionalHeaderFieldAsText_arrayOfDates() throws {
        let headerFields: [HeaderField] = [
            .init(name: "foo", value: testDateString),
            .init(name: "foo", value: testDateString),
        ]
        let value = try converter.getOptionalHeaderFieldAsText(
            in: headerFields,
            name: "foo",
            as: [Date].self
        )
        XCTAssertEqual(value, [testDate, testDate])
    }

    //    | common | get | header field | text | array of dates | required | getRequiredHeaderFieldAsText |
    func test_getRequiredHeaderFieldAsText_arrayOfDates() throws {
        let headerFields: [HeaderField] = [
            .init(name: "foo", value: testDateString),
            .init(name: "foo", value: testDateString),
        ]
        let value = try converter.getRequiredHeaderFieldAsText(
            in: headerFields,
            name: "foo",
            as: [Date].self
        )
        XCTAssertEqual(value, [testDate, testDate])
    }

    //    | common | get | header field | JSON | codable | optional | getOptionalHeaderFieldAsJSON |
    func test_getOptionalHeaderFieldAsJSON_codable() throws {
        let headerFields: [HeaderField] = [
            .init(name: "foo", value: testStructString)
        ]
        let value = try converter.getOptionalHeaderFieldAsJSON(
            in: headerFields,
            name: "foo",
            as: TestPet.self
        )
        XCTAssertEqual(value, testStruct)
    }

    //    | common | get | header field | JSON | codable | required | getRequiredHeaderFieldAsJSON |
    func test_getRequiredHeaderFieldAsJSON_codable() throws {
        let headerFields: [HeaderField] = [
            .init(name: "foo", value: testStructString)
        ]
        let value = try converter.getRequiredHeaderFieldAsJSON(
            in: headerFields,
            name: "foo",
            as: TestPet.self
        )
        XCTAssertEqual(value, testStruct)
    }
}
