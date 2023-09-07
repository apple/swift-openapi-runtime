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
            let body: HTTPBody = HTTPBody(string: "hello")
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

        // A sequence of strings.
        do {
            let body: HTTPBody = HTTPBody(stringChunks: ["hel", "lo"])
            try await _testConsume(
                body,
                expected: "hello"
            )
        }

        // A single substring.
        do {
            let body: HTTPBody = HTTPBody(string: "hello")
            try await _testConsume(
                body,
                expected: "hello"
            )
        }

        // A sequence of substrings.
        do {
            let body: HTTPBody = HTTPBody(stringChunks: [
                "hel",
                "lo",
            ])
            try await _testConsume(
                body,
                expected: "hello"[...]
            )
        }

        // A single array of bytes.
        do {
            let body: HTTPBody = HTTPBody(bytes: [0])
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
            let body: HTTPBody = HTTPBody(data: Data([0]))
            try await _testConsume(
                body,
                expected: [0]
            )
        }

        // A sequence of arrays of bytes.
        do {
            let body: HTTPBody = HTTPBody(byteChunks: [[0], [1]])
            try await _testConsume(
                body,
                expected: [0, 1]
            )
        }

        // A single slice of an array of bytes.
        do {
            let body: HTTPBody = HTTPBody(bytes: [0][...])
            try await _testConsume(
                body,
                expected: [0][...]
            )
        }

        // A sequence of slices of an array of bytes.
        do {
            let body: HTTPBody = HTTPBody(byteChunks: [
                [0][...],
                [1][...],
            ])
            try await _testConsume(
                body,
                expected: [0, 1][...]
            )
        }

        // An async throwing stream.
        do {
            let body: HTTPBody = HTTPBody(
                stream: AsyncThrowingStream(
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
                stream: AsyncStream(
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
                sequence: sequence,
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
            sequence: sequence,
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
        let output = try await body.collect(upTo: .max)
        XCTAssertEqual(output, expected, file: file, line: line)
    }

    func _testConsume(
        _ body: HTTPBody,
        expected: some StringProtocol,
        file: StaticString = #file,
        line: UInt = #line
    ) async throws {
        let output = try await body.collectAsString(upTo: .max)
        XCTAssertEqual(output, expected.description, file: file, line: line)
    }
}
