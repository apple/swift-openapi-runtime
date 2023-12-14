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

final class Test_JSONLinesDecoding: Test_Runtime {
    
    func testTyped() async throws {
        let sequence = testJSONLinesOneBytePerElementSequence.asDecodedJSONLines(of: TestPet.self)
        let events = try await [TestPet](collecting: sequence)
        XCTAssertEqual(events, testEvents)
    }
}
