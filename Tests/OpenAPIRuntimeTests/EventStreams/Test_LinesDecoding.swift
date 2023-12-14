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

final class Test_LinesDecoding: Test_Runtime {
    
    func testParsed() async throws {
        let sequence = asOneBytePerElementSequence(ArraySlice("hello\nworld\n".utf8)).asParsedLines()
        let lines = try await [ArraySlice<UInt8>](collecting: sequence)
        XCTAssertEqual(lines.count, 2)
        XCTAssertEqualData(lines[0], "hello".utf8)
        XCTAssertEqualData(lines[1], "world".utf8)
    }
}
