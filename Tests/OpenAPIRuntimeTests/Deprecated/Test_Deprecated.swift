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

}
