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
@_spi(Generated) @testable import OpenAPIRuntime

final class Test_OpenAPIMIMEType: Test_Runtime {
    func testParsing() throws {
        let cases: [(String, OpenAPIMIMEType?, String?)] = [

            // Common
            (
                "application/json", OpenAPIMIMEType(kind: .concrete(type: "application", subtype: "json")),
                "application/json"
            ),

            // Subtype wildcard
            ("application/*", OpenAPIMIMEType(kind: .anySubtype(type: "application")), "application/*"),

            // Type wildcard
            ("*/*", OpenAPIMIMEType(kind: .any), "*/*"),

            // Common with a parameter
            (
                "application/json; charset=UTF-8",
                OpenAPIMIMEType(
                    kind: .concrete(type: "application", subtype: "json"),
                    parameters: ["charset": "UTF-8"]
                ), "application/json; charset=UTF-8"
            ),

            // Common with two parameters
            (
                "application/json; charset=UTF-8; boundary=1234",
                OpenAPIMIMEType(
                    kind: .concrete(type: "application", subtype: "json"),
                    parameters: ["charset": "UTF-8", "boundary": "1234"]
                ), "application/json; boundary=1234; charset=UTF-8"
            ),

            // Common case preserving, but case insensitive equality
            (
                "APPLICATION/JSON;CHARSET=UTF-8",
                OpenAPIMIMEType(
                    kind: .concrete(type: "application", subtype: "json"),
                    parameters: ["charset": "UTF-8"]
                ), "APPLICATION/JSON; CHARSET=UTF-8"
            ),

            // Invalid
            ("application", nil, nil), ("application/foo/bar", nil, nil), ("", nil, nil),
        ]
        for (inputString, expectedMIME, outputString) in cases {
            let mime = OpenAPIMIMEType(inputString)
            XCTAssertEqual(mime, expectedMIME)
            XCTAssertEqual(mime?.description, outputString)
        }
    }

    func testScore() throws {
        let cases: [(OpenAPIMIMEType.Match, Int)] = [

            (.incompatible(.type), 0), (.incompatible(.subtype), 0), (.incompatible(.parameter(name: "foo")), 0),

            (.wildcard, 1),

            (.subtypeWildcard, 2),

            (.typeAndSubtype(matchedParameterCount: 0), 3), (.typeAndSubtype(matchedParameterCount: 2), 5),
        ]
        for (match, score) in cases { XCTAssertEqual(match.score, score, "Mismatch for match: \(match)") }
    }

    func testEvaluate() throws {
        func testCase(
            receivedType: String,
            receivedSubtype: String,
            receivedParameters: [String: String],
            against option: OpenAPIMIMEType,
            expected expectedMatch: OpenAPIMIMEType.Match,
            file: StaticString = #filePath,
            line: UInt = #line
        ) {
            let result = OpenAPIMIMEType.evaluate(
                receivedType: receivedType,
                receivedSubtype: receivedSubtype,
                receivedParameters: receivedParameters,
                against: option
            )
            XCTAssertEqual(result, expectedMatch, file: file, line: line)
        }

        let jsonWith2Params = OpenAPIMIMEType("application/json; charset=utf-8; version=1")!
        let jsonWith1Param = OpenAPIMIMEType("application/json; charset=utf-8")!
        let json = OpenAPIMIMEType("application/json")!
        let anyJsonStructuredSyntax = OpenAPIMIMEType("application/*+json")!
        let fullWildcard = OpenAPIMIMEType("*/*")!
        let subtypeWildcard = OpenAPIMIMEType("application/*")!

        func testJSONWith2Params(
            against option: OpenAPIMIMEType,
            expected expectedMatch: OpenAPIMIMEType.Match,
            file: StaticString = #filePath,
            line: UInt = #line
        ) {
            testCase(
                receivedType: "application",
                receivedSubtype: "json",
                receivedParameters: ["charset": "utf-8", "version": "1"],
                against: option,
                expected: expectedMatch,
                file: file,
                line: line
            )
        }

        // Actual test cases start here.

        testJSONWith2Params(against: jsonWith2Params, expected: .typeAndSubtype(matchedParameterCount: 2))
        testJSONWith2Params(against: jsonWith1Param, expected: .typeAndSubtype(matchedParameterCount: 1))
        testJSONWith2Params(against: json, expected: .typeAndSubtype(matchedParameterCount: 0))
        testJSONWith2Params(against: subtypeWildcard, expected: .subtypeWildcard)
        testJSONWith2Params(against: fullWildcard, expected: .wildcard)

        testCase(
            receivedType: "application",
            receivedSubtype: "problem+json",
            receivedParameters: [:],
            against: json,
            expected: .typeAndSubtype(matchedParameterCount: 0)
        )
        testCase(
            receivedType: "application",
            receivedSubtype: "json",
            receivedParameters: [:],
            against: anyJsonStructuredSyntax,
            expected: .typeAndSubtype(matchedParameterCount: 0)
        )
        testCase(
            receivedType: "application",
            receivedSubtype: "problem+json",
            receivedParameters: [:],
            against: anyJsonStructuredSyntax,
            expected: .typeAndSubtype(matchedParameterCount: 0)
        )
        testCase(
            receivedType: "application",
            receivedSubtype: "problem+xml",
            receivedParameters: [:],
            against: json,
            expected: .incompatible(.subtype)
        )
    }
}
