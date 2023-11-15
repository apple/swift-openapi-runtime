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
