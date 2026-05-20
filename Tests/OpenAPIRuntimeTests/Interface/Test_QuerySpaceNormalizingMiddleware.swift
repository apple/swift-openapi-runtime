//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftOpenAPIGenerator open source project
//
// Copyright (c) 2026 Apple Inc. and the SwiftOpenAPIGenerator project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftOpenAPIGenerator project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import HTTPTypes

import XCTest
@_spi(Generated) @testable import OpenAPIRuntime

final class Test_QuerySpaceNormalizingMiddleware: XCTestCase {
    static let middleware = QuerySpaceNormalizingMiddleware()

    func testPlusInQueryIsReplacedWithPercent20() async throws {
        try await assertNormalizedPath(input: "/search?q=hello+world", expected: "/search?q=hello%20world")
    }

    func testMultiplePlusesAreReplaced() async throws {
        try await assertNormalizedPath(
            input: "/search?a=one+two&b=three+four+five",
            expected: "/search?a=one%20two&b=three%20four%20five"
        )
    }

    func testPercent20InQueryIsUntouched() async throws {
        try await assertNormalizedPath(input: "/search?q=hello%20world", expected: "/search?q=hello%20world")
    }

    func testLiteralPlusEncodedAsPercent2BIsUntouched() async throws {
        try await assertNormalizedPath(input: "/search?q=hello%2Bworld", expected: "/search?q=hello%2Bworld")
    }

    func testPlusInPathIsNotReplaced() async throws {
        try await assertNormalizedPath(input: "/a+b/c+d?q=e+f", expected: "/a+b/c+d?q=e%20f")
    }

    func testPlusInFragmentIsNotReplaced() async throws {
        try await assertNormalizedPath(input: "/search?q=a+b#c+d", expected: "/search?q=a%20b#c+d")
    }

    func testQuestionMarkInsideFragmentDoesNotCrash() async throws {
        try await assertNormalizedPath(input: "/a#b?c+d", expected: "/a#b?c+d")
    }

    func testQueryBeforeFragmentContainingQuestionMark() async throws {
        try await assertNormalizedPath(input: "/a?b+c#d?e+f", expected: "/a?b%20c#d?e+f")
    }

    func testPathWithoutQueryIsUntouched() async throws {
        try await assertNormalizedPath(input: "/search", expected: "/search")
    }

    func testQueryWithoutPlusIsUntouched() async throws {
        try await assertNormalizedPath(input: "/search?q=hello", expected: "/search?q=hello")
    }

    func testEmptyQueryIsUntouched() async throws {
        try await assertNormalizedPath(input: "/search?", expected: "/search?")
    }

    func testResponseIsForwardedUnchanged() async throws {
        let request = HTTPRequest(soar_path: "/search?q=hello+world", method: .get)
        let (response, responseBody) = try await Test_QuerySpaceNormalizingMiddleware.middleware.intercept(
            request,
            body: nil,
            metadata: .init(),
            operationID: "testop",
            next: { _, _, _ in (HTTPResponse(status: .accepted), HTTPBody("ok")) }
        )
        XCTAssertEqual(response.status, .accepted)
        let bodyBytes = try await String(collecting: responseBody!, upTo: .max)
        XCTAssertEqual(bodyBytes, "ok")
    }

    private func assertNormalizedPath(
        input: String,
        expected: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws {
        let request = HTTPRequest(soar_path: input, method: .get)
        _ = try await Test_QuerySpaceNormalizingMiddleware.middleware.intercept(
            request,
            body: nil,
            metadata: .init(),
            operationID: "testop",
            next: { forwarded, _, _ in
                XCTAssertEqual(forwarded.path, expected, file: file, line: line)
                return (HTTPResponse(status: .ok), nil)
            }
        )
    }
}
