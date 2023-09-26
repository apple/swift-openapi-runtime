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
import HTTPTypes

extension HTTPField.Name {
    static var foo: Self {
        Self("foo")!
    }
}

final class Test_CommonConverterExtensions: Test_Runtime {

    // MARK: Miscs

    func testContentTypeMatching() throws {
        let cases: [(received: String, expected: String, isMatch: Bool)] = [
            ("application/json", "application/json", true),
            ("APPLICATION/JSON", "application/json", true),
            ("application/json", "application/*", true),
            ("application/json", "*/*", true),
            ("application/json", "text/*", false),
            ("application/json", "application/xml", false),
            ("application/json", "text/plain", false),

            ("text/plain; charset=UTF-8", "text/plain", true),
            ("TEXT/PLAIN; CHARSET=UTF-8", "text/plain", true),
            ("text/plain; charset=UTF-8", "text/*", true),
            ("text/plain; charset=UTF-8", "*/*", true),
            ("text/plain; charset=UTF-8", "application/*", false),
            ("text/plain; charset=UTF-8", "text/html", false),
        ]
        for testCase in cases {
            XCTAssertEqual(
                try converter.isMatchingContentType(
                    received: .init(testCase.received),
                    expectedRaw: testCase.expected
                ),
                testCase.isMatch,
                "Wrong result for (\(testCase.received), \(testCase.expected), \(testCase.isMatch))"
            )
        }
    }

    // MARK: Converter helper methods

    //    | common | set | header field | URI | both | setHeaderFieldAsURI |
    func test_setHeaderFieldAsURI_string() throws {
        var headerFields: HTTPFields = [:]
        try converter.setHeaderFieldAsURI(
            in: &headerFields,
            name: "foo",
            value: "bar"
        )
        XCTAssertEqual(
            headerFields,
            [
                .foo: "bar"
            ]
        )
    }

    func test_setHeaderFieldAsURI_arrayOfStrings() throws {
        var headerFields: HTTPFields = [:]
        try converter.setHeaderFieldAsURI(
            in: &headerFields,
            name: "foo",
            value: ["bar", "baz"] as [String]
        )
        XCTAssertEqual(
            headerFields,
            [
                .foo: "bar,baz"
            ]
        )
    }

    func test_setHeaderFieldAsURI_date() throws {
        var headerFields: HTTPFields = [:]
        try converter.setHeaderFieldAsURI(
            in: &headerFields,
            name: "foo",
            value: testDate
        )
        XCTAssertEqual(
            headerFields,
            [
                .foo: testDateEscapedString
            ]
        )
    }

    func test_setHeaderFieldAsURI_arrayOfDates() throws {
        var headerFields: HTTPFields = [:]
        try converter.setHeaderFieldAsURI(
            in: &headerFields,
            name: "foo",
            value: [testDate, testDate]
        )
        XCTAssertEqual(
            headerFields,
            [
                .foo: "\(testDateEscapedString),\(testDateEscapedString)"
            ]
        )
    }

    func test_setHeaderFieldAsURI_struct() throws {
        var headerFields: HTTPFields = [:]
        try converter.setHeaderFieldAsURI(
            in: &headerFields,
            name: "foo",
            value: testStruct
        )
        XCTAssertEqual(
            headerFields,
            [
                .foo: "name,Fluffz"
            ]
        )
    }

    //    | common | set | header field | JSON | both | setHeaderFieldAsJSON |
    func test_setHeaderFieldAsJSON_codable() throws {
        var headerFields: HTTPFields = [:]
        try converter.setHeaderFieldAsJSON(
            in: &headerFields,
            name: "foo",
            value: testStruct
        )
        XCTAssertEqual(
            headerFields,
            [
                .foo: testStructString
            ]
        )
    }

    func test_setHeaderFieldAsJSON_codable_string() throws {
        var headerFields: HTTPFields = [:]
        try converter.setHeaderFieldAsJSON(
            in: &headerFields,
            name: "foo",
            value: "hello"
        )
        XCTAssertEqual(
            headerFields,
            [
                .foo: "\"hello\""
            ]
        )
    }

    //    | common | get | header field | URI | optional | getOptionalHeaderFieldAsURI |
    func test_getOptionalHeaderFieldAsURI_string() throws {
        let headerFields: HTTPFields = [
            .foo: "bar"
        ]
        let value: String? = try converter.getOptionalHeaderFieldAsURI(
            in: headerFields,
            name: "foo",
            as: String.self
        )
        XCTAssertEqual(value, "bar")
    }

    //    | common | get | header field | URI | required | getRequiredHeaderFieldAsURI |
    func test_getRequiredHeaderFieldAsURI_stringConvertible() throws {
        let headerFields: HTTPFields = [
            .foo: "bar"
        ]
        let value: String = try converter.getRequiredHeaderFieldAsURI(
            in: headerFields,
            name: "foo",
            as: String.self
        )
        XCTAssertEqual(value, "bar")
    }

    func test_getOptionalHeaderFieldAsURI_arrayOfStrings_singleHeader() throws {
        let headerFields: HTTPFields = [
            .foo: "bar,baz"
        ]
        let value: [String]? = try converter.getOptionalHeaderFieldAsURI(
            in: headerFields,
            name: "foo",
            as: [String].self
        )
        XCTAssertEqual(value, ["bar", "baz"])
    }

    func test_getOptionalHeaderFieldAsURI_date() throws {
        let headerFields: HTTPFields = [
            .foo: testDateEscapedString
        ]
        let value: Date? = try converter.getOptionalHeaderFieldAsURI(
            in: headerFields,
            name: "foo",
            as: Date.self
        )
        XCTAssertEqual(value, testDate)
    }

    func test_getRequiredHeaderFieldAsURI_arrayOfDates() throws {
        let headerFields: HTTPFields = [
            .foo: "\(testDateString),\(testDateEscapedString)"  // escaped and unescaped
        ]
        let value: [Date] = try converter.getRequiredHeaderFieldAsURI(
            in: headerFields,
            name: "foo",
            as: [Date].self
        )
        XCTAssertEqual(value, [testDate, testDate])
    }

    func test_getOptionalHeaderFieldAsURI_struct() throws {
        let headerFields: HTTPFields = [
            .foo: "name,Sprinkles"
        ]
        let value: TestPet? = try converter.getOptionalHeaderFieldAsURI(
            in: headerFields,
            name: "foo",
            as: TestPet.self
        )
        XCTAssertEqual(value, .init(name: "Sprinkles"))
    }

    //    | common | get | header field | JSON | optional | getOptionalHeaderFieldAsJSON |
    func test_getOptionalHeaderFieldAsJSON_codable() throws {
        let headerFields: HTTPFields = [
            .foo: testStructString
        ]
        let value: TestPet? = try converter.getOptionalHeaderFieldAsJSON(
            in: headerFields,
            name: "foo",
            as: TestPet.self
        )
        XCTAssertEqual(value, testStruct)
    }

    //    | common | get | header field | JSON | required | getRequiredHeaderFieldAsJSON |
    func test_getRequiredHeaderFieldAsJSON_codable() throws {
        let headerFields: HTTPFields = [
            .foo: testStructString
        ]
        let value: TestPet = try converter.getRequiredHeaderFieldAsJSON(
            in: headerFields,
            name: "foo",
            as: TestPet.self
        )
        XCTAssertEqual(value, testStruct)
    }
}
