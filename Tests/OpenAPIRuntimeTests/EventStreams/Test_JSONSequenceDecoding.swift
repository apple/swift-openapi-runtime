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
@_spi(Generated) @testable import OpenAPIRuntime

final class Test_JSONSequenceDecoding: Test_Runtime {
    func testParsed() async throws {
        let upstream = testJSONSequenceOneBytePerElementSequence
        let sequence = JSONSequenceDeserializationSequence(upstream: upstream)
        let events = try await [ArraySlice<UInt8>](collecting: sequence)
        XCTAssertEqual(events.count, 2)
        XCTAssertEqualData(events[0], "{\"name\":\"Rover\"}\n".utf8)
        XCTAssertEqualData(events[1], "{\"name\":\"Pancake\"}\n".utf8)
    }
    func testTyped() async throws {
        let sequence = testJSONSequenceOneBytePerElementSequence.asDecodedJSONSequence(of: TestPet.self)
        let events = try await [TestPet](collecting: sequence)
        XCTAssertEqual(events, testEvents)
    }
}
