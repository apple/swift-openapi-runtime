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

final class Test_MultipartRawPartsToFramesSequence: Test_Runtime {
    func test() async throws {
        var secondPartChunks = "{}".utf8.makeIterator()
        let secondPartBody = HTTPBody(
            AsyncStream(unfolding: { secondPartChunks.next().map { ArraySlice([$0]) } }),
            length: .unknown
        )
        let parts: [MultipartRawPart] = [
            .init(headerFields: [.contentDisposition: #"form-data; name="name""#], body: "24"),
            .init(headerFields: [.contentDisposition: #"form-data; name="info""#], body: secondPartBody),
        ]
        var upstreamIterator = parts.makeIterator()
        let upstream = AsyncStream { upstreamIterator.next() }
        let sequence = MultipartRawPartsToFramesSequence(upstream: upstream)

        var frames: [MultipartFrame] = []
        for try await frame in sequence { frames.append(frame) }
        let expectedFrames: [MultipartFrame] = [
            .headerFields([.contentDisposition: #"form-data; name="name""#]), .bodyChunk(chunkFromString("24")),
            .headerFields([.contentDisposition: #"form-data; name="info""#]), .bodyChunk(chunkFromString("{")),
            .bodyChunk(chunkFromString("}")),
        ]
        XCTAssertEqual(frames, expectedFrames)
    }
}

final class Test_MultipartRawPartsToFramesSequenceSerializer: Test_Runtime {
    func test() async throws {
        var secondPartChunks = "{}".utf8.makeIterator()
        let secondPartBody = HTTPBody(
            AsyncStream(unfolding: { secondPartChunks.next().map { ArraySlice([$0]) } }),
            length: .unknown
        )
        let parts: [MultipartRawPart] = [
            .init(headerFields: [.contentDisposition: #"form-data; name="name""#], body: "24"),
            .init(headerFields: [.contentDisposition: #"form-data; name="info""#], body: secondPartBody),
        ]
        var upstreamIterator = parts.makeIterator()
        let upstream = AsyncStream { upstreamIterator.next() }
        var serializer = MultipartRawPartsToFramesSequence<AsyncStream<MultipartRawPart>>
            .Serializer(upstream: upstream.makeAsyncIterator())
        var frames: [MultipartFrame] = []
        while let frame = try await serializer.next() { frames.append(frame) }
        let expectedFrames: [MultipartFrame] = [
            .headerFields([.contentDisposition: #"form-data; name="name""#]), .bodyChunk(chunkFromString("24")),
            .headerFields([.contentDisposition: #"form-data; name="info""#]), .bodyChunk(chunkFromString("{")),
            .bodyChunk(chunkFromString("}")),
        ]
        XCTAssertEqual(frames, expectedFrames)
    }
}

private func newStateMachine() -> MultipartRawPartsToFramesSequence<AsyncStream<MultipartRawPart>>.StateMachine {
    .init()
}

final class Test_MultipartRawPartsToFramesSequenceStateMachine: Test_Runtime {

    func testTwoParts() throws {
        var stateMachine = newStateMachine()
        XCTAssertTrue(stateMachine.state.isInitial)
        XCTAssertTrue(stateMachine.next().isFetchPart)
        XCTAssertTrue(stateMachine.state.isWaitingForPart)
        XCTAssertEqual(
            stateMachine.receivedPart(
                .init(headerFields: [.contentDisposition: #"form-data; name="name""#], body: "24")
            ),
            .emitHeaderFields([.contentDisposition: #"form-data; name="name""#])
        )
        XCTAssertTrue(stateMachine.state.isStreamingBody)
        XCTAssertTrue(stateMachine.next().isFetchBodyChunk)
        XCTAssertEqual(stateMachine.receivedBodyChunk(chunkFromString("24")), .emitBodyChunk(chunkFromString("24")))
        XCTAssertTrue(stateMachine.state.isStreamingBody)
        XCTAssertTrue(stateMachine.next().isFetchBodyChunk)
        XCTAssertEqual(stateMachine.receivedBodyChunk(nil), .fetchPart)
        XCTAssertEqual(
            stateMachine.receivedPart(
                .init(headerFields: [.contentDisposition: #"form-data; name="info""#], body: "{}")
            ),
            .emitHeaderFields([.contentDisposition: #"form-data; name="info""#])
        )
        XCTAssertTrue(stateMachine.state.isStreamingBody)
        XCTAssertTrue(stateMachine.next().isFetchBodyChunk)
        XCTAssertEqual(stateMachine.receivedBodyChunk(chunkFromString("{")), .emitBodyChunk(chunkFromString("{")))
        XCTAssertTrue(stateMachine.state.isStreamingBody)
        XCTAssertTrue(stateMachine.next().isFetchBodyChunk)
        XCTAssertEqual(stateMachine.receivedBodyChunk(chunkFromString("}")), .emitBodyChunk(chunkFromString("}")))
        XCTAssertTrue(stateMachine.state.isStreamingBody)
        XCTAssertTrue(stateMachine.next().isFetchBodyChunk)
        XCTAssertEqual(stateMachine.receivedBodyChunk(nil), .fetchPart)
        XCTAssertEqual(stateMachine.receivedPart(nil), .returnNil)
    }
}

extension MultipartRawPartsToFramesSequence.StateMachine.State {
    var isInitial: Bool {
        guard case .initial = self else { return false }
        return true
    }
    var isWaitingForPart: Bool {
        guard case .waitingForPart = self else { return false }
        return true
    }
    var isStreamingBody: Bool {
        guard case .streamingBody = self else { return false }
        return true
    }
    var isFinished: Bool {
        guard case .finished = self else { return false }
        return true
    }
}

extension MultipartRawPartsToFramesSequence.StateMachine.NextAction {
    var isReturnNil: Bool {
        guard case .returnNil = self else { return false }
        return true
    }
    var isFetchPart: Bool {
        guard case .fetchPart = self else { return false }
        return true
    }
    var isFetchBodyChunk: Bool {
        guard case .fetchBodyChunk = self else { return false }
        return true
    }
}
