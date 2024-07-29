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
    func testJSONCoder_defaultConfiguration() throws {
        let configuration = Configuration()
        XCTAssertEqualStringifiedData(
            try configuration.jsonCoder.customEncode(testPetWithPath),
            testPetWithPathPrettifiedWithEscapingSlashes
        )
    }
    func testJSONCoder_defaultInit() throws {
        let coder = FoundationJSONCoder()
        XCTAssertEqualStringifiedData(
            try coder.customEncode(testPetWithPath),
            testPetWithPathPrettifiedWithEscapingSlashes
        )
    }
    func testJSONCoder_minifiedWithoutEscapingSlashes() throws {
        let coder = FoundationJSONCoder(outputFormatting: [.sortedKeys, .withoutEscapingSlashes])
        XCTAssertEqualStringifiedData(
            try coder.customEncode(testPetWithPath),
            testPetWithPathMinifiedWithoutEscapingSlashes
        )
    }
}
