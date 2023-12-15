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

final class Test_ServerSentEventsEncoding: Test_Runtime {
    
    func _test(
        input: [ServerSentEvent],
        output: String,
        file: StaticString = #file,
        line: UInt = #line
    ) async throws {
        let sequence = WrappedSyncSequence(
            sequence: input
        ).asEncodedServerSentEvents()
        try await XCTAssertEqualAsyncData(sequence, output.utf8, file: file, line: line)
    }
    
    func test() async throws {
        // Simple event.
        try await _test(
            input: [
                .init(data: "hello\nworld")
            ],
            output: #"""
            data: hello
            data: world
            
            
            """#
        )
        // Two simple events.
        try await _test(
            input: [
                .init(data: "hello\nworld"),
                .init(data: "hello2\nworld2")
            ],
            output: #"""
            data: hello
            data: world
            
            data: hello2
            data: world2

            
            """#
        )
        // A few events.
        try await _test(
            input: [
                .init(retry: 5000),
                .init(data: "This is the first message."),
                .init(data: "This is the second\nmessage."),
                .init(event: "customEvent", data: "This is a custom event message."),
                .init(id: "123", data: "This is a message with an ID.")
            ],
            output: #"""
            retry: 5000

            data: This is the first message.

            data: This is the second
            data: message.

            event: customEvent
            data: This is a custom event message.

            id: 123
            data: This is a message with an ID.

            
            """#
        )
    }
    
    func _testJSONData<JSONType: Encodable & Hashable & Sendable>(
        input: [ServerSentEventWithJSONData<JSONType>],
        output: String,
        file: StaticString = #file,
        line: UInt = #line
    ) async throws {
        let sequence = WrappedSyncSequence(
            sequence: input
        ).asEncodedServerSentEventsWithJSONData()
        try await XCTAssertEqualAsyncData(sequence, output.utf8, file: file, line: line)
    }
    
    struct TestEvent: Encodable, Hashable, Sendable {
        var index: Int
    }
    
    func testJSONData() async throws {
        // Simple event.
        try await _testJSONData(
            input: [
                .init(event: "event1", data: TestEvent(index: 1), id: "1"),
                .init(event: "event2", data: TestEvent(index: 2), id: "2")
            ],
            output: #"""
            id: 1
            event: event1
            data: {"index":1}

            id: 2
            event: event2
            data: {"index":2}


            """#
        )
    }
}
