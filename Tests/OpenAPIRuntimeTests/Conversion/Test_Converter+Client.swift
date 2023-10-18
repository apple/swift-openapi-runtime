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

final class Test_ClientConverterExtensions: Test_Runtime {

    func test_setAcceptHeader() throws {
        var headerFields: HTTPFields = [:]
        converter.setAcceptHeader(
            in: &headerFields,
            contentTypes: [.init(contentType: TestAcceptable.json, quality: 0.8)]
        )
        XCTAssertEqual(
            headerFields,
            [
                .accept: "application/json; q=0.800"
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
        XCTAssertEqual(request.soar_query, "search=foo")
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
        XCTAssertEqual(request.soar_query, "search=h%25llo")
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
        XCTAssertEqual(request.soar_query, "search=foo&search=bar")
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
        XCTAssertEqual(request.soar_query, "search=foo,bar")
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
        XCTAssertEqual(request.soar_query, "search=2023-01-18T10%3A04%3A11Z")
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
        XCTAssertEqual(request.soar_query, "search=2023-01-18T10%3A04%3A11Z&search=2023-01-18T10%3A04%3A11Z")
    }

    //    | client | set | request body | JSON | optional | setOptionalRequestBodyAsJSON |
    func test_setOptionalRequestBodyAsJSON_codable() async throws {
        var headerFields: HTTPFields = [:]
        let body = try converter.setOptionalRequestBodyAsJSON(
            testStruct,
            headerFields: &headerFields,
            contentType: "application/json"
        )
        try await XCTAssertEqualStringifiedData(body, testStructPrettyString)
        XCTAssertEqual(
            headerFields,
            [
                .contentType: "application/json"
            ]
        )
    }

    func test_setOptionalRequestBodyAsJSON_codable_string() async throws {
        var headerFields: HTTPFields = [:]
        let body = try converter.setOptionalRequestBodyAsJSON(
            testString,
            headerFields: &headerFields,
            contentType: "application/json"
        )
        try await XCTAssertEqualStringifiedData(body, testQuotedString)
        XCTAssertEqual(
            headerFields,
            [
                .contentType: "application/json"
            ]
        )
    }

    //    | client | set | request body | JSON | required | setRequiredRequestBodyAsJSON |
    func test_setRequiredRequestBodyAsJSON_codable() async throws {
        var headerFields: HTTPFields = [:]
        let body = try converter.setRequiredRequestBodyAsJSON(
            testStruct,
            headerFields: &headerFields,
            contentType: "application/json"
        )
        try await XCTAssertEqualStringifiedData(body, testStructPrettyString)
        XCTAssertEqual(
            headerFields,
            [
                .contentType: "application/json"
            ]
        )
    }

    //    | client | set | request body | urlEncodedForm | codable | optional | setRequiredRequestBodyAsURLEncodedForm |
    func test_setOptionalRequestBodyAsURLEncodedForm_codable() async throws {
        var headerFields: HTTPFields = [:]
        let body = try converter.setOptionalRequestBodyAsURLEncodedForm(
            testStructDetailed,
            headerFields: &headerFields,
            contentType: "application/x-www-form-urlencoded"
        )

        guard let body else {
            XCTFail("Expected body should not be nil")
            return
        }

        try await XCTAssertEqualStringifiedData(body, testStructURLFormString)
        XCTAssertEqual(
            headerFields,
            [
                .contentType: "application/x-www-form-urlencoded"
            ]
        )
    }

    //    | client | set | request body | urlEncodedForm | codable | required | setRequiredRequestBodyAsURLEncodedForm |
    func test_setRequiredRequestBodyAsURLEncodedForm_codable() async throws {
        var headerFields: HTTPFields = [:]
        let body = try converter.setRequiredRequestBodyAsURLEncodedForm(
            testStructDetailed,
            headerFields: &headerFields,
            contentType: "application/x-www-form-urlencoded"
        )
        try await XCTAssertEqualStringifiedData(body, testStructURLFormString)
        XCTAssertEqual(
            headerFields,
            [
                .contentType: "application/x-www-form-urlencoded"
            ]
        )
    }

    //    | client | set | request body | binary | optional | setOptionalRequestBodyAsBinary |
    func test_setOptionalRequestBodyAsBinary_data() async throws {
        var headerFields: HTTPFields = [:]
        let body = try converter.setOptionalRequestBodyAsBinary(
            .init(testStringData),
            headerFields: &headerFields,
            contentType: "application/octet-stream"
        )
        try await XCTAssertEqualStringifiedData(body, testString)
        XCTAssertEqual(
            headerFields,
            [
                .contentType: "application/octet-stream"
            ]
        )
    }

    //    | client | set | request body | binary | required | setRequiredRequestBodyAsBinary |
    func test_setRequiredRequestBodyAsBinary_data() async throws {
        var headerFields: HTTPFields = [:]
        let body = try converter.setRequiredRequestBodyAsBinary(
            .init(testString),
            headerFields: &headerFields,
            contentType: "application/octet-stream"
        )
        try await XCTAssertEqualStringifiedData(body, testString)
        XCTAssertEqual(
            headerFields,
            [
                .contentType: "application/octet-stream"
            ]
        )
    }

    //    | client | get | response body | JSON | required | getResponseBodyAsJSON |
    func test_getResponseBodyAsJSON_codable() async throws {
        let value: TestPet = try await converter.getResponseBodyAsJSON(
            TestPet.self,
            from: .init(testStructData),
            transforming: { $0 }
        )
        XCTAssertEqual(value, testStruct)
    }

    //    | client | get | response body | binary | required | getResponseBodyAsBinary |
    func test_getResponseBodyAsBinary_data() async throws {
        let value: HTTPBody = try converter.getResponseBodyAsBinary(
            HTTPBody.self,
            from: .init(testString),
            transforming: { $0 }
        )
        try await XCTAssertEqualStringifiedData(value, testString)
    }
}

/// Asserts that the string representation of binary data is equal to an expected string.
///
/// - Parameters:
///   - expression1: An autoclosure that evaluates to a `Data`, which represents the binary data.
///   - expression2: An autoclosure that evaluates to the expected string.
///   - message: An optional custom message to display upon test failure.
///   - file: The file name to include in the failure message (default is the source file where this function is called).
///   - line: The line number to include in the failure message (default is the line where this function is called).
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
