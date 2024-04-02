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

final class Test_ServerConverterExtensions: Test_Runtime {

    func testExtractAccept() throws {
        let headerFields: HTTPFields = [.accept: "application/json, */*; q=0.8"]
        let accept: [AcceptHeaderContentType<TestAcceptable>] = try converter.extractAcceptHeaderIfPresent(
            in: headerFields
        )
        XCTAssertEqual(
            accept,
            [.init(contentType: .json, quality: 1.0), .init(contentType: .other("*/*"), quality: 0.8)]
        )
    }

    // MARK: Miscs

    func testValidateAccept() throws {
        let emptyHeaders: HTTPFields = [:]
        let wildcard: HTTPFields = [.accept: "*/*"]
        let partialWildcard: HTTPFields = [.accept: "text/*"]
        let short: HTTPFields = [.accept: "text/plain"]
        let long: HTTPFields = [
            .accept: "text/html, application/xhtml+xml, application/xml;q=0.9, image/webp, */*;q=0.8"
        ]
        let multiple: HTTPFields = [.accept: "text/plain, application/json"]
        let cases: [(HTTPFields, String, Bool)] = [
            // No Accept header, any string validates successfully
            (emptyHeaders, "foobar", true),

            // Accept: */*, any string validates successfully
            (wildcard, "foobar", true),

            // Accept: text/*, so text/plain succeeds, application/json fails
            (partialWildcard, "text/plain", true), (partialWildcard, "application/json", false),

            // Accept: text/plain, text/plain succeeds, application/json fails
            (short, "text/plain", true), (short, "application/json", false),

            // A bunch of acceptable content types
            (long, "text/html", true), (long, "application/xhtml+xml", true), (long, "application/xml", true),
            (long, "image/webp", true), (long, "application/json", true),

            // Multiple values
            (multiple, "text/plain", true), (multiple, "application/json", true), (multiple, "application/xml", false),
        ]
        for (headers, contentType, success) in cases {
            if success {
                XCTAssertNoThrow(
                    try converter.validateAcceptIfPresent(contentType, in: headers),
                    "Unexpected error when validating string: \(contentType) against headers: \(headers)"
                )
            } else {
                XCTAssertThrowsError(
                    try converter.validateAcceptIfPresent(contentType, in: headers),
                    "Expected to throw error when validating string: \(contentType) against headers: \(headers)"
                )
            }
        }
    }

    // MARK: Converter helper methods

