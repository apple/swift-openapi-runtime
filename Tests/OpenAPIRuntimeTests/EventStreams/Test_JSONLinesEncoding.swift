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
import Foundation

final class Test_JSONLinesEncoding: Test_Runtime {
    
    func testSerialized() async throws {
        let sequence = WrappedSyncSequence(
            sequence: [
                ArraySlice(#"{"name":"Rover"}"#.utf8),
                ArraySlice(#"{"name":"Pancake"}"#.utf8)
            ]
        ).asSerializedLines()
        try await XCTAssertEqualAsyncData(sequence, testJSONLinesBytes)
    }
    
    func testTyped() async throws {
        let sequence = testEventsAsyncSequence.asEncodedJSONLines()
        try await XCTAssertEqualAsyncData(sequence, testJSONLinesBytes)
    }
}
