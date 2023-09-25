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

    func test_setAcceptHeader() throws {
        var headerFields: [HeaderField] = []
        converter.setAcceptHeader(
            in: &headerFields,
            contentTypes: [.init(contentType: TestAcceptable.json, quality: 0.8)]
        )
        XCTAssertEqual(
            headerFields,
            [
                .init(name: "accept", value: "application/json; q=0.800")
            ]
        )
    }

    // MARK: Converter helper methods

    //    | client | set | request path | URI | required | renderedPath |
    func test_renderedPath_string() throws {
        let renderedPath = try converter.renderedPath(
            template: "/items/{}/detail/{}/habitats/{}",
            parameters: [
                1 as Int,
                "foo" as String,
                [.land, .air] as [TestHabitat],
            ]
        )
        XCTAssertEqual(renderedPath, "/items/1/detail/foo/habitats/land,air")
    }

    //    | client | set | request query | URI | both | setQueryItemAsURI |
    func test_setQueryItemAsURI_string() throws {
        var request = testRequest
        try converter.setQueryItemAsURI(
            in: &request,
            style: nil,
            explode: nil,
            name: "search",
            value: "foo"
        )
        XCTAssertEqual(request.query, "search=foo")
    }

    func test_setQueryItemAsURI_stringConvertible_needsEncoding() throws {
        var request = testRequest
        try converter.setQueryItemAsURI(
            in: &request,
            style: nil,
            explode: nil,
            name: "search",
            value: "h%llo"
        )
        XCTAssertEqual(request.query, "search=h%25llo")
    }

    func test_setQueryItemAsURI_arrayOfStrings() throws {
        var request = testRequest
        try converter.setQueryItemAsURI(
            in: &request,
            style: nil,
            explode: nil,
            name: "search",
            value: ["foo", "bar"]
        )
        XCTAssertEqual(request.query, "search=foo&search=bar")
    }

    func test_setQueryItemAsURI_arrayOfStrings_unexploded() throws {
        var request = testRequest
        try converter.setQueryItemAsURI(
            in: &request,
            style: nil,
            explode: false,
            name: "search",
            value: ["foo", "bar"]
        )
        XCTAssertEqual(request.query, "search=foo,bar")
    }

    func test_setQueryItemAsURI_date() throws {
        var request = testRequest
        try converter.setQueryItemAsURI(
            in: &request,
            style: nil,
            explode: nil,
            name: "search",
            value: testDate
        )
        XCTAssertEqual(request.query, "search=2023-01-18T10%3A04%3A11Z")
    }

    func test_setQueryItemAsURI_arrayOfDates() throws {
        var request = testRequest
        try converter.setQueryItemAsURI(
            in: &request,
            style: nil,
            explode: nil,
            name: "search",
            value: [testDate, testDate]
        )
        XCTAssertEqual(request.query, "search=2023-01-18T10%3A04%3A11Z&search=2023-01-18T10%3A04%3A11Z")
    }

    //    | client | set | request body | string | optional | setOptionalRequestBodyAsString |
    func test_setOptionalRequestBodyAsString_string() throws {
        var headerFields: [HeaderField] = []
        let body = try converter.setOptionalRequestBodyAsString(
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

    //    | client | set | request body | string | required | setRequiredRequestBodyAsString |
    func test_setRequiredRequestBodyAsString_string() throws {
        var headerFields: [HeaderField] = []
        let body = try converter.setRequiredRequestBodyAsString(
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

    func test_setOptionalRequestBodyAsString_date() throws {
        var headerFields: [HeaderField] = []
        let body = try converter.setOptionalRequestBodyAsString(
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

    func test_setRequiredRequestBodyAsString_date() throws {
        var headerFields: [HeaderField] = []
        let body = try converter.setRequiredRequestBodyAsString(
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

    //    | client | set | request body | JSON | optional | setOptionalRequestBodyAsJSON |
    func test_setOptionalRequestBodyAsJSON_codable() throws {
        var headerFields: [HeaderField] = []
        let body = try converter.setOptionalRequestBodyAsJSON(
            testStruct,
            headerFields: &headerFields,
            contentType: "application/json"
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
            contentType: "application/json"
        )
        XCTAssertEqual(body, testQuotedStringData)
        XCTAssertEqual(
            headerFields,
            [
                .init(name: "content-type", value: "application/json")
            ]
        )
    }

    //    | client | set | request body | JSON | required | setRequiredRequestBodyAsJSON |
    func test_setRequiredRequestBodyAsJSON_codable() throws {
        var headerFields: [HeaderField] = []
        let body = try converter.setRequiredRequestBodyAsJSON(
            testStruct,
            headerFields: &headerFields,
            contentType: "application/json"
        )
        XCTAssertEqual(body, testStructPrettyData)
        XCTAssertEqual(
            headerFields,
            [
                .init(name: "content-type", value: "application/json")
            ]
        )
    }

    //    | client | set | request body | urlEncodedForm | codable | optional | setRequiredRequestBodyAsURLEncodedForm |
    func test_setOptionalRequestBodyAsURLEncodedForm_codable() throws {
        var headerFields: [HeaderField] = []
        let body = try converter.setOptionalRequestBodyAsURLEncodedForm(
            testStructDetailed,
            headerFields: &headerFields,
            contentType: "application/x-www-form-urlencoded"
        )

        guard let body else {
            XCTFail("Expected body should not be nil")
            return
        }

        XCTAssertEqualStringifiedData(body, testStructURLFormString)
        XCTAssertEqual(
            headerFields,
            [
                .init(name: "content-type", value: "application/x-www-form-urlencoded")
            ]
        )
    }

    //    | client | set | request body | urlEncodedForm | codable | required | setRequiredRequestBodyAsURLEncodedForm |
    func test_setRequiredRequestBodyAsURLEncodedForm_codable() throws {
        var headerFields: [HeaderField] = []
        let body = try converter.setRequiredRequestBodyAsURLEncodedForm(
            testStructDetailed,
            headerFields: &headerFields,
            contentType: "application/x-www-form-urlencoded"
        )
        XCTAssertEqualStringifiedData(body, testStructURLFormString)
        XCTAssertEqual(
            headerFields,
            [
                .init(name: "content-type", value: "application/x-www-form-urlencoded")
            ]
        )
    }

    //    | client | set | request body | binary | optional | setOptionalRequestBodyAsBinary |
    func test_setOptionalRequestBodyAsBinary_data() throws {
        var headerFields: [HeaderField] = []
        let body = try converter.setOptionalRequestBodyAsBinary(
            testStringData,
            headerFields: &headerFields,
            contentType: "application/octet-stream"
        )
        XCTAssertEqual(body, testStringData)
        XCTAssertEqual(
            headerFields,
            [
                .init(name: "content-type", value: "application/octet-stream")
            ]
        )
    }

    //    | client | set | request body | binary | required | setRequiredRequestBodyAsBinary |
    func test_setRequiredRequestBodyAsBinary_data() throws {
        var headerFields: [HeaderField] = []
        let body = try converter.setRequiredRequestBodyAsBinary(
            testStringData,
            headerFields: &headerFields,
            contentType: "application/octet-stream"
        )
        XCTAssertEqual(body, testStringData)
        XCTAssertEqual(
            headerFields,
            [
                .init(name: "content-type", value: "application/octet-stream")
            ]
        )
    }

    //    | client | get | response body | string | required | getResponseBodyAsString |
    func test_getResponseBodyAsString_stringConvertible() throws {
        let value: String = try converter.getResponseBodyAsString(
            String.self,
            from: testStringData,
            transforming: { $0 }
        )
        XCTAssertEqual(value, testString)
    }

    //    | client | get | response body | string | required | getResponseBodyAsString |
    func test_getResponseBodyAsString_date() throws {
        let value: Date = try converter.getResponseBodyAsString(
            Date.self,
            from: testDateStringData,
            transforming: { $0 }
        )
        XCTAssertEqual(value, testDate)
    }

    //    | client | get | response body | JSON | required | getResponseBodyAsJSON |
    func test_getResponseBodyAsJSON_codable() throws {
        let value: TestPet = try converter.getResponseBodyAsJSON(
            TestPet.self,
            from: testStructData,
            transforming: { $0 }
        )
        XCTAssertEqual(value, testStruct)
    }

    //    | client | get | response body | binary | required | getResponseBodyAsBinary |
    func test_getResponseBodyAsBinary_data() throws {
        let value: Data = try converter.getResponseBodyAsBinary(
            Data.self,
            from: testStringData,
            transforming: { $0 }
        )
        XCTAssertEqual(value, testStringData)
    }
}

public func XCTAssertEqualStringifiedData(
    _ expression1: @autoclosure () throws -> Data,
    _ expression2: @autoclosure () throws -> String,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line
) {
    do {
        let actualString = String(decoding: try expression1(), as: UTF8.self)
        XCTAssertEqual(actualString, try expression2(), file: file, line: line)
    } catch {
        XCTFail(error.localizedDescription, file: file, line: line)
    }
}