    //    | server | get | request path | URI | required | getPathParameterAsURI |
    func test_getPathParameterAsURI_various() throws {
        let path: [String: Substring] = [
            "foo": "bar", "number": "1", "habitats": "land,air", "withEscaping": "Hello%20world%21",
        ]
        do {
            let value = try converter.getPathParameterAsURI(in: path, name: "foo", as: String.self)
            XCTAssertEqual(value, "bar")
        }
        do {
            let value = try converter.getPathParameterAsURI(in: path, name: "number", as: Int.self)
            XCTAssertEqual(value, 1)
        }
        do {
            let value = try converter.getPathParameterAsURI(in: path, name: "habitats", as: [TestHabitat].self)
            XCTAssertEqual(value, [.land, .air])
        }
        do {
            let value = try converter.getPathParameterAsURI(in: path, name: "withEscaping", as: String.self)
            XCTAssertEqual(value, "Hello world!")
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
        let query: Substring = "search=foo&search=bar"
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
        let query: Substring = "search=foo&search=bar"
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
        let query: Substring = "search=foo,bar"
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
        let query: Substring = "search=\(testDateEscapedString)"
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
        let query: Substring = "search=\(testDateEscapedString)&search=\(testDateEscapedString)"
        let value: [Date] = try converter.getRequiredQueryItemAsURI(
            in: query,
            style: nil,
            explode: nil,
            name: "search",
            as: [Date].self
        )
        XCTAssertEqual(value, [testDate, testDate])
    }

    //    | server | get | request body | JSON | optional | getOptionalRequestBodyAsJSON |
    func test_getOptionalRequestBodyAsJSON_codable() async throws {
        let body: TestPet? = try await converter.getOptionalRequestBodyAsJSON(
            TestPet.self,
            from: .init(testStructData),
            transforming: { $0 }
        )
        XCTAssertEqual(body, testStruct)
    }

    func test_getOptionalRequestBodyAsJSON_codable_string() async throws {
        let body: String? = try await converter.getOptionalRequestBodyAsJSON(
            String.self,
            from: .init(testQuotedStringData),
            transforming: { $0 }
        )
        XCTAssertEqual(body, testString)
    }

    //    | server | get | request body | JSON | required | getRequiredRequestBodyAsJSON |
    func test_getRequiredRequestBodyAsJSON_codable() async throws {
        let body: TestPet = try await converter.getRequiredRequestBodyAsJSON(
            TestPet.self,
            from: .init(testStructData),
            transforming: { $0 }
        )
        XCTAssertEqual(body, testStruct)
    }
    
    //    | server | get | request body | XML | optional | getOptionalRequestBodyAsXML |
    func test_getOptionalRequestBodyAsXML_codable() async throws {
        let body: TestPet? = try await converter.getOptionalRequestBodyAsXML(
            TestPet.self,
            from: .init(testStructData),
            transforming: { $0 }
        )
        XCTAssertEqual(body, testStruct)
    }
    
    //    | server | get | request body | XML | required | getRequiredRequestBodyAsXML |
    func test_getRequiredRequestBodyAsXML_codable() async throws {
        let body: TestPet = try await converter.getRequiredRequestBodyAsXML(
            TestPet.self,
            from: .init(testStructData),
            transforming: { $0 }
        )
        XCTAssertEqual(body, testStruct)
    }

    //    | server | get | request body | urlEncodedForm | optional | getOptionalRequestBodyAsURLEncodedForm |
    func test_getOptionalRequestBodyAsURLEncodedForm_codable() async throws {
        let body: TestPetDetailed? = try await converter.getOptionalRequestBodyAsURLEncodedForm(
            TestPetDetailed.self,
            from: .init(testStructURLFormData),
            transforming: { $0 }
        )
        XCTAssertEqual(body, testStructDetailed)
    }

    //    | server | get | request body | urlEncodedForm | required | getRequiredRequestBodyAsURLEncodedForm |
    func test_getRequiredRequestBodyAsURLEncodedForm_codable() async throws {
        let body: TestPetDetailed = try await converter.getRequiredRequestBodyAsURLEncodedForm(
            TestPetDetailed.self,
            from: .init(testStructURLFormData),
            transforming: { $0 }
        )
        XCTAssertEqual(body, testStructDetailed)
    }

    //    | server | get | request body | binary | optional | getOptionalRequestBodyAsBinary |
    func test_getOptionalRequestBodyAsBinary_data() async throws {
        let body: HTTPBody? = try converter.getOptionalRequestBodyAsBinary(
            HTTPBody.self,
            from: .init(testStringData),
            transforming: { $0 }
        )
        try await XCTAssertEqualStringifiedData(body, testString)
    }

    //    | server | get | request body | binary | required | getRequiredRequestBodyAsBinary |
    func test_getRequiredRequestBodyAsBinary_data() async throws {
        let body: HTTPBody = try converter.getRequiredRequestBodyAsBinary(
            HTTPBody.self,
            from: .init(testStringData),
            transforming: { $0 }
        )
        try await XCTAssertEqualStringifiedData(body, testString)
    }

    //    | server | get | request body | multipart | required | getRequiredRequestBodyAsMultipart |
    func test_getRequiredRequestBodyAsMultipart() async throws {
        let value = try converter.getRequiredRequestBodyAsMultipart(
            MultipartBody<MultipartTestPart>.self,
            from: .init(testMultipartStringBytes),
            transforming: { $0 },
            boundary: "__X_SWIFT_OPENAPI_GENERATOR_BOUNDARY__",
            allowsUnknownParts: true,
            requiredExactlyOncePartNames: ["hello"],
            requiredAtLeastOncePartNames: ["world"],
            atMostOncePartNames: [],
            zeroOrMoreTimesPartNames: [],
            decoding: { part in try await .init(part) }
        )
        var parts: [MultipartTestPart] = []
        for try await part in value { parts.append(part) }
        XCTAssertEqual(parts, MultipartTestPart.all)
    }

    //    | server | set | response body | JSON | required | setResponseBodyAsJSON |
    func test_setResponseBodyAsJSON_codable() async throws {
        var headers: HTTPFields = [:]
        let data = try converter.setResponseBodyAsJSON(
            testStruct,
            headerFields: &headers,
            contentType: "application/json"
        )
        try await XCTAssertEqualStringifiedData(data, testStructPrettyString)
        XCTAssertEqual(headers, [.contentType: "application/json", .contentLength: "23"])
    }
    
    //    | server | set | response body | XML | required | setResponseBodyAsXML |
    func test_setResponseBodyAsXML_codable() async throws {
        var headers: HTTPFields = [:]
        let data = try converter.setResponseBodyAsXML(
            testStruct,
            headerFields: &headers,
            contentType: "application/xml"
        )
        try await XCTAssertEqualStringifiedData(data, testStructString)
        XCTAssertEqual(headers, [.contentType: "application/xml", .contentLength: "17"])
    }

    //    | server | set | response body | binary | required | setResponseBodyAsBinary |
    func test_setResponseBodyAsBinary_data() async throws {
        var headers: HTTPFields = [:]
        let data = try converter.setResponseBodyAsBinary(
            .init(testStringData),
            headerFields: &headers,
            contentType: "application/octet-stream"
        )
        try await XCTAssertEqualStringifiedData(data, testString)
        XCTAssertEqual(headers, [.contentType: "application/octet-stream", .contentLength: "5"])
    }

    //    | server | set | response body | multipart | required | setResponseBodyAsMultipart |
    func test_setResponseBodyAsMultipart() async throws {
        let multipartBody: MultipartBody<MultipartTestPart> = .init(MultipartTestPart.all)
        var headerFields: HTTPFields = [:]
        let body = try converter.setResponseBodyAsMultipart(
            multipartBody,
            headerFields: &headerFields,
            contentType: "multipart/form-data",
            allowsUnknownParts: true,
            requiredExactlyOncePartNames: ["hello"],
            requiredAtLeastOncePartNames: ["world"],
            atMostOncePartNames: [],
            zeroOrMoreTimesPartNames: [],
            encoding: { part in part.rawPart }
        )
        try await XCTAssertEqualData(body, testMultipartStringBytes)
        XCTAssertEqual(
            headerFields,
            [.contentType: "multipart/form-data; boundary=__X_SWIFT_OPENAPI_GENERATOR_BOUNDARY__"]
        )
    }
}
