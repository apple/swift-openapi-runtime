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

final class Test_Configuration: Test_Runtime {

    func testDateTranscoder_iso8601() throws {
        let transcoder: any DateTranscoder = .iso8601
        XCTAssertEqual(try transcoder.encode(testDate), testDateString)
        XCTAssertEqual(testDate, try transcoder.decode(testDateString))
    }

    func testDateTranscoder_iso8601WithFractionalSeconds() throws {
        let transcoder: any DateTranscoder = .iso8601WithFractionalSeconds
        XCTAssertEqual(try transcoder.encode(testDateWithFractionalSeconds), testDateWithFractionalSecondsString)
        XCTAssertEqual(testDateWithFractionalSeconds, try transcoder.decode(testDateWithFractionalSecondsString))
    }

    func testJSONEncodingOptions_default() throws {
        let converter = Converter(configuration: Configuration())
        XCTAssertEqualStringifiedData(
            try converter.encoder.encode(testPetWithPath),
            testPetWithPathPrettifiedWithEscapingSlashes
        )
    }

    func testJSONEncodingOptions_empty() throws {
        let converter = Converter(
            configuration: Configuration(jsonEncodingOptions: [
                .sortedKeys  // without sorted keys, this test would be unreliable
            ])
        )
        XCTAssertEqualStringifiedData(
            try converter.encoder.encode(testPetWithPath),
            testPetWithPathMinifiedWithEscapingSlashes
        )
    }

    func testJSONEncodingOptions_prettyWithoutEscapingSlashes() throws {
        let converter = Converter(
            configuration: Configuration(jsonEncodingOptions: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])
        )
        XCTAssertEqualStringifiedData(
            try converter.encoder.encode(testPetWithPath),
            testPetWithPathPrettifiedWithoutEscapingSlashes
        )
    }
}
