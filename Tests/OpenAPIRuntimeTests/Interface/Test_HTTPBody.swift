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
@_spi(Generated)@testable import OpenAPIRuntime
import Foundation

final class Test_Body: Test_Runtime {

    func testCreateAndCollect() async throws {

        // A single string.
        do {
            let body: HTTPBody = HTTPBody("hello")
            try await _testConsume(
                body,
                expected: "hello"
            )
        }

        // A literal string.
        do {
            let body: HTTPBody = "hello"
            try await _testConsume(
                body,
                expected: "hello"
            )
        }

        // A single substring.
        do {
            let substring: Substring = "hello"
            let body: HTTPBody = HTTPBody(substring)
            try await _testConsume(
                body,
                expected: "hello"
            )
        }

        // A single array of bytes.
        do {
            let body: HTTPBody = HTTPBody([0])
            try await _testConsume(
                body,
                expected: [0]
            )
        }

        // A literal array of bytes.
        do {
            let body: HTTPBody = [0]
            try await _testConsume(
                body,
                expected: [0]
            )
        }

        // A single data.
        do {
            let body: HTTPBody = HTTPBody(Data([0]))
            try await _testConsume(
                body,
                expected: [0]
            )
        }

        // A single slice of an array of bytes.
        do {
            let body: HTTPBody = HTTPBody([0][...])
            try await _testConsume(
                body,
                expected: [0][...]
            )
        }

        // An async throwing stream.
        do {
            let body: HTTPBody = HTTPBody(
                AsyncThrowingStream(
                    String.self,
                    { continuation in
                        continuation.yield("hel")
                        continuation.yield("lo")
                        continuation.finish()
                    }
                ),
                length: .known(5)
            )
            try await _testConsume(
                body,
                expected: "hello"
            )
        }

        // An async stream.
        do {
            let body: HTTPBody = HTTPBody(
                AsyncStream(
                    String.self,
                    { continuation in
                        continuation.yield("hel")
                        continuation.yield("lo")
                        continuation.finish()
                    }
                ),
                length: .known(5)
            )
            try await _testConsume(
                body,
                expected: "hello"
            )
        }

        // Another async sequence.
        do {
            let sequence = AsyncStream(
                String.self,
                { continuation in
                    continuation.yield("hel")
                    continuation.yield("lo")
                    continuation.finish()
                }
            )
            .map { $0 }
            let body: HTTPBody = HTTPBody(
                sequence,
                length: .known(5),
                iterationBehavior: .single
            )
            try await _testConsume(
                body,
                expected: "hello"
            )
        }
    }

    func testChunksPreserved() async throws {
        let sequence = AsyncStream(
            String.self,
            { continuation in
                continuation.yield("hel")
                continuation.yield("lo")
                continuation.finish()
            }
        )
        .map { $0 }
        let body: HTTPBody = HTTPBody(
            sequence,
            length: .known(5),
            iterationBehavior: .single
        )
        var chunks: [HTTPBody.ByteChunk] = []
        for try await chunk in body {
            chunks.append(chunk)
        }
        XCTAssertEqual(chunks, ["hel", "lo"].map { Array($0.utf8)[...] })
    }
}

extension Test_Body {
    func _testConsume(
        _ body: HTTPBody,
        expected: HTTPBody.ByteChunk,
        file: StaticString = #file,
        line: UInt = #line
    ) async throws {
        let output = try await ArraySlice(collecting: body, upTo: .max)
        XCTAssertEqual(output, expected, file: file, line: line)
    }

    func _testConsume(
        _ body: HTTPBody,
        expected: some StringProtocol,
        file: StaticString = #file,
        line: UInt = #line
    ) async throws {
        let output = try await String(collecting: body, upTo: .max)
        XCTAssertEqual(output, expected.description, file: file, line: line)
    }
}
