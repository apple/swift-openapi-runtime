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

final class Test_ServerSentEventsDecoding: Test_Runtime {
    func _test(input: String, output: [ServerSentEvent], file: StaticString = #filePath, line: UInt = #line)
        async throws
    {
        let sequence = asOneBytePerElementSequence(ArraySlice(input.utf8)).asDecodedServerSentEvents()
        let events = try await [ServerSentEvent](collecting: sequence)
        XCTAssertEqual(events.count, output.count, file: file, line: line)
        for (index, linePair) in zip(events, output).enumerated() {
            let (actualEvent, expectedEvent) = linePair
            XCTAssertEqual(actualEvent, expectedEvent, "Event: \(index)", file: file, line: line)
        }
    }
    func test() async throws {
        // Simple event.
        try await _test(
            input: #"""
                data: hello
                data: world


                """#,
            output: [.init(data: "hello\nworld")]
        )
        // Two simple events.
        try await _test(
            input: #"""
                data: hello
                data: world

                data: hello2
                data: world2


                """#,
            output: [.init(data: "hello\nworld"), .init(data: "hello2\nworld2")]
        )
        // Incomplete event is not emitted.
        try await _test(
            input: #"""
                data: hello
                """#,
            output: []
        )
        // A few events.
        try await _test(
            input: #"""
                retry: 5000

                data: This is the first message.

                data: This is the second
                data: message.

                event: customEvent
                data: This is a custom event message.

                id: 123
                data: This is a message with an ID.


                """#,
            output: [
                .init(retry: 5000), .init(data: "This is the first message."),
                .init(data: "This is the second\nmessage."),
                .init(event: "customEvent", data: "This is a custom event message."),
                .init(id: "123", data: "This is a message with an ID."),
            ]
        )
    }
    func _testJSONData<JSONType: Decodable & Hashable & Sendable>(
        input: String,
        output: [ServerSentEventWithJSONData<JSONType>],
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws {
        let sequence = asOneBytePerElementSequence(ArraySlice(input.utf8))
            .asDecodedServerSentEventsWithJSONData(of: JSONType.self)
        let events = try await [ServerSentEventWithJSONData<JSONType>](collecting: sequence)
        XCTAssertEqual(events.count, output.count, file: file, line: line)
        for (index, linePair) in zip(events, output).enumerated() {
            let (actualEvent, expectedEvent) = linePair
            XCTAssertEqual(actualEvent, expectedEvent, "Event: \(index)", file: file, line: line)
        }
    }
    struct TestEvent: Decodable, Hashable, Sendable { var index: Int }
    func testJSONData() async throws {
        // Simple event.
        try await _testJSONData(
            input: #"""
                event: event1
                id: 1
                data: {"index":1}

                event: event2
                id: 2
                data: {
                data:   "index": 2
                data: }


                """#,
            output: [
                .init(event: "event1", data: TestEvent(index: 1), id: "1"),
                .init(event: "event2", data: TestEvent(index: 2), id: "2"),
            ]
        )
    }
}

final class Test_ServerSentEventsDecoding_Lines: Test_Runtime {
    func _test(input: String, output: [String], file: StaticString = #filePath, line: UInt = #line) async throws {
        let upstream = asOneBytePerElementSequence(ArraySlice(input.utf8))
        let sequence = ServerSentEventsLineDeserializationSequence(upstream: upstream)
        let lines = try await [ArraySlice<UInt8>](collecting: sequence)
        XCTAssertEqual(lines.count, output.count, file: file, line: line)
        for (index, linePair) in zip(lines, output).enumerated() {
            let (actualLine, expectedLine) = linePair
            XCTAssertEqualData(actualLine, expectedLine.utf8, "Line: \(index)", file: file, line: line)
        }
    }
    func test() async throws {
        // LF
        try await _test(input: "hello\nworld\n", output: ["hello", "world"])
        // CR
        try await _test(input: "hello\rworld\r", output: ["hello", "world"])
        // CRLF
        try await _test(input: "hello\r\nworld\r\n", output: ["hello", "world"])
    }
}
