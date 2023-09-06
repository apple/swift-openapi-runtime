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

    func testExtractAccept() throws {
        let headerFields: [HeaderField] = [
            .init(name: "accept", value: "application/json, */*; q=0.8")
        ]
        let accept: [AcceptHeaderContentType<TestAcceptable>] = try converter.extractAcceptHeaderIfPresent(
            in: headerFields
        )
        XCTAssertEqual(
            accept,
            [
                .init(contentType: .json, quality: 1.0),
                .init(contentType: .other("*/*"), quality: 0.8),
            ]
        )
    }

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

    //    | server | get | request path | URI | required | getPathParameterAsURI |
    func test_getPathParameterAsURI_various() throws {
        let path: [String: String] = [
            "foo": "bar",
            "number": "1",
            "habitats": "land,air",
        ]
        do {
            let value = try converter.getPathParameterAsURI(
                in: path,
                name: "foo",
                as: String.self
            )
            XCTAssertEqual(value, "bar")
        }
        do {
            let value = try converter.getPathParameterAsURI(
                in: path,
                name: "number",
                as: Int.self
            )
            XCTAssertEqual(value, 1)
        }
        do {
            let value = try converter.getPathParameterAsURI(
                in: path,
                name: "habitats",
                as: [TestHabitat].self
            )
            XCTAssertEqual(value, [.land, .air])
        }
    }

    //    | server | get | request query | URI | optional | getOptionalQueryItemAsURI |
    func test_getOptionalQueryItemAsURI_string() throws {
        let value: String? = try converter.getOptionalQueryItemAsURI(
            in: "search=foo",
            style: nil,
            explode: nil,
            name: "search",
            as: String.self
        )
        XCTAssertEqual(value, "foo")
    }

    //    | server | get | request query | URI | optional | getOptionalQueryItemAsURI |
    func test_getOptionalQueryItemAsURI_string_nil() throws {
        let value: String? = try converter.getOptionalQueryItemAsURI(
            in: "",
            style: nil,
            explode: nil,
            name: "search",
            as: String.self
        )
        XCTAssertNil(value)
    }

    //    | server | get | request query | URI | optional | getOptionalQueryItemAsURI |
    func test_getOptionalQueryItemAsURI_string_notFound() throws {
        let value: String? = try converter.getOptionalQueryItemAsURI(
            in: "foo=bar",
            style: nil,
            explode: nil,
            name: "search",
            as: String.self
        )
        XCTAssertNil(value)
    }

    //    | server | get | request query | URI | optional | getOptionalQueryItemAsURI |
    func test_getOptionalQueryItemAsURI_string_empty() throws {
        let value: String? = try converter.getOptionalQueryItemAsURI(
            in: "search=",
            style: nil,
            explode: nil,
            name: "search",
            as: String.self
        )
        XCTAssertEqual(value, "")
    }

    //    | server | get | request query | URI | required | getRequiredQueryItemAsURI |
    func test_getRequiredQueryItemAsURI_string() throws {
        let value: String = try converter.getRequiredQueryItemAsURI(
            in: "search=foo",
            style: nil,
            explode: nil,
            name: "search",
            as: String.self
        )
        XCTAssertEqual(value, "foo")
    }

    func test_getOptionalQueryItemAsURI_arrayOfStrings() throws {
        let query = "search=foo&search=bar"
        let value: [String]? = try converter.getOptionalQueryItemAsURI(
            in: query,
            style: nil,
            explode: nil,
            name: "search",
            as: [String].self
        )
        XCTAssertEqual(value, ["foo", "bar"])
    }

    func test_getRequiredQueryItemAsURI_arrayOfStrings() throws {
        let query = "search=foo&search=bar"
        let value: [String] = try converter.getRequiredQueryItemAsURI(
            in: query,
            style: nil,
            explode: nil,
            name: "search",
            as: [String].self
        )
        XCTAssertEqual(value, ["foo", "bar"])
    }

    func test_getRequiredQueryItemAsURI_arrayOfStrings_unexploded() throws {
        let query = "search=foo,bar"
        let value: [String] = try converter.getRequiredQueryItemAsURI(
            in: query,
            style: nil,
            explode: false,
            name: "search",
            as: [String].self
        )
        XCTAssertEqual(value, ["foo", "bar"])
    }

    func test_getOptionalQueryItemAsURI_date() throws {
        let query = "search=\(testDateEscapedString)"
        let value: Date? = try converter.getOptionalQueryItemAsURI(
            in: query,
            style: nil,
            explode: nil,
            name: "search",
            as: Date.self
        )
        XCTAssertEqual(value, testDate)
    }

    func test_getRequiredQueryItemAsURI_arrayOfDates() throws {
        let query = "search=\(testDateEscapedString)&search=\(testDateEscapedString)"
        let value: [Date] = try converter.getRequiredQueryItemAsURI(
            in: query,
            style: nil,
            explode: nil,
            name: "search",
            as: [Date].self
        )
        XCTAssertEqual(value, [testDate, testDate])
    }

    //    | server | get | request body | string | optional | getOptionalRequestBodyAsString |
    func test_getOptionalRequestBodyAsText_string() throws {
        let body: String? = try converter.getOptionalRequestBodyAsString(
            String.self,
            from: testStringData,
            transforming: { $0 }
        )
        XCTAssertEqual(body, testString)
    }

    //    | server | get | request body | string | required | getRequiredRequestBodyAsString |
    func test_getRequiredRequestBodyAsText_stringConvertible() throws {
        let body: String = try converter.getRequiredRequestBodyAsString(
            String.self,
            from: testStringData,
            transforming: { $0 }
        )
        XCTAssertEqual(body, testString)
    }

    func test_getRequiredRequestBodyAsText_date() throws {
        let body: Date = try converter.getRequiredRequestBodyAsString(
            Date.self,
            from: testDateStringData,
            transforming: { $0 }
        )
        XCTAssertEqual(body, testDate)
    }

    //    | server | get | request body | JSON | optional | getOptionalRequestBodyAsJSON |
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

    //    | server | get | request body | JSON | required | getRequiredRequestBodyAsJSON |
    func test_getRequiredRequestBodyAsJSON_codable() throws {
        let body: TestPet = try converter.getRequiredRequestBodyAsJSON(
            TestPet.self,
            from: testStructData,
            transforming: { $0 }
        )
        XCTAssertEqual(body, testStruct)
    }

    //    | server | get | request body | binary | optional | getOptionalRequestBodyAsBinary |
    func test_getOptionalRequestBodyAsBinary_data() throws {
        let body: Data? = try converter.getOptionalRequestBodyAsBinary(
            Data.self,
            from: testStringData,
            transforming: { $0 }
        )
        XCTAssertEqual(body, testStringData)
    }

    //    | server | get | request body | binary | required | getRequiredRequestBodyAsBinary |
    func test_getRequiredRequestBodyAsBinary_data() throws {
        let body: Data = try converter.getRequiredRequestBodyAsBinary(
            Data.self,
            from: testStringData,
            transforming: { $0 }
        )
        XCTAssertEqual(body, testStringData)
    }

    //    | server | set | response body | string | required | setResponseBodyAsString |
    func test_setResponseBodyAsText_stringConvertible() throws {
        var headers: [HeaderField] = []
        let data = try converter.setResponseBodyAsString(
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

    //    | server | set | response body | string | required | setResponseBodyAsString |
    func test_setResponseBodyAsText_date() throws {
        var headers: [HeaderField] = []
        let data = try converter.setResponseBodyAsString(
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

    //    | server | set | response body | JSON | required | setResponseBodyAsJSON |
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

    //    | server | set | response body | binary | required | setResponseBodyAsBinary |
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
