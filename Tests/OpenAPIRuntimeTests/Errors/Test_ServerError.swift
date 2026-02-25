//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftOpenAPIGenerator open source project
//
// Copyright (c) 2025 Apple Inc. and the SwiftOpenAPIGenerator project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftOpenAPIGenerator project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Foundation
import HTTPTypes
@_spi(Generated) @testable import OpenAPIRuntime
import XCTest

final class Test_ClientError: XCTestCase {
    func testPrinting() throws {
        let upstreamError = RuntimeError.transportFailed(PrintableError())
        let error: any Error = ClientError(
            operationID: "op",
            operationInput: "test",
            causeDescription: upstreamError.prettyDescription,
            underlyingError: upstreamError.underlyingError ?? upstreamError
        )
        XCTAssertEqual(
            "\(error)",
            "Client error - cause description: 'Transport threw an error.', underlying error: Just description, operationID: op, operationInput: test, request: <nil>, requestBody: <nil>, baseURL: <nil>, response: <nil>, responseBody: <nil>"
        )
        XCTAssertEqual(
            error.localizedDescription,
            "Client encountered an error invoking the operation \"op\", caused by \"Transport threw an error.\", underlying error: Just description."
        )
    }
}
