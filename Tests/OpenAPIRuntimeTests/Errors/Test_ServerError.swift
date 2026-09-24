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

    func testPrintingRedactsSensitiveRequestAndResponseValues() throws {
        let upstreamError = RuntimeError.transportFailed(PrintableError())
        let error: any Error = ClientError(
            operationID: "op",
            operationInput: "test",
            request: .init(
                soar_path: "/test?access_token=request-token&name=jane",
                method: .get,
                headerFields: [
                    .init("Authorization")!: "Bearer request-secret",
                    .init("X-Trace-ID")!: "trace-id",
                ]
            ),
            response: .init(
                status: .ok,
                headerFields: [
                    .init("Set-Cookie")!: "session=response-secret",
                    .init("X-Request-ID")!: "request-id",
                ]
            ),
            causeDescription: upstreamError.prettyDescription,
            underlyingError: upstreamError.underlyingError ?? upstreamError
        )

        let description = "\(error)"
        XCTAssertFalse(description.contains("request-token"))
        XCTAssertFalse(description.contains("request-secret"))
        XCTAssertFalse(description.contains("response-secret"))
        XCTAssertTrue(description.contains("access_token=<redacted>"))
        XCTAssertTrue(description.contains("authorization: <redacted>"))
        XCTAssertTrue(description.contains("set-cookie: <redacted>"))
        XCTAssertTrue(description.contains("x-trace-id: trace-id"))
        XCTAssertTrue(description.contains("x-request-id: request-id"))
    }
}
