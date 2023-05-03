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

    // MARK: [HeaderField] extension

    func testHeaderFields_add_string() throws {
        var headerFields: [HeaderField] = []
        headerFields.add(name: "foo", value: "bar")
        XCTAssertEqual(
            headerFields,
            [
                .init(name: "foo", value: "bar")
            ]
        )
    }

    func testHeaderFields_add_nil() throws {
        var headerFields: [HeaderField] = []
        let value: String? = nil
        headerFields.add(name: "foo", value: value)
        XCTAssertEqual(headerFields, [])
    }

    func testHeaderFields_firstValue_found() throws {
        let headerFields: [HeaderField] = [
            .init(name: "foo", value: "bar")
        ]
        XCTAssertEqual(headerFields.firstValue(name: "foo"), "bar")
    }

    func testHeaderFields_firstValue_nil() throws {
        let headerFields: [HeaderField] = []
        XCTAssertNil(headerFields.firstValue(name: "foo"))
    }

    func testHeaderFields_values() throws {
        let headerFields: [HeaderField] = [
            .init(name: "foo", value: "bar"),
            .init(name: "foo", value: "baz"),
        ]
        XCTAssertEqual(headerFields.values(name: "foo"), ["bar", "baz"])
    }

    func testHeaderFields_removeAll_noMatches() throws {
        var headerFields: [HeaderField] = [
            .init(name: "one", value: "one"),
            .init(name: "two", value: "two"),
        ]
        headerFields.removeAll(named: "three")
        XCTAssertEqual(headerFields.map(\.name), ["one", "two"])
    }

    func testHeaderFields_removeAll_oneMatch() throws {
        var headerFields: [HeaderField] = [
            .init(name: "one", value: "one"),
            .init(name: "two", value: "two"),
            .init(name: "three", value: "three"),
        ]
        headerFields.removeAll(named: "three")
        XCTAssertEqual(headerFields.map(\.name), ["one", "two"])
    }

    func testHeaderFields_removeAll_manyMatches() throws {
        var headerFields: [HeaderField] = [
            .init(name: "one", value: "one"),
            .init(name: "three", value: "3"),
            .init(name: "two", value: "two"),
            .init(name: "three", value: "three"),
        ]
        headerFields.removeAll(named: "three")
        XCTAssertEqual(headerFields.map(\.name), ["one", "two"])
    }

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

    // MARK: [HeaderField] - _StringParameterConvertible

    func testHeaderAdd_string() throws {
        var headerFields: [HeaderField] = []
        try converter.headerFieldAdd(
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

    func testHeaderGetOptional_string() throws {
        let headerFields: [HeaderField] = [
            .init(name: "foo", value: "bar")
        ]
        let value = try converter.headerFieldGetOptional(
            in: headerFields,
            name: "foo",
            as: String.self
        )
        XCTAssertEqual(value, "bar")
    }

    func testHeaderGetOptional_missing() throws {
        let headerFields: [HeaderField] = []
        let value = try converter.headerFieldGetOptional(
            in: headerFields,
            name: "foo",
            as: String.self
        )
        XCTAssertNil(value)
    }

    func testHeaderGetRequired_string() throws {
        let headerFields: [HeaderField] = [
            .init(name: "foo", value: "bar")
        ]
        let value = try converter.headerFieldGetRequired(
            in: headerFields,
            name: "foo",
            as: String.self
        )
        XCTAssertEqual(value, "bar")
    }

    func testHeaderGetRequired_missing() throws {
        let headerFields: [HeaderField] = []
        XCTAssertThrowsError(
            try converter.headerFieldGetRequired(
                in: headerFields,
                name: "foo",
                as: String.self
            ),
            "Was expected to throw error on missing required header",
            { error in
                guard
                    let err = error as? RuntimeError,
                    case .missingRequiredHeader(let name) = err
                else {
                    XCTFail("Unexpected kind of error thrown")
                    return
                }
                XCTAssertEqual(name, "foo")
            }
        )
    }

    // MARK: [HeaderField] -  (Date)

    func testHeaderAdd_date() throws {
        var headerFields: [HeaderField] = []
        try converter.headerFieldAdd(
            in: &headerFields,
            name: "since",
            value: testDate
        )
        XCTAssertEqual(
            headerFields,
            [
                .init(name: "since", value: testDateString)
            ]
        )
    }

    func testHeaderAdd_date_nil() throws {
        var headerFields: [HeaderField] = []
        let date: Date? = nil
        try converter.headerFieldAdd(
            in: &headerFields,
            name: "since",
            value: date
        )
        XCTAssertEqual(headerFields, [])
    }

    func testHeaderGetOptional_date() throws {
        let headerFields: [HeaderField] = [
            .init(name: "since", value: testDateString)
        ]
        let value = try converter.headerFieldGetOptional(
            in: headerFields,
            name: "since",
            as: Date.self
        )
        XCTAssertEqual(value, testDate)
    }

    func testHeaderGetOptional_date_missing() throws {
        let headerFields: [HeaderField] = []
        let value = try converter.headerFieldGetOptional(
            in: headerFields,
            name: "since",
            as: Date.self
        )
        XCTAssertNil(value)
    }

    func testHeaderGetRequired_date() throws {
        let headerFields: [HeaderField] = [
            .init(name: "since", value: testDateString)
        ]
        let value = try converter.headerFieldGetRequired(
            in: headerFields,
            name: "since",
            as: Date.self
        )
        XCTAssertEqual(value, testDate)
    }

    func testHeaderGetRequired_date_missing() throws {
        let headerFields: [HeaderField] = []
        XCTAssertThrowsError(
            try converter.headerFieldGetRequired(
                in: headerFields,
                name: "since",
                as: Date.self
            ),
            "Was expected to throw error on missing required header",
            { error in
                guard
                    let err = error as? RuntimeError,
                    case .missingRequiredHeader(let name) = err
                else {
                    XCTFail("Unexpected kind of error thrown")
                    return
                }
                XCTAssertEqual(name, "since")
            }
        )
    }

    // MARK: [HeaderField] - Complex

    func testHeaderAddComplex_struct() throws {
        var headerFields: [HeaderField] = []
        try converter.headerFieldAdd(
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

    func testHeaderAddComplex_nil() throws {
        var headerFields: [HeaderField] = []
        let value: TestPet? = nil
        try converter.headerFieldAdd(
            in: &headerFields,
            name: "foo",
            value: value
        )
        XCTAssertEqual(headerFields, [])
    }

    func testHeaderGetComplexOptional_struct() throws {
        let headerFields: [HeaderField] = [
            .init(name: "pet", value: testStructString)
        ]
        let value = try converter.headerFieldGetOptional(
            in: headerFields,
            name: "pet",
            as: TestPet.self
        )
        XCTAssertEqual(value, testStruct)
    }

    func testHeaderGetComplexOptional_missing() throws {
        let headerFields: [HeaderField] = []
        let value = try converter.headerFieldGetOptional(
            in: headerFields,
            name: "pet",
            as: TestPet.self
        )
        XCTAssertNil(value)
    }

    func testHeaderGetComplexRequired_struct() throws {
        let headerFields: [HeaderField] = [
            .init(name: "pet", value: testStructString)
        ]
        let value = try converter.headerFieldGetRequired(
            in: headerFields,
            name: "pet",
            as: TestPet.self
        )
        XCTAssertEqual(value, testStruct)
    }

    func testHeaderGetComplexRequired_missing() throws {
        let headerFields: [HeaderField] = []
        XCTAssertThrowsError(
            try converter.headerFieldGetRequired(
                in: headerFields,
                name: "pet",
                as: TestPet.self
            ),
            "Was expected to throw error on missing required header",
            { error in
                guard
                    let err = error as? RuntimeError,
                    case .missingRequiredHeader(let name) = err
                else {
                    XCTFail("Unexpected kind of error thrown")
                    return
                }
                XCTAssertEqual(name, "pet")
            }
        )
    }
}
