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
import HTTPTypes

final class Test_MultipartBytesToFramesSequence: Test_Runtime {
    func test() async throws {
        let chunk = chunkFromStringLines([
            "--__abcd__", #"Content-Disposition: form-data; name="name""#, "", "24", "--__abcd__",
            #"Content-Disposition: form-data; name="info""#, "", "{}", "--__abcd__--",
        ])
        let upstream = chunk.async.map { ArraySlice([$0]) }
        let sequence = MultipartBytesToFramesSequence(upstream: upstream, boundary: "__abcd__")
        var frames: [MultipartFrame] = []
        for try await frame in sequence { frames.append(frame) }
        XCTAssertEqual(
            frames,
            [
                .headerFields([.contentDisposition: #"form-data; name="name""#]), .bodyChunk(chunkFromString("2")),
                .bodyChunk(chunkFromString("4")), .headerFields([.contentDisposition: #"form-data; name="info""#]),
                .bodyChunk(chunkFromString("{")), .bodyChunk(chunkFromString("}")),
            ]
        )
    }
}

final class Test_MultipartParser: Test_Runtime {
    func test() async throws {
        var chunk = chunkFromStringLines([
            "--__abcd__", #"Content-Disposition: form-data; name="name""#, "", "24", "--__abcd__",
            #"Content-Disposition: form-data; name="info""#, "", "{}", "--__abcd__--",
        ])
        var parser = MultipartParser(boundary: "__abcd__")
        let next: () async throws -> ArraySlice<UInt8>? = {
            if let first = chunk.first {
                let out: ArraySlice<UInt8> = [first]
                chunk = chunk.dropFirst()
                return out
            } else {
                return nil
            }
        }
        var frames: [MultipartFrame] = []
        while let frame = try await parser.next(next) { frames.append(frame) }
        XCTAssertEqual(
            frames,
            [
                .headerFields([.contentDisposition: #"form-data; name="name""#]), .bodyChunk(chunkFromString("2")),
                .bodyChunk(chunkFromString("4")), .headerFields([.contentDisposition: #"form-data; name="info""#]),
                .bodyChunk(chunkFromString("{")), .bodyChunk(chunkFromString("}")),
            ]
        )
    }
}

private func newStateMachine() -> MultipartParser.StateMachine { .init(boundary: "__abcd__") }

final class Test_MultipartParserStateMachine: Test_Runtime {

    func testInvalidInitialBoundary() throws {
        var stateMachine = newStateMachine()
        XCTAssertEqual(stateMachine.receivedChunk(chunkFromString("invalid")), .none)
        XCTAssertEqual(stateMachine.readNextPart(), .emitError(.invalidInitialBoundary))
    }

    func testHeaderFields() throws {
        var stateMachine = newStateMachine()
        XCTAssertEqual(stateMachine.receivedChunk(chunkFromString("--__ab")), .none)
        XCTAssertEqual(stateMachine.readNextPart(), .needsMore)
        XCTAssertEqual(stateMachine.state, .parsingInitialBoundary(bufferFromString("--__ab")))
        XCTAssertEqual(stateMachine.receivedChunk(chunkFromString("cd__", addCRLFs: 1)), .none)
        XCTAssertEqual(stateMachine.readNextPart(), .none)
        XCTAssertEqual(stateMachine.state, .parsingPart([0x0d, 0x0a], .parsingHeaderFields(.init())))
        XCTAssertEqual(stateMachine.receivedChunk(chunkFromString(#"Content-Disposi"#)), .none)
        XCTAssertEqual(
            stateMachine.state,
            .parsingPart([0x0d, 0x0a] + bufferFromString(#"Content-Disposi"#), .parsingHeaderFields(.init()))
        )
        XCTAssertEqual(stateMachine.readNextPart(), .needsMore)
        XCTAssertEqual(
            stateMachine.receivedChunk(chunkFromString(#"tion: form-data; name="name""#, addCRLFs: 2)),
            .none
        )
        XCTAssertEqual(
            stateMachine.state,
            .parsingPart(
                [0x0d, 0x0a] + bufferFromString(#"Content-Disposition: form-data; name="name""#) + [
                    0x0d, 0x0a, 0x0d, 0x0a,
                ],
                .parsingHeaderFields(.init())
            )
        )
        // Reads the first header field.
        XCTAssertEqual(stateMachine.readNextPart(), .none)
        // Reads the end of the header fields section.
        XCTAssertEqual(
            stateMachine.readNextPart(),
            .emitHeaderFields([.contentDisposition: #"form-data; name="name""#])
        )
        XCTAssertEqual(stateMachine.state, .parsingPart([], .parsingBody))
    }

    func testPartBody() throws {
        var stateMachine = newStateMachine()
        let chunk = chunkFromStringLines(["--__abcd__", #"Content-Disposition: form-data; name="name""#, "", "24"])
        XCTAssertEqual(stateMachine.receivedChunk(chunk), .none)
        XCTAssertEqual(stateMachine.state, .parsingInitialBoundary(Array(chunk)))
        // Parse the initial boundary and first header field.
        for _ in 0..<2 { XCTAssertEqual(stateMachine.readNextPart(), .none) }
        // Parse the end of header fields.
        XCTAssertEqual(
            stateMachine.readNextPart(),
            .emitHeaderFields([.contentDisposition: #"form-data; name="name""#])
        )
        XCTAssertEqual(stateMachine.state, .parsingPart(bufferFromString(#"24"#) + [0x0d, 0x0a], .parsingBody))
        XCTAssertEqual(stateMachine.receivedChunk(chunkFromString(".42")), .none)
        XCTAssertEqual(
            stateMachine.state,
            .parsingPart(bufferFromString("24") + [0x0d, 0x0a] + bufferFromString(".42"), .parsingBody)
        )
        XCTAssertEqual(
            stateMachine.readNextPart(),
            .emitBodyChunk(bufferFromString("24") + [0x0d, 0x0a] + bufferFromString(".42"))
        )
        XCTAssertEqual(stateMachine.state, .parsingPart([], .parsingBody))
        XCTAssertEqual(stateMachine.receivedChunk([0x0d, 0x0a] + chunkFromString("--__ab")), .none)
        XCTAssertEqual(stateMachine.state, .parsingPart([0x0d, 0x0a] + chunkFromString("--__ab"), .parsingBody))
        XCTAssertEqual(stateMachine.readNextPart(), .needsMore)
        XCTAssertEqual(stateMachine.receivedChunk(chunkFromString("cd__--", addCRLFs: 1)), .none)
        XCTAssertEqual(
            stateMachine.state,
            .parsingPart([0x0d, 0x0a] + chunkFromString("--__abcd__--", addCRLFs: 1), .parsingBody)
        )
        // Parse the final boundary.
        XCTAssertEqual(stateMachine.readNextPart(), .none)
        // Parse the trailing two dashes.
        XCTAssertEqual(stateMachine.readNextPart(), .returnNil)
    }

    func testTwoParts() throws {
        var stateMachine = newStateMachine()
        let chunk = chunkFromStringLines([
            "--__abcd__", #"Content-Disposition: form-data; name="name""#, "", "24", "--__abcd__",
            #"Content-Disposition: form-data; name="info""#, "", "{}", "--__abcd__--",
        ])
        XCTAssertEqual(stateMachine.receivedChunk(chunk), .none)
        // Parse the initial boundary and first header field.
        for _ in 0..<2 { XCTAssertEqual(stateMachine.readNextPart(), .none) }
        // Parse the end of header fields.
        XCTAssertEqual(
            stateMachine.readNextPart(),
            .emitHeaderFields([.contentDisposition: #"form-data; name="name""#])
        )
        // Parse the first part's body.
        XCTAssertEqual(stateMachine.readNextPart(), .emitBodyChunk(chunkFromString("24")))
        // Parse the boundary.
        XCTAssertEqual(stateMachine.readNextPart(), .none)
        // Parse the end of header fields.
        XCTAssertEqual(
            stateMachine.readNextPart(),
            .emitHeaderFields([.contentDisposition: #"form-data; name="info""#])
        )
        // Parse the second part's body.
        XCTAssertEqual(stateMachine.readNextPart(), .emitBodyChunk(chunkFromString("{}")))
        // Parse the trailing two dashes.
        XCTAssertEqual(stateMachine.readNextPart(), .returnNil)
    }
}
