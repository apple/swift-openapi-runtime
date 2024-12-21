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
import HTTPTypes

final class Test_MultipartFramesToRawPartsSequence: Test_Runtime {
    func test() async throws {
        let frames: [MultipartFrame] = [
            .headerFields([.contentDisposition: #"form-data; name="name""#]), .bodyChunk(chunkFromString("2")),
            .bodyChunk(chunkFromString("4")), .headerFields([.contentDisposition: #"form-data; name="info""#]),
            .bodyChunk(chunkFromString("{")), .bodyChunk(chunkFromString("}")),
        ]
        var upstreamIterator = frames.makeIterator()
        let upstream = AsyncStream { upstreamIterator.next() }
        let sequence = MultipartFramesToRawPartsSequence(upstream: upstream)
        var iterator = sequence.makeAsyncIterator()
        guard let part1 = try await iterator.next() else {
            XCTFail("Missing part")
            return
        }
        XCTAssertEqual(part1.headerFields, [.contentDisposition: #"form-data; name="name""#])
        try await XCTAssertEqualStringifiedData(part1.body, "24")
        guard let part2 = try await iterator.next() else {
            XCTFail("Missing part")
            return
        }
        XCTAssertEqual(part2.headerFields, [.contentDisposition: #"form-data; name="info""#])
        try await XCTAssertEqualStringifiedData(part2.body, "{}")

        let part3 = try await iterator.next()
        XCTAssertNil(part3)
    }
}

final class Test_MultipartFramesToRawPartsSequenceIterator: Test_Runtime {
    func test() async throws {
        let frames: [MultipartFrame] = [
            .headerFields([.contentDisposition: #"form-data; name="name""#]), .bodyChunk(chunkFromString("2")),
            .bodyChunk(chunkFromString("4")), .headerFields([.contentDisposition: #"form-data; name="info""#]),
            .bodyChunk(chunkFromString("{")), .bodyChunk(chunkFromString("}")),
        ]
        var upstreamSyncIterator = frames.makeIterator()
        let upstream = AsyncStream { upstreamSyncIterator.next() }
        let sharedIterator = MultipartFramesToRawPartsSequence<AsyncStream<MultipartFrame>>
            .SharedIterator(makeUpstreamIterator: { upstream.makeAsyncIterator() })
        let bodyClosure: @Sendable () async throws -> ArraySlice<UInt8>? = {
            try await sharedIterator.nextFromBodySubsequence()
        }
        guard let part1 = try await sharedIterator.nextFromPartSequence(bodyClosure: bodyClosure) else {
            XCTFail("Missing part")
            return
        }
        XCTAssertEqual(part1.headerFields, [.contentDisposition: #"form-data; name="name""#])
        try await XCTAssertEqualStringifiedData(part1.body, "24")
        guard let part2 = try await sharedIterator.nextFromPartSequence(bodyClosure: bodyClosure) else {
            XCTFail("Missing part")
            return
        }
        XCTAssertEqual(part2.headerFields, [.contentDisposition: #"form-data; name="info""#])
        try await XCTAssertEqualStringifiedData(part2.body, "{}")

        let part3 = try await sharedIterator.nextFromPartSequence(bodyClosure: bodyClosure)
        XCTAssertNil(part3)
    }
}

private func newStateMachine() -> MultipartFramesToRawPartsSequence<AsyncStream<MultipartFrame>>.StateMachine {
    .init()
}

final class Test_MultipartFramesToRawPartsSequenceIteratorStateMachine: Test_Runtime {

    func testInvalidFirstFrame() throws {
        var stateMachine = newStateMachine()
        XCTAssertEqual(stateMachine.state, .initial)
        XCTAssertEqual(stateMachine.nextFromPartSequence(), .fetchFrame)
        XCTAssertEqual(stateMachine.state, .waitingToSendHeaders(nil))
        XCTAssertEqual(
            stateMachine.partReceivedFrame(.bodyChunk([])),
            .emitError(.receivedBodyChunkWhenWaitingForHeaders)
        )
    }

    func testTwoParts() throws {
        var stateMachine = newStateMachine()
        XCTAssertEqual(stateMachine.state, .initial)
        XCTAssertEqual(stateMachine.nextFromPartSequence(), .fetchFrame)
        XCTAssertEqual(stateMachine.state, .waitingToSendHeaders(nil))
        XCTAssertEqual(
            stateMachine.partReceivedFrame(.headerFields([.contentDisposition: #"form-data; name="name""#])),
            .emitPart([.contentDisposition: #"form-data; name="name""#])
        )
        XCTAssertEqual(stateMachine.state, .streamingBody)
        XCTAssertEqual(stateMachine.nextFromBodySubsequence(), .fetchFrame)
        XCTAssertEqual(stateMachine.state, .streamingBody)
        XCTAssertEqual(
            stateMachine.bodyReceivedFrame(.bodyChunk(chunkFromString("24"))),
            .returnChunk(chunkFromString("24"))
        )
        XCTAssertEqual(stateMachine.state, .streamingBody)
        XCTAssertEqual(stateMachine.nextFromBodySubsequence(), .fetchFrame)
        XCTAssertEqual(
            stateMachine.bodyReceivedFrame(.headerFields([.contentDisposition: #"form-data; name="info""#])),
            .returnNil
        )
        XCTAssertEqual(stateMachine.state, .waitingToSendHeaders([.contentDisposition: #"form-data; name="info""#]))
        XCTAssertEqual(
            stateMachine.nextFromPartSequence(),
            .emitPart([.contentDisposition: #"form-data; name="info""#])
        )
        XCTAssertEqual(stateMachine.state, .streamingBody)
        XCTAssertEqual(stateMachine.nextFromBodySubsequence(), .fetchFrame)
        XCTAssertEqual(
            stateMachine.bodyReceivedFrame(.bodyChunk(chunkFromString("{}"))),
            .returnChunk(chunkFromString("{}"))
        )
        XCTAssertEqual(stateMachine.nextFromBodySubsequence(), .fetchFrame)
        XCTAssertEqual(stateMachine.bodyReceivedFrame(nil), .returnNil)
        XCTAssertEqual(stateMachine.state, .finished)
        XCTAssertEqual(stateMachine.nextFromPartSequence(), .returnNil)
    }
}
