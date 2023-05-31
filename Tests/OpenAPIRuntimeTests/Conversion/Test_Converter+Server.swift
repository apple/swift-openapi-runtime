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

    func testValidateAccept_missing() throws {
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

    // MARK: Path

    func testPathGetOptional_string() throws {
        let path: [String: String] = [
            "foo": "bar"
        ]
        let value = try converter.pathGetOptional(
            in: path,
            name: "foo",
            as: String.self
        )
        XCTAssertEqual(value, "bar")
    }

    func testPathGetOptional_intMismatch() throws {
        let path: [String: String] = [
            "foo": "bar"
        ]
        XCTAssertThrowsError(
            try converter.pathGetOptional(
                in: path,
                name: "foo",
                as: Int.self
            ),
            "Expected conversion from string to Int to throw",
            { error in
                guard
                    let err = error as? RuntimeError,
                    case let .failedToDecodePathParameter(name, type) = err
                else {
                    XCTFail("Unexpected error thrown: \(error)")
                    return
                }
                XCTAssertEqual(name, "foo")
                XCTAssertEqual(type, "Int")
            }
        )
    }

    func testPathGetOptional_nil() throws {
        let path: [String: String] = [:]
        let value = try converter.pathGetOptional(
            in: path,
            name: "foo",
            as: String.self
        )
        XCTAssertNil(value)
    }

    func testPathGetRequired_string() throws {
        let path: [String: String] = [
            "foo": "bar"
        ]
        let value = try converter.pathGetRequired(
            in: path,
            name: "foo",
            as: String.self
        )
        XCTAssertEqual(value, "bar")
    }

    func testPathGetRequired_missing() throws {
        let path: [String: String] = [
            "foo": "bar"
        ]
        XCTAssertThrowsError(
            try converter.pathGetRequired(
                in: path,
                name: "pet",
                as: String.self
            ),
            "Was expected to throw error on missing required path parameter",
            { error in
                guard
                    let err = error as? RuntimeError,
                    case .missingRequiredPathParameter(let name) = err
                else {
                    XCTFail("Unexpected kind of error thrown")
                    return
                }
                XCTAssertEqual(name, "pet")
            }
        )
    }

    // MARK: Query - LosslessStringConvertible

    func testQueryGetOptional_string() throws {
        let query: [URLQueryItem] = [
            .init(name: "search", value: "foo")
        ]
        let value = try converter.queryGetOptional(
            in: query,
            name: "search",
            as: String.self
        )
        XCTAssertEqual(value, "foo")
    }

    func testQueryGetOptional_mismatch() throws {
        let query: [URLQueryItem] = [
            .init(name: "search", value: "foo")
        ]
        XCTAssertThrowsError(
            try converter.queryGetOptional(
                in: query,
                name: "search",
                as: Int.self
            ),
            "Was expected to throw error on missing required query",
            { error in
                guard
                    let err = error as? RuntimeError,
                    case let .failedToDecodeQueryParameter(name, type) = err
                else {
                    XCTFail("Unexpected kind of error thrown")
                    return
                }
                XCTAssertEqual(name, "search")
                XCTAssertEqual(type, "Int")
            }
        )
    }

    func testQueryGetOptional_nil() throws {
        let query: [URLQueryItem] = []
        let value = try converter.queryGetOptional(
            in: query,
            name: "search",
            as: String.self
        )
        XCTAssertNil(value)
    }

    func testQueryGetRequired_string() throws {
        let query: [URLQueryItem] = [
            .init(name: "search", value: "foo")
        ]
        let value = try converter.queryGetRequired(
            in: query,
            name: "search",
            as: String.self
        )
        XCTAssertEqual(value, "foo")
    }

    func testQueryGetRequired_mismatch() throws {
        let query: [URLQueryItem] = [
            .init(name: "search", value: "foo")
        ]
        XCTAssertThrowsError(
            try converter.queryGetRequired(
                in: query,
                name: "search",
                as: Int.self
            ),
            "Was expected to throw error on missing required query",
            { error in
                guard
                    let err = error as? RuntimeError,
                    case let .failedToDecodeQueryParameter(name, type) = err
                else {
                    XCTFail("Unexpected kind of error thrown")
                    return
                }
                XCTAssertEqual(name, "search")
                XCTAssertEqual(type, "Int")
            }
        )
    }

    func testQueryGetRequired_missing() throws {
        let query: [URLQueryItem] = []
        XCTAssertThrowsError(
            try converter.queryGetRequired(
                in: query,
                name: "search",
                as: String.self
            ),
            "Was expected to throw error on missing required query",
            { error in
                guard
                    let err = error as? RuntimeError,
                    case .missingRequiredQueryParameter(let queryKey) = err
                else {
                    XCTFail("Unexpected kind of error thrown")
                    return
                }
                XCTAssertEqual(queryKey, "search")
            }
        )
    }

    // MARK: Query - Date

    func testQueryGetOptional_date() throws {
        let query: [URLQueryItem] = [
            .init(name: "since", value: testDateString)
        ]
        let value = try converter.queryGetOptional(
            in: query,
            name: "since",
            as: Date.self
        )
        XCTAssertEqual(value, testDate)
    }

    func testQueryGetOptional_date_invalid() throws {
        let query: [URLQueryItem] = [
            .init(name: "since", value: "invaliddate")
        ]
        XCTAssertThrowsError(
            try converter.queryGetOptional(
                in: query,
                name: "since",
                as: Date.self
            ),
            "Was expected to throw error on missing required query",
            { error in
                guard
                    let err = error as? DecodingError,
                    case let .dataCorrupted(context) = err
                else {
                    XCTFail("Unexpected kind of error thrown")
                    return
                }
                XCTAssertEqual(context.codingPath.map(\.description), [])
                // Do not check the exact string of the error as that's not
                // controlled by us - just ensure it's not empty.
                XCTAssertFalse(context.debugDescription.isEmpty)
                XCTAssertNil(context.underlyingError)
            }
        )
    }

    func testQueryGetOptional_date_nil() throws {
        let query: [URLQueryItem] = []
        let value = try converter.queryGetOptional(
            in: query,
            name: "since",
            as: Date.self
        )
        XCTAssertNil(value)
    }

    func testQueryGetRequired_date() throws {
        let query: [URLQueryItem] = [
            .init(name: "since", value: testDateString)
        ]
        let value = try converter.queryGetRequired(
            in: query,
            name: "since",
            as: Date.self
        )
        XCTAssertEqual(value, testDate)
    }

    func testQueryGetRequired_date_invalid() throws {
        let query: [URLQueryItem] = [
            .init(name: "since", value: "invaliddate")
        ]
        XCTAssertThrowsError(
            try converter.queryGetRequired(
                in: query,
                name: "since",
                as: Date.self
            ),
            "Was expected to throw error on missing required query",
            { error in
                guard
                    let err = error as? DecodingError,
                    case let .dataCorrupted(context) = err
                else {
                    XCTFail("Unexpected kind of error thrown")
                    return
                }
                XCTAssertEqual(context.codingPath.map(\.description), [])
                // Do not check the exact string of the error as that's not
                // controlled by us - just ensure it's not empty.
                XCTAssertFalse(context.debugDescription.isEmpty)
                XCTAssertNil(context.underlyingError)
            }
        )
    }

    func testQueryGetRequired_date_missing() throws {
        let query: [URLQueryItem] = []
        XCTAssertThrowsError(
            try converter.queryGetRequired(
                in: query,
                name: "since",
                as: Date.self
            ),
            "Was expected to throw error on missing required query",
            { error in
                guard
                    let err = error as? RuntimeError,
                    case .missingRequiredQueryParameter(let queryKey) = err
                else {
                    XCTFail("Unexpected kind of error thrown")
                    return
                }
                XCTAssertEqual(queryKey, "since")
            }
        )
    }

    // MARK: Query - Array of LosslessStringConvertibles

    func testQueryGetOptional_array() throws {
        let query: [URLQueryItem] = [
            .init(name: "id", value: "1"),
            .init(name: "id", value: "2"),
        ]
        let value = try converter.queryGetOptional(
            in: query,
            name: "id",
            as: [String].self
        )
        XCTAssertEqual(value, ["1", "2"])
    }

    func testQueryGetOptional_array_mismatch() throws {
        let query: [URLQueryItem] = [
            .init(name: "id", value: "1"),
            .init(name: "id", value: "foo"),
        ]
        XCTAssertThrowsError(
            try converter.queryGetOptional(
                in: query,
                name: "id",
                as: [Int].self
            ),
            "Was expected to throw error on mismatched query",
            { error in
                guard
                    let err = error as? RuntimeError,
                    case let .failedToDecodeQueryParameter(name, type) = err
                else {
                    XCTFail("Unexpected kind of error thrown")
                    return
                }
                XCTAssertEqual(name, "id")
                XCTAssertEqual(type, "Int")
            }
        )
    }

    func testQueryGetOptional_array_nil() throws {
        let query: [URLQueryItem] = []
        let value = try converter.queryGetOptional(
            in: query,
            name: "id",
            as: [String].self
        )
        XCTAssertNil(value)
    }

    func testQueryGetRequired_array() throws {
        let query: [URLQueryItem] = [
            .init(name: "id", value: "1"),
            .init(name: "id", value: "2"),
        ]
        let value = try converter.queryGetRequired(
            in: query,
            name: "id",
            as: [String].self
        )
        XCTAssertEqual(value, ["1", "2"])
    }

    func testQueryGetRequired_array_mismatch() throws {
        let query: [URLQueryItem] = [
            .init(name: "id", value: "1"),
            .init(name: "id", value: "foo"),
        ]
        XCTAssertThrowsError(
            try converter.queryGetRequired(
                in: query,
                name: "id",
                as: [Int].self
            ),
            "Was expected to throw error on mismatched query",
            { error in
                guard
                    let err = error as? RuntimeError,
                    case let .failedToDecodeQueryParameter(name, type) = err
                else {
                    XCTFail("Unexpected kind of error thrown")
                    return
                }
                XCTAssertEqual(name, "id")
                XCTAssertEqual(type, "Int")
            }
        )
    }

    func testQueryGetRequired_array_missing() throws {
        let query: [URLQueryItem] = []
        XCTAssertThrowsError(
            try converter.queryGetRequired(
                in: query,
                name: "id",
                as: [String].self
            ),
            "Was expected to throw error on missing required query",
            { error in
                guard
                    let err = error as? RuntimeError,
                    case .missingRequiredQueryParameter(let queryKey) = err
                else {
                    XCTFail("Unexpected kind of error thrown")
                    return
                }
                XCTAssertEqual(queryKey, "id")
            }
        )
    }

    // MARK: Body

    func testBodyAddComplex() throws {
        var headers: [HeaderField] = []
        let data = try converter.bodyAdd(
            testStruct,
            headerFields: &headers,
            transforming: {
                .init(
                    value: $0,
                    contentType: "application/json",
                    strategy: .deferredToType
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

    func testBodyAddString_strategyDeferredToType() throws {
        var headers: [HeaderField] = []
        let data = try converter.bodyAdd(
            testString,
            headerFields: &headers,
            transforming: {
                .init(
                    value: $0,
                    contentType: "text/plain",
                    strategy: .deferredToType
                )
            }
        )
        XCTAssertEqual(String(data: data, encoding: .utf8)!, testQuotedString)
        XCTAssertEqual(
            headers,
            [
                .init(name: "content-type", value: "text/plain")
            ]
        )
    }

    func testBodyAddString_strategyString() throws {
        var headers: [HeaderField] = []
        let data = try converter.bodyAdd(
            testString,
            headerFields: &headers,
            transforming: {
                .init(
                    value: $0,
                    contentType: "text/plain",
                    strategy: .string
                )
            }
        )
        XCTAssertEqual(String(data: data, encoding: .utf8)!, testString)
        XCTAssertEqual(
            headers,
            [
                .init(name: "content-type", value: "text/plain")
            ]
        )
    }

    func testBodyAddString_strategyCodable() throws {
        var headers: [HeaderField] = []
        let data = try converter.bodyAdd(
            testString,
            headerFields: &headers,
            transforming: {
                .init(
                    value: $0,
                    contentType: "text/plain",
                    strategy: .codable
                )
            }
        )
        XCTAssertEqual(String(data: data, encoding: .utf8)!, testQuotedString)
        XCTAssertEqual(
            headers,
            [
                .init(name: "content-type", value: "text/plain")
            ]
        )
    }

    func testBodyAddData() throws {
        var headers: [HeaderField] = []
        let data = try converter.bodyAdd(
            testStructPrettyData,
            headerFields: &headers,
            transforming: {
                .init(
                    value: $0,
                    contentType: "application/octet-stream",
                    strategy: .deferredToType
                )
            }
        )
        XCTAssertEqual(data, testStructPrettyData)
        XCTAssertEqual(
            headers,
            [
                .init(name: "content-type", value: "application/octet-stream")
            ]
        )
    }

    func testBodyGetComplexOptional_success() throws {
        let body = try converter.bodyGetOptional(
            TestPet.self,
            from: testStructData,
            strategy: .deferredToType,
            transforming: { $0 }
        )
        XCTAssertEqual(body, testStruct)
    }

    func testBodyGetComplexOptional_nil() throws {
        let body = try converter.bodyGetOptional(
            TestPet.self,
            from: nil,
            strategy: .deferredToType,
            transforming: { _ -> TestPet in fatalError("Unreachable") }
        )
        XCTAssertNil(body)
    }

    func testBodyGetComplexRequired_success() throws {
        let body = try converter.bodyGetOptional(
            TestPet.self,
            from: testStructData,
            strategy: .deferredToType,
            transforming: { $0 }
        )
        XCTAssertEqual(body, testStruct)
    }

    func testBodyGetComplexRequired_nil() throws {
        XCTAssertThrowsError(
            try converter.bodyGetRequired(
                TestPet.self,
                from: nil,
                strategy: .deferredToType,
                transforming: { _ -> TestPet in fatalError("Unreachable") }
            ),
            "Was expected to throw error on missing required body",
            { error in
                guard
                    let err = error as? RuntimeError,
                    case .missingRequiredRequestBody = err
                else {
                    XCTFail("Unexpected kind of error thrown")
                    return
                }
            }
        )
    }

    func testBodyGetDataOptional_success() throws {
        let body = try converter.bodyGetOptional(
            Data.self,
            from: testStructPrettyData,
            strategy: .deferredToType,
            transforming: { $0 }
        )
        XCTAssertEqual(body, testStructPrettyData)
    }

    func testBodyGetDataRequired_success() throws {
        let body = try converter.bodyGetRequired(
            Data.self,
            from: testStructPrettyData,
            strategy: .deferredToType,
            transforming: { $0 }
        )
        XCTAssertEqual(body, testStructPrettyData)
    }

    func testBodyGetDataRequired_missing() throws {
        XCTAssertThrowsError(
            try converter.bodyGetRequired(
                Data.self,
                from: nil,
                strategy: .deferredToType,
                transforming: { $0 }
            ),
            "Was expected to throw error on missing required body",
            { error in
                guard
                    let err = error as? RuntimeError,
                    case .missingRequiredRequestBody = err
                else {
                    XCTFail("Unexpected kind of error thrown")
                    return
                }
            }
        )
    }

    func testBodyGetStringOptional_strategyDeferredToType_success() throws {
        let body = try converter.bodyGetOptional(
            String.self,
            from: testQuotedStringData,
            strategy: .deferredToType,
            transforming: { $0 }
        )
        XCTAssertEqual(body, testString)
    }

    func testBodyGetStringOptional_strategyString_success() throws {
        let body = try converter.bodyGetOptional(
            String.self,
            from: testStringData,
            strategy: .string,
            transforming: { $0 }
        )
        XCTAssertEqual(body, testString)
    }

    func testBodyGetStringOptional_strategyCodable_success() throws {
        let body = try converter.bodyGetOptional(
            String.self,
            from: testQuotedStringData,
            strategy: .codable,
            transforming: { $0 }
        )
        XCTAssertEqual(body, testString)
    }

    func testBodyGetStringRequired_strategyDeferredToType_success() throws {
        let body = try converter.bodyGetRequired(
            String.self,
            from: testQuotedStringData,
            strategy: .deferredToType,
            transforming: { $0 }
        )
        XCTAssertEqual(body, testString)
    }

    func testBodyGetStringRequired_strategyString_success() throws {
        let body = try converter.bodyGetRequired(
            String.self,
            from: testStringData,
            strategy: .string,
            transforming: { $0 }
        )
        XCTAssertEqual(body, testString)
    }

    func testBodyGetStringRequired_strategyCodable_success() throws {
        let body = try converter.bodyGetRequired(
            String.self,
            from: testQuotedStringData,
            strategy: .codable,
            transforming: { $0 }
        )
        XCTAssertEqual(body, testString)
    }
}
