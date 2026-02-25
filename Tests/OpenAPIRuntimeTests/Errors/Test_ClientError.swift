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

final class Test_ServerError: XCTestCase {
    func testPrinting() throws {
        let upstreamError = RuntimeError.handlerFailed(PrintableError())
        let error: any Error = ServerError(
            operationID: "op",
            request: .init(soar_path: "/test", method: .get),
            requestBody: nil,
            requestMetadata: .init(),
            causeDescription: upstreamError.prettyDescription,
            underlyingError: upstreamError.underlyingError ?? upstreamError,
            httpStatus: .internalServerError,
            httpHeaderFields: [:],
            httpBody: nil
        )
        XCTAssertEqual(
            "\(error)",
            "Server error - cause description: 'User handler threw an error.', underlying error: Just description, operationID: op, request: GET /test [], requestBody: <nil>, metadata: Path parameters: [:], operationInput: <nil>, operationOutput: <nil>"
        )
        XCTAssertEqual(
            error.localizedDescription,
            "Server encountered an error handling the operation \"op\", caused by \"User handler threw an error.\", underlying error: Just description."
        )
    }
}
