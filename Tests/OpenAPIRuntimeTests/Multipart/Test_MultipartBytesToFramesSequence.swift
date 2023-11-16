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

final class Test_MultipartBytesToFramesSequence: Test_Runtime {
    func test() async throws {
        var chunk = chunkFromStringLines([
            "--__abcd__", #"Content-Disposition: form-data; name="name""#, "", "24", "--__abcd__",
            #"Content-Disposition: form-data; name="info""#, "", "{}", "--__abcd__--",
        ])
        let next: () async throws -> ArraySlice<UInt8>? = {
            if let first = chunk.first {
                let out: ArraySlice<UInt8> = [first]
                chunk = chunk.dropFirst()
                return out
            } else {
                return nil
            }
        }
        let upstream = HTTPBody(AsyncThrowingStream(unfolding: next), length: .unknown, iterationBehavior: .single)
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
