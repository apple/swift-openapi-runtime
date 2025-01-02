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

final class Test_MultipartFramesToBytesSequence: Test_Runtime {
    func test() async throws {
        let frames: [MultipartFrame] = [
            .headerFields([.contentDisposition: #"form-data; name="name""#]), .bodyChunk(chunkFromString("2")),
            .bodyChunk(chunkFromString("4")), .headerFields([.contentDisposition: #"form-data; name="info""#]),
            .bodyChunk(chunkFromString("{")), .bodyChunk(chunkFromString("}")),
        ]
        var iterator = frames.makeIterator()
        let upstream = AsyncStream { iterator.next() }
        let sequence = MultipartFramesToBytesSequence(upstream: upstream, boundary: "__abcd__")
        var bytes: ArraySlice<UInt8> = []
        for try await chunk in sequence { bytes.append(contentsOf: chunk) }
        let expectedBytes = chunkFromStringLines([
            "--__abcd__", #"content-disposition: form-data; name="name""#, "", "24", "--__abcd__",
            #"content-disposition: form-data; name="info""#, "", "{}", "--__abcd__--", "",
        ])
        XCTAssertEqualData(bytes, expectedBytes)
    }
}

final class Test_MultipartSerializer: Test_Runtime {
    func test() async throws {
        let frames: [MultipartFrame] = [
            .headerFields([.contentDisposition: #"form-data; name="name""#]), .bodyChunk(chunkFromString("2")),
            .bodyChunk(chunkFromString("4")), .headerFields([.contentDisposition: #"form-data; name="info""#]),
            .bodyChunk(chunkFromString("{")), .bodyChunk(chunkFromString("}")),
        ]
        var serializer = MultipartSerializer(boundary: "__abcd__")
        var iterator = frames.makeIterator()
        var bytes: [UInt8] = []
        while let chunk = try await serializer.next({ iterator.next() }) { bytes.append(contentsOf: chunk) }
        let expectedBytes = chunkFromStringLines([
            "--__abcd__", #"content-disposition: form-data; name="name""#, "", "24", "--__abcd__",
            #"content-disposition: form-data; name="info""#, "", "{}", "--__abcd__--", "",
        ])
        XCTAssertEqualData(bytes, expectedBytes)
    }
}

private func newStateMachine() -> MultipartSerializer.StateMachine { .init() }

final class Test_MultipartSerializerStateMachine: Test_Runtime {

    func testInvalidFirstFrame() throws {
        var stateMachine = newStateMachine()
        XCTAssertEqual(stateMachine.next(), .emitStart)
        XCTAssertEqual(stateMachine.next(), .needsMore)
        XCTAssertEqual(stateMachine.receivedFrame(.bodyChunk([])), .emitError(.noHeaderFieldsAtStart))
    }

    func testTwoParts() throws {
        var stateMachine = newStateMachine()
        XCTAssertEqual(stateMachine.state, .initial)
        XCTAssertEqual(stateMachine.next(), .emitStart)
        XCTAssertEqual(stateMachine.state, .startedNothingEmittedYet)
        XCTAssertEqual(
            stateMachine.receivedFrame(.headerFields([.contentDisposition: #"form-data; name="name""#])),
            .emitEvents([.headerFields([.contentDisposition: #"form-data; name="name""#])])
        )
        XCTAssertEqual(stateMachine.state, .emittedHeaders)
        XCTAssertEqual(stateMachine.next(), .needsMore)
        XCTAssertEqual(
            stateMachine.receivedFrame(.bodyChunk(chunkFromString("24"))),
            .emitEvents([.bodyChunk(chunkFromString("24"))])
        )
        XCTAssertEqual(stateMachine.state, .emittedBodyChunk)
        XCTAssertEqual(stateMachine.next(), .needsMore)
        XCTAssertEqual(
            stateMachine.receivedFrame(.headerFields([.contentDisposition: #"form-data; name="info""#])),
            .emitEvents([.endOfPart, .headerFields([.contentDisposition: #"form-data; name="info""#])])
        )
        XCTAssertEqual(stateMachine.state, .emittedHeaders)
        XCTAssertEqual(stateMachine.next(), .needsMore)
        XCTAssertEqual(
            stateMachine.receivedFrame(.bodyChunk(chunkFromString("{}"))),
            .emitEvents([.bodyChunk(chunkFromString("{}"))])
        )
        XCTAssertEqual(stateMachine.state, .emittedBodyChunk)
        XCTAssertEqual(stateMachine.next(), .needsMore)
        XCTAssertEqual(stateMachine.receivedFrame(nil), .emitEvents([.endOfPart, .end]))
    }
}
