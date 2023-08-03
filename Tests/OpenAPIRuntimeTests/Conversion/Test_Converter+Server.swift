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

final class Test_ServerConverterExtensions: Test_Runtime {

    // MARK: Miscs

    func testValidateAccept() throws {
        let emptyHeaders: [HeaderField] = []
        let wildcard: [HeaderField] = [
            .init(name: "accept", value: "*/*")
        ]
        let partialWildcard: [HeaderField] = [
            .init(name: "accept", value: "text/*")
        ]
        let short: [HeaderField] = [
            .init(name: "accept", value: "text/plain")
        ]
        let long: [HeaderField] = [
            .init(
                name: "accept",
                value: "text/html, application/xhtml+xml, application/xml;q=0.9, image/webp, */*;q=0.8"
            )
        ]
        let multiple: [HeaderField] = [
            .init(name: "accept", value: "text/plain"),
            .init(name: "accept", value: "application/json"),
        ]
        let cases: [([HeaderField], String, Bool)] = [
            // No Accept header, any string validates successfully
            (emptyHeaders, "foobar", true),

            // Accept: */*, any string validates successfully
            (wildcard, "foobar", true),

            // Accept: text/*, so text/plain succeeds, application/json fails
            (partialWildcard, "text/plain", true),
            (partialWildcard, "application/json", false),

            // Accept: text/plain, text/plain succeeds, application/json fails
            (short, "text/plain", true),
            (short, "application/json", false),

            // A bunch of acceptable content types
            (long, "text/html", true),
            (long, "application/xhtml+xml", true),
            (long, "application/xml", true),
            (long, "image/webp", true),
            (long, "application/json", true),

            // Multiple values
            (multiple, "text/plain", true),
            (multiple, "application/json", true),
            (multiple, "application/xml", false),
        ]
        for (headers, contentType, success) in cases {
            if success {
                XCTAssertNoThrow(
                    try converter.validateAcceptIfPresent(
                        contentType,
                        in: headers
                    ),
                    "Unexpected error when validating string: \(contentType) against headers: \(headers)"
                )
            } else {
                let acceptHeader =
                    headers
                    .values(name: "accept")
                    .joined(separator: ", ")
                XCTAssertThrowsError(
                    try converter.validateAcceptIfPresent(
                        contentType,
                        in: headers
                    ),
                    "Expected to throw error when validating string: \(contentType) against headers: \(headers)",
                    { error in
                        guard
                            let err = error as? RuntimeError,
                            case .unexpectedAcceptHeader(let string) = err
                        else {
                            XCTFail("Threw an unexpected error: \(error)")
                            return
                        }
                        XCTAssertEqual(string, acceptHeader)
                    }
                )
            }
        }
    }

    // MARK: Converter helper methods

    //    | server | get | request path | text | string-convertible | required | getPathParameterAsText |
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
    func test_getOptionalQueryItemAsText_stringConvertible() throws {
        let query: [URLQueryItem] = [
            .init(name: "search", value: "foo")
        ]
        let value: String? = try converter.getOptionalQueryItemAsText(
            in: query,
            name: "search",
            as: String.self
        )
        XCTAssertEqual(value, "foo")
    }

    //    | server | get | request query | text | string-convertible | required | getRequiredQueryItemAsText |
    func test_getRequiredQueryItemAsText_stringConvertible() throws {
        let query: [URLQueryItem] = [
            .init(name: "search", value: "foo")
        ]
        let value: String = try converter.getRequiredQueryItemAsText(
            in: query,
            name: "search",
            as: String.self
        )
        XCTAssertEqual(value, "foo")
    }

    //    | server | get | request query | text | array of string-convertibles | optional | getOptionalQueryItemAsText |
    func test_getOptionalQueryItemAsText_arrayOfStringConvertibles() throws {
        let query: [URLQueryItem] = [
            .init(name: "search", value: "foo"),
            .init(name: "search", value: "bar"),
        ]
        let value: [String]? = try converter.getOptionalQueryItemAsText(
            in: query,
            name: "search",
            as: [String].self
        )
        XCTAssertEqual(value, ["foo", "bar"])
    }

    //    | server | get | request query | text | array of string-convertibles | required | getRequiredQueryItemAsText |
    func test_getRequiredQueryItemAsText_arrayOfStringConvertibles() throws {
        let query: [URLQueryItem] = [
            .init(name: "search", value: "foo"),
            .init(name: "search", value: "bar"),
        ]
        let value: [String] = try converter.getRequiredQueryItemAsText(
            in: query,
            name: "search",
            as: [String].self
        )
        XCTAssertEqual(value, ["foo", "bar"])
    }

    //    | server | get | request query | text | date | optional | getOptionalQueryItemAsText |
    func test_getOptionalQueryItemAsText_date() throws {
        let query: [URLQueryItem] = [
            .init(name: "search", value: testDateString)
        ]
        let value: Date? = try converter.getOptionalQueryItemAsText(
            in: query,
            name: "search",
            as: Date.self
        )
        XCTAssertEqual(value, testDate)
    }

