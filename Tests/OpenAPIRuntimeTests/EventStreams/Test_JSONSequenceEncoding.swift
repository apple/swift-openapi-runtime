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

final class Test_JSONSequenceEncoding: Test_Runtime {
    
    func testSerialized() async throws {
        let upstream = WrappedSyncSequence(
            sequence: [
                ArraySlice(#"{"name":"Rover"}"#.utf8),
                ArraySlice(#"{"name":"Pancake"}"#.utf8)
            ]
        )
        let sequence = JSONSequenceSerializationSequence(upstream: upstream)
        try await XCTAssertEqualAsyncData(sequence, testJSONSequenceBytes)
    }
    
    func testTyped() async throws {
        let sequence = testEventsAsyncSequence.asEncodedJSONSequence()
        try await XCTAssertEqualAsyncData(sequence, testJSONSequenceBytes)
    }
}
