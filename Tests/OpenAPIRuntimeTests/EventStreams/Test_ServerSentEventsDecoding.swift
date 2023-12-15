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

final class Test_ServerSentEventsDecoding_Lines: Test_Runtime {
    
    func _test(
        input: String,
        output: [String],
        file: StaticString = #file,
        line: UInt = #line
    ) async throws {
        let sequence = asOneBytePerElementSequence(ArraySlice(input.utf8))
            .asParsedServerSentEventLines()
        let lines = try await [ArraySlice<UInt8>](collecting: sequence)
        XCTAssertEqual(lines.count, output.count, file: file, line: line)
        for (index, linePair) in zip(lines, output).enumerated() {
            let (actualLine, expectedLine) = linePair
            XCTAssertEqualData(actualLine, expectedLine.utf8, "Line: \(index)", file: file, line: line)
        }
    }
    
    func test() async throws {
        // LF
        try await _test(
            input: "hello\nworld\n",
            output: [
                "hello",
                "world"
            ]
        )
        // CR
        try await _test(
            input: "hello\rworld\r",
            output: [
                "hello",
                "world"
            ]
        )
        // CRLF
        try await _test(
            input: "hello\r\nworld\r\n",
            output: [
                "hello",
                "world"
            ]
        )
    }
}