    //    | server | get | request query | text | date | required | getRequiredQueryItemAsText |
    func test_getRequiredQueryItemAsText_date() throws {
        let query: [URLQueryItem] = [
            .init(name: "search", value: testDateString)
        ]
        let value: Date = try converter.getRequiredQueryItemAsText(
            in: query,
            name: "search",
            as: Date.self
        )
        XCTAssertEqual(value, testDate)
    }

    //    | server | get | request query | text | array of dates | optional | getOptionalQueryItemAsText |
    func test_getOptionalQueryItemAsText_arrayOfDates() throws {
        let query: [URLQueryItem] = [
            .init(name: "search", value: testDateString),
            .init(name: "search", value: testDateString),
        ]
        let value: [Date]? = try converter.getOptionalQueryItemAsText(
            in: query,
            name: "search",
            as: [Date].self
        )
        XCTAssertEqual(value, [testDate, testDate])
    }

    //    | server | get | request query | text | array of dates | required | getRequiredQueryItemAsText |
    func test_getRequiredQueryItemAsText_arrayOfDates() throws {
        let query: [URLQueryItem] = [
            .init(name: "search", value: testDateString),
            .init(name: "search", value: testDateString),
        ]
        let value: [Date] = try converter.getRequiredQueryItemAsText(
            in: query,
            name: "search",
            as: [Date].self
        )
        XCTAssertEqual(value, [testDate, testDate])
    }

    //    | server | get | request body | text | string-convertible | optional | getOptionalRequestBodyAsText |
    func test_getOptionalRequestBodyAsText_stringConvertible() throws {
        let body: String? = try converter.getOptionalRequestBodyAsText(
            String.self,
            from: testStringData,
            transforming: { $0 }
        )
        XCTAssertEqual(body, testString)
    }

    //    | server | get | request body | text | string-convertible | required | getRequiredRequestBodyAsText |
    func test_getRequiredRequestBodyAsText_stringConvertible() throws {
        let body: String = try converter.getRequiredRequestBodyAsText(
            String.self,
            from: testStringData,
            transforming: { $0 }
        )
        XCTAssertEqual(body, testString)
    }

    //    | server | get | request body | text | date | optional | getOptionalRequestBodyAsText |
    func test_getOptionalRequestBodyAsText_date() throws {
        let body: Date? = try converter.getOptionalRequestBodyAsText(
            Date.self,
            from: testDateStringData,
            transforming: { $0 }
        )
        XCTAssertEqual(body, testDate)
    }

    //    | server | get | request body | text | date | required | getRequiredRequestBodyAsText |
    func test_getRequiredRequestBodyAsText_date() throws {
        let body: Date = try converter.getRequiredRequestBodyAsText(
            Date.self,
            from: testDateStringData,
            transforming: { $0 }
        )
        XCTAssertEqual(body, testDate)
    }

    //    | server | get | request body | JSON | codable | optional | getOptionalRequestBodyAsJSON |
    func test_getOptionalRequestBodyAsJSON_codable() throws {
        let body: TestPet? = try converter.getOptionalRequestBodyAsJSON(
            TestPet.self,
            from: testStructData,
            transforming: { $0 }
        )
        XCTAssertEqual(body, testStruct)
    }

    func test_getOptionalRequestBodyAsJSON_codable_string() throws {
        let body: String? = try converter.getOptionalRequestBodyAsJSON(
            String.self,
            from: testQuotedStringData,
            transforming: { $0 }
        )
        XCTAssertEqual(body, testString)
    }

    //    | server | get | request body | JSON | codable | required | getRequiredRequestBodyAsJSON |
    func test_getRequiredRequestBodyAsJSON_codable() throws {
        let body: TestPet = try converter.getRequiredRequestBodyAsJSON(
            TestPet.self,
            from: testStructData,
            transforming: { $0 }
        )
        XCTAssertEqual(body, testStruct)
    }

    //    | server | get | request body | binary | data | optional | getOptionalRequestBodyAsBinary |
    func test_getOptionalRequestBodyAsBinary_data() throws {
        let body: Data? = try converter.getOptionalRequestBodyAsBinary(
            Data.self,
            from: testStringData,
            transforming: { $0 }
        )
        XCTAssertEqual(body, testStringData)
    }

    //    | server | get | request body | binary | data | required | getRequiredRequestBodyAsBinary |
    func test_getRequiredRequestBodyAsBinary_data() throws {
        let body: Data = try converter.getRequiredRequestBodyAsBinary(
            Data.self,
            from: testStringData,
            transforming: { $0 }
        )
        XCTAssertEqual(body, testStringData)
    }

    //    | server | set | response body | text | string-convertible | required | setResponseBodyAsText |
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

    //    | server | set | response body | JSON | codable | required | setResponseBodyAsJSON |
    func test_setResponseBodyAsJSON_codable() throws {
        var headers: [HeaderField] = []
        let data = try converter.setResponseBodyAsJSON(
            testStruct,
            headerFields: &headers,
            contentType: "application/json"
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
    func test_setResponseBodyAsBinary_data() throws {
        var headers: [HeaderField] = []
        let data = try converter.setResponseBodyAsBinary(
            testStringData,
            headerFields: &headers,
            contentType: "application/octet-stream"
        )
        XCTAssertEqual(data, testStringData)
        XCTAssertEqual(
            headers,
            [
                .init(name: "content-type", value: "application/octet-stream")
            ]
        )
    }
}
