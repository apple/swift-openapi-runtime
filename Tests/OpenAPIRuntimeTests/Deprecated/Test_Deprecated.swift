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

final class Test_Deprecated: Test_Runtime {

    //    | client | set | request body | text | string-convertible | optional | setOptionalRequestBodyAsText |
    @available(*, deprecated)
    func test_deprecated_setOptionalRequestBodyAsText_stringConvertible() throws {
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
    @available(*, deprecated)
    func test_deprecated_setRequiredRequestBodyAsText_stringConvertible() throws {
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
    @available(*, deprecated)
    func test_deprecated_setOptionalRequestBodyAsText_date() throws {
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
    @available(*, deprecated)
    func test_deprecated_setRequiredRequestBodyAsText_date() throws {
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
    @available(*, deprecated)
    func test_deprecated_setOptionalRequestBodyAsJSON_codable() throws {
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

    @available(*, deprecated)
    func test_deprecated_setOptionalRequestBodyAsJSON_codable_string() throws {
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
    @available(*, deprecated)
    func test_deprecated_setRequiredRequestBodyAsJSON_codable() throws {
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
    @available(*, deprecated)
    func test_deprecated_setOptionalRequestBodyAsBinary_data() throws {
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
    @available(*, deprecated)
    func test_deprecated_setRequiredRequestBodyAsBinary_data() throws {
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

    @available(*, deprecated)
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

    @available(*, deprecated)
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

    @available(*, deprecated)
    func testValidateContentType_missing() throws {
        let headerFields: [HeaderField] = []
        XCTAssertNoThrow(
            try converter.validateContentTypeIfPresent(
                in: headerFields,
                substring: "application/json"
            )
        )
    }

    @available(*, deprecated)
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

    //    | server | set | response body | text | string-convertible | required | setResponseBodyAsText |
    @available(*, deprecated)
    func test_deprecated_setResponseBodyAsText_stringConvertible() throws {
        var headers: [HeaderField] = []
        let data = try converter.setResponseBodyAsText(
            testString,
            headerFields: &headers,
            transforming: {
                .init(
                    value: $0,
                    contentType: "text/plain"
                )
            }
        )
        XCTAssertEqual(data, testStringData)
        XCTAssertEqual(
            headers,
            [
                .init(name: "content-type", value: "text/plain")
            ]
        )
    }

    //    | server | set | response body | text | date | required | setResponseBodyAsText |
    @available(*, deprecated)
    func test_deprecated_setResponseBodyAsText_date() throws {
        var headers: [HeaderField] = []
        let data = try converter.setResponseBodyAsText(
            testDate,
            headerFields: &headers,
            transforming: {
                .init(
                    value: $0,
                    contentType: "text/plain"
                )
            }
        )
        XCTAssertEqual(data, testDateStringData)
        XCTAssertEqual(
            headers,
            [
                .init(name: "content-type", value: "text/plain")
            ]
        )
    }

    //    | server | set | response body | JSON | codable | required | setResponseBodyAsJSON |
    @available(*, deprecated)
    func test_deprecated_setResponseBodyAsJSON_codable() throws {
        var headers: [HeaderField] = []
        let data = try converter.setResponseBodyAsJSON(
            testStruct,
            headerFields: &headers,
            transforming: {
                .init(
                    value: $0,
                    contentType: "application/json"
                )
            }
        )
        XCTAssertEqual(data, testStructPrettyData)
        XCTAssertEqual(
            headers,
            [
                .init(name: "content-type", value: "application/json")
            ]
        )
    }

    //    | server | set | response body | binary | data | required | setResponseBodyAsBinary |
    @available(*, deprecated)
    func test_deprecated_setResponseBodyAsBinary_data() throws {
        var headers: [HeaderField] = []
        let data = try converter.setResponseBodyAsBinary(
            testStringData,
            headerFields: &headers,
            transforming: {
                .init(
                    value: $0,
                    contentType: "application/octet-stream"
                )
            }
        )
        XCTAssertEqual(data, testStringData)
        XCTAssertEqual(
            headers,
            [
                .init(name: "content-type", value: "application/octet-stream")
            ]
        )
    }

    //    | common | set | header field | text | string-convertible | both | setHeaderFieldAsText |
    @available(*, deprecated)
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
    @available(*, deprecated)
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
    @available(*, deprecated)
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
    @available(*, deprecated)
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

    //    | common | get | header field | text | string-convertible | optional | getOptionalHeaderFieldAsText |
    @available(*, deprecated)
    func test_getOptionalHeaderFieldAsText_stringConvertible() throws {
        let headerFields: [HeaderField] = [
            .init(name: "foo", value: "bar")
        ]
        let value: String? = try converter.getOptionalHeaderFieldAsText(
            in: headerFields,
            name: "foo",
            as: String.self
        )
        XCTAssertEqual(value, "bar")
    }

    //    | common | get | header field | text | string-convertible | required | getRequiredHeaderFieldAsText |
    @available(*, deprecated)
    func test_getRequiredHeaderFieldAsText_stringConvertible() throws {
        let headerFields: [HeaderField] = [
            .init(name: "foo", value: "bar")
        ]
        let value: String = try converter.getRequiredHeaderFieldAsText(
            in: headerFields,
            name: "foo",
            as: String.self
        )
        XCTAssertEqual(value, "bar")
    }

    //    | common | get | header field | text | array of string-convertibles | optional | getOptionalHeaderFieldAsText |
    @available(*, deprecated)
    func test_getOptionalHeaderFieldAsText_arrayOfStringConvertibles() throws {
        let headerFields: [HeaderField] = [
            .init(name: "foo", value: "bar"),
            .init(name: "foo", value: "baz"),
        ]
        let value: [String]? = try converter.getOptionalHeaderFieldAsText(
            in: headerFields,
            name: "foo",
            as: [String].self
        )
        XCTAssertEqual(value, ["bar", "baz"])
    }

    //    | common | get | header field | text | array of string-convertibles | required | getRequiredHeaderFieldAsText |
    @available(*, deprecated)
    func test_getRequiredHeaderFieldAsText_arrayOfStringConvertibles() throws {
        let headerFields: [HeaderField] = [
            .init(name: "foo", value: "bar"),
            .init(name: "foo", value: "baz"),
        ]
        let value: [String] = try converter.getRequiredHeaderFieldAsText(
            in: headerFields,
            name: "foo",
            as: [String].self
        )
        XCTAssertEqual(value, ["bar", "baz"])
    }

    //    | common | get | header field | text | date | optional | getOptionalHeaderFieldAsText |
    @available(*, deprecated)
    func test_getOptionalHeaderFieldAsText_date() throws {
        let headerFields: [HeaderField] = [
            .init(name: "foo", value: testDateString)
        ]
        let value: Date? = try converter.getOptionalHeaderFieldAsText(
            in: headerFields,
            name: "foo",
            as: Date.self
        )
        XCTAssertEqual(value, testDate)
    }

    //    | common | get | header field | text | date | required | getRequiredHeaderFieldAsText |
    @available(*, deprecated)
    func test_getRequiredHeaderFieldAsText_date() throws {
        let headerFields: [HeaderField] = [
            .init(name: "foo", value: testDateString)
        ]
        let value: Date = try converter.getRequiredHeaderFieldAsText(
            in: headerFields,
            name: "foo",
            as: Date.self
        )
        XCTAssertEqual(value, testDate)
    }

    //    | common | get | header field | text | array of dates | optional | getOptionalHeaderFieldAsText |
    @available(*, deprecated)
    func test_getOptionalHeaderFieldAsText_arrayOfDates() throws {
        let headerFields: [HeaderField] = [
            .init(name: "foo", value: testDateString),
            .init(name: "foo", value: testDateString),
        ]
        let value: [Date]? = try converter.getOptionalHeaderFieldAsText(
            in: headerFields,
            name: "foo",
            as: [Date].self
        )
        XCTAssertEqual(value, [testDate, testDate])
    }

    //    | common | get | header field | text | array of dates | required | getRequiredHeaderFieldAsText |
    @available(*, deprecated)
    func test_getRequiredHeaderFieldAsText_arrayOfDates() throws {
        let headerFields: [HeaderField] = [
            .init(name: "foo", value: testDateString),
            .init(name: "foo", value: testDateString),
        ]
        let value: [Date] = try converter.getRequiredHeaderFieldAsText(
            in: headerFields,
            name: "foo",
            as: [Date].self
        )
        XCTAssertEqual(value, [testDate, testDate])
    }

    //    | client | set | request path | text | string-convertible | required | renderedRequestPath |
    @available(*, deprecated)
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
    @available(*, deprecated)
    func test_setQueryItemAsText_stringConvertible() throws {
        var request = testRequest
        try converter.setQueryItemAsText(
            in: &request,
            style: nil,
            explode: nil,
            name: "search",
            value: "foo"
        )
        XCTAssertEqual(request.query, "search=foo")
    }

    @available(*, deprecated)
    func test_setQueryItemAsText_stringConvertible_needsEncoding() throws {
        var request = testRequest
        try converter.setQueryItemAsText(
            in: &request,
            style: nil,
            explode: nil,
            name: "search",
            value: "h%llo"
        )
        XCTAssertEqual(request.query, "search=h%25llo")
    }

    //    | client | set | request query | text | array of string-convertibles | both | setQueryItemAsText |
    @available(*, deprecated)
    func test_setQueryItemAsText_arrayOfStringConvertibles() throws {
        var request = testRequest
        try converter.setQueryItemAsText(
            in: &request,
            style: nil,
            explode: nil,
            name: "search",
            value: ["foo", "bar"]
        )
        XCTAssertEqual(request.query, "search=foo&search=bar")
    }

    //    | client | set | request query | text | array of string-convertibles | both | setQueryItemAsText |
    @available(*, deprecated)
    func test_setQueryItemAsText_arrayOfStringConvertibles_unexploded() throws {
        var request = testRequest
        try converter.setQueryItemAsText(
            in: &request,
            style: nil,
            explode: false,
            name: "search",
            value: ["foo", "bar"]
        )
        XCTAssertEqual(request.query, "search=foo,bar")
    }

    //    | client | set | request query | text | date | both | setQueryItemAsText |
    @available(*, deprecated)
    func test_setQueryItemAsText_date() throws {
        var request = testRequest
        try converter.setQueryItemAsText(
            in: &request,
            style: nil,
            explode: nil,
            name: "search",
            value: testDate
        )
        XCTAssertEqual(request.query, "search=2023-01-18T10:04:11Z")
    }

    //    | client | set | request query | text | array of dates | both | setQueryItemAsText |
    @available(*, deprecated)
    func test_setQueryItemAsText_arrayOfDates() throws {
        var request = testRequest
        try converter.setQueryItemAsText(
            in: &request,
            style: nil,
            explode: nil,
            name: "search",
            value: [testDate, testDate]
        )
        XCTAssertEqual(request.query, "search=2023-01-18T10:04:11Z&search=2023-01-18T10:04:11Z")
    }

    //    | client | set | request body | text | string-convertible | optional | setOptionalRequestBodyAsText |
    @available(*, deprecated)
    func test_setOptionalRequestBodyAsText_stringConvertible() throws {
        var headerFields: [HeaderField] = []
        let body = try converter.setOptionalRequestBodyAsText(
            testString,
            headerFields: &headerFields,
            contentType: "text/plain"
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
    @available(*, deprecated)
    func test_setRequiredRequestBodyAsText_stringConvertible() throws {
        var headerFields: [HeaderField] = []
        let body = try converter.setRequiredRequestBodyAsText(
            testString,
            headerFields: &headerFields,
            contentType: "text/plain"
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
    @available(*, deprecated)
    func test_setOptionalRequestBodyAsText_date() throws {
        var headerFields: [HeaderField] = []
        let body = try converter.setOptionalRequestBodyAsText(
            testDate,
            headerFields: &headerFields,
            contentType: "text/plain"
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
    @available(*, deprecated)
    func test_setRequiredRequestBodyAsText_date() throws {
        var headerFields: [HeaderField] = []
        let body = try converter.setRequiredRequestBodyAsText(
            testDate,
            headerFields: &headerFields,
            contentType: "text/plain"
        )
        XCTAssertEqual(body, testDateStringData)
        XCTAssertEqual(
            headerFields,
            [
                .init(name: "content-type", value: "text/plain")
            ]
        )
    }

    //    | client | get | response body | text | string-convertible | required | getResponseBodyAsText |
    @available(*, deprecated)
    func test_getResponseBodyAsText_stringConvertible() throws {
        let value: String = try converter.getResponseBodyAsText(
            String.self,
            from: testStringData,
            transforming: { $0 }
        )
        XCTAssertEqual(value, testString)
    }

    //    | client | get | response body | text | date | required | getResponseBodyAsText |
    @available(*, deprecated)
    func test_getResponseBodyAsText_date() throws {
        let value: Date = try converter.getResponseBodyAsText(
            Date.self,
            from: testDateStringData,
            transforming: { $0 }
        )
        XCTAssertEqual(value, testDate)
    }

    //    | server | get | request path | text | string-convertible | required | getPathParameterAsText |
    @available(*, deprecated)
    func test_getPathParameterAsText_stringConvertible() throws {
        let path: [String: String] = [
            "foo": "bar"
        ]
        let value: String = try converter.getPathParameterAsText(
            in: path,
            name: "foo",
            as: String.self
        )
        XCTAssertEqual(value, "bar")
    }

    //    | server | get | request query | text | string-convertible | optional | getOptionalQueryItemAsText |
    @available(*, deprecated)
    func test_getOptionalQueryItemAsText_stringConvertible() throws {
        let query: [URLQueryItem] = [
            .init(name: "search", value: "foo")
        ]
        let value: String? = try converter.getOptionalQueryItemAsText(
            in: query,
            style: nil,
            explode: nil,
            name: "search",
            as: String.self
        )
        XCTAssertEqual(value, "foo")
    }

    //    | server | get | request query | text | string-convertible | required | getRequiredQueryItemAsText |
    @available(*, deprecated)
    func test_getRequiredQueryItemAsText_stringConvertible() throws {
        let query: [URLQueryItem] = [
            .init(name: "search", value: "foo")
        ]
        let value: String = try converter.getRequiredQueryItemAsText(
            in: query,
            style: nil,
            explode: nil,
            name: "search",
            as: String.self
        )
        XCTAssertEqual(value, "foo")
    }

    //    | server | get | request query | text | array of string-convertibles | optional | getOptionalQueryItemAsText |
    @available(*, deprecated)
    func test_getOptionalQueryItemAsText_arrayOfStringConvertibles() throws {
        let query: [URLQueryItem] = [
            .init(name: "search", value: "foo"),
            .init(name: "search", value: "bar"),
        ]
        let value: [String]? = try converter.getOptionalQueryItemAsText(
            in: query,
            style: nil,
            explode: nil,
            name: "search",
            as: [String].self
        )
        XCTAssertEqual(value, ["foo", "bar"])
    }

    //    | server | get | request query | text | array of string-convertibles | required | getRequiredQueryItemAsText |
    @available(*, deprecated)
    func test_getRequiredQueryItemAsText_arrayOfStringConvertibles() throws {
        let query: [URLQueryItem] = [
            .init(name: "search", value: "foo"),
            .init(name: "search", value: "bar"),
        ]
        let value: [String] = try converter.getRequiredQueryItemAsText(
            in: query,
            style: nil,
            explode: nil,
            name: "search",
            as: [String].self
        )
        XCTAssertEqual(value, ["foo", "bar"])
    }

    //    | server | get | request query | text | array of string-convertibles | required | getRequiredQueryItemAsText |
    @available(*, deprecated)
    func test_getRequiredQueryItemAsText_arrayOfStringConvertibles_unexploded() throws {
        let query: [URLQueryItem] = [
            .init(name: "search", value: "foo,bar")
        ]
        let value: [String] = try converter.getRequiredQueryItemAsText(
            in: query,
            style: nil,
            explode: false,
            name: "search",
            as: [String].self
        )
        XCTAssertEqual(value, ["foo", "bar"])
    }

    //    | server | get | request query | text | date | optional | getOptionalQueryItemAsText |
    @available(*, deprecated)
    func test_getOptionalQueryItemAsText_date() throws {
        let query: [URLQueryItem] = [
            .init(name: "search", value: testDateString)
        ]
        let value: Date? = try converter.getOptionalQueryItemAsText(
            in: query,
            style: nil,
            explode: nil,
            name: "search",
            as: Date.self
        )
        XCTAssertEqual(value, testDate)
    }

    //    | server | get | request query | text | date | required | getRequiredQueryItemAsText |
    @available(*, deprecated)
    func test_getRequiredQueryItemAsText_date() throws {
        let query: [URLQueryItem] = [
            .init(name: "search", value: testDateString)
        ]
        let value: Date = try converter.getRequiredQueryItemAsText(
            in: query,
            style: nil,
            explode: nil,
            name: "search",
            as: Date.self
        )
        XCTAssertEqual(value, testDate)
    }

    //    | server | get | request query | text | array of dates | optional | getOptionalQueryItemAsText |
    @available(*, deprecated)
    func test_getOptionalQueryItemAsText_arrayOfDates() throws {
        let query: [URLQueryItem] = [
            .init(name: "search", value: testDateString),
            .init(name: "search", value: testDateString),
        ]
        let value: [Date]? = try converter.getOptionalQueryItemAsText(
            in: query,
            style: nil,
            explode: nil,
            name: "search",
            as: [Date].self
        )
        XCTAssertEqual(value, [testDate, testDate])
    }

    //    | server | get | request query | text | array of dates | required | getRequiredQueryItemAsText |
    @available(*, deprecated)
    func test_getRequiredQueryItemAsText_arrayOfDates() throws {
        let query: [URLQueryItem] = [
            .init(name: "search", value: testDateString),
            .init(name: "search", value: testDateString),
        ]
        let value: [Date] = try converter.getRequiredQueryItemAsText(
            in: query,
            style: nil,
            explode: nil,
            name: "search",
            as: [Date].self
        )
        XCTAssertEqual(value, [testDate, testDate])
    }

    //    | server | get | request body | text | string-convertible | optional | getOptionalRequestBodyAsText |
    @available(*, deprecated)
    func test_getOptionalRequestBodyAsText_stringConvertible() throws {
        let body: String? = try converter.getOptionalRequestBodyAsText(
            String.self,
            from: testStringData,
            transforming: { $0 }
        )
        XCTAssertEqual(body, testString)
    }

    //    | server | get | request body | text | string-convertible | required | getRequiredRequestBodyAsText |
    @available(*, deprecated)
    func test_getRequiredRequestBodyAsText_stringConvertible() throws {
        let body: String = try converter.getRequiredRequestBodyAsText(
            String.self,
            from: testStringData,
            transforming: { $0 }
        )
        XCTAssertEqual(body, testString)
    }

    //    | server | get | request body | text | date | optional | getOptionalRequestBodyAsText |
    @available(*, deprecated)
    func test_getOptionalRequestBodyAsText_date() throws {
        let body: Date? = try converter.getOptionalRequestBodyAsText(
            Date.self,
            from: testDateStringData,
            transforming: { $0 }
        )
        XCTAssertEqual(body, testDate)
    }

    //    | server | get | request body | text | date | required | getRequiredRequestBodyAsText |
    @available(*, deprecated)
    func test_getRequiredRequestBodyAsText_date() throws {
        let body: Date = try converter.getRequiredRequestBodyAsText(
            Date.self,
            from: testDateStringData,
            transforming: { $0 }
        )
        XCTAssertEqual(body, testDate)
    }

    //    | server | set | response body | text | string-convertible | required | setResponseBodyAsText |
    @available(*, deprecated)
    func test_setResponseBodyAsText_stringConvertible() throws {
        var headers: [HeaderField] = []
        let data = try converter.setResponseBodyAsText(
            testString,
            headerFields: &headers,
            contentType: "text/plain"
        )
        XCTAssertEqual(data, testStringData)
        XCTAssertEqual(
            headers,
            [
                .init(name: "content-type", value: "text/plain")
            ]
        )
    }

    //    | server | set | response body | text | date | required | setResponseBodyAsText |
    @available(*, deprecated)
    func test_setResponseBodyAsText_date() throws {
        var headers: [HeaderField] = []
        let data = try converter.setResponseBodyAsText(
            testDate,
            headerFields: &headers,
            contentType: "text/plain"
        )
        XCTAssertEqual(data, testDateStringData)
        XCTAssertEqual(
            headers,
            [
                .init(name: "content-type", value: "text/plain")
            ]
        )
    }
}
