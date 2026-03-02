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

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif
import XCTest
import HTTPTypes
@_spi(Generated) import OpenAPIRuntime

final class Test_Configuration: Test_Runtime {

    func testDateTranscoder_iso8601() throws {
        let transcoder: any DateTranscoder = .iso8601
        XCTAssertEqual(try transcoder.encode(testDate), testDateString)
        XCTAssertEqual(testDate, try transcoder.decode(testDateString))
    }

    func testDateTranscoder_iso8601WithFractionalSeconds() throws {
        let transcoder: any DateTranscoder = .iso8601WithFractionalSeconds

        // There is a small accuracy difference in the Foundation ISO8601DateFormatter
        // and the new Foundation .formatted() APIs, so the below tests take that into account
        #if FullFoundationSupport || canImport(Darwin)
        XCTAssertEqual(try transcoder.encode(testDateWithFractionalSeconds), testDateWithFractionalSecondsString)
        XCTAssertEqual(testDateWithFractionalSeconds, try transcoder.decode(testDateWithFractionalSecondsString))
        #else
        XCTAssertEqual(
            try transcoder.encode(testDateWithFractionalSeconds),
            testDateWithFractionalSecondsStringNewFoundationAPIs
        )
        XCTAssertEqual(
            testDateWithFractionalSeconds.timeIntervalSince1970,
            try transcoder.decode(testDateWithFractionalSecondsString).timeIntervalSince1970,
            accuracy: 0.00001
        )
        #endif
    }

    func _testJSON(configuration: Configuration, expected: String) async throws {
        let converter = Converter(configuration: configuration)
        var headerFields: HTTPFields = [:]
        let body = try converter.setResponseBodyAsJSON(
            testPetWithPath,
            headerFields: &headerFields,
            contentType: "application/json"
        )
        let data = try await Data(collecting: body, upTo: 1024)
        XCTAssertEqualStringifiedData(data, expected)
    }

    func testJSONEncodingOptions_default() async throws {
        try await _testJSON(configuration: Configuration(), expected: testPetWithPathPrettifiedWithEscapingSlashes)
    }

    func testJSONEncodingOptions_empty() async throws {
        try await _testJSON(
            configuration: Configuration(jsonEncodingOptions: [
                .sortedKeys  // without sorted keys, this test would be unreliable
            ]),
            expected: testPetWithPathMinifiedWithEscapingSlashes
        )
    }

    func testJSONEncodingOptions_prettyWithoutEscapingSlashes() async throws {
        try await _testJSON(
            configuration: Configuration(jsonEncodingOptions: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]),
            expected: testPetWithPathPrettifiedWithoutEscapingSlashes
        )
    }
}
