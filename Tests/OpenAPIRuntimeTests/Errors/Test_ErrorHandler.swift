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

import HTTPTypes
@_spi(Generated) @testable import OpenAPIRuntime
import XCTest

// MARK: - Test Helpers

/// A custom client error handler that logs all errors for testing
final class LoggingClientErrorHandler: ClientErrorHandler {
    var handledErrors: [ClientError] = []
    private let lock = NSLock()

    func handleClientError(_ error: ClientError) {
        lock.lock()
        handledErrors.append(error)
        lock.unlock()
    }
}

/// A custom server error handler that logs all errors for testing
final class LoggingServerErrorHandler: ServerErrorHandler {
    var handledErrors: [ServerError] = []
    private let lock = NSLock()

    func handleServerError(_ error: ServerError) {
        lock.lock()
        handledErrors.append(error)
        lock.unlock()
    }
}

// MARK: - ErrorHandler Tests

final class Test_ErrorHandler: XCTestCase {

    func testClientErrorHandler_IsCalledWithClientError() throws {
        let handler = LoggingClientErrorHandler()
        let clientError = ClientError(
            operationID: "testOp",
            operationInput: "test-input",
            request: .init(soar_path: "/test", method: .get),
            requestBody: nil,
            baseURL: URL(string: "https://example.com"),
            response: nil,
            responseBody: nil,
            causeDescription: "Test error",
            underlyingError: NSError(domain: "test", code: 1)
        )

        handler.handleClientError(clientError)

        XCTAssertEqual(handler.handledErrors.count, 1)
        XCTAssertEqual(handler.handledErrors[0].operationID, "testOp")
        XCTAssertEqual(handler.handledErrors[0].causeDescription, "Test error")
    }

    func testServerErrorHandler_IsCalledWithServerError() throws {
        let handler = LoggingServerErrorHandler()
        let serverError = ServerError(
            operationID: "testOp",
            request: .init(soar_path: "/test", method: .post),
            requestBody: nil,
            requestMetadata: .init(),
            operationInput: "test-input",
            operationOutput: nil,
            causeDescription: "Test error",
            underlyingError: NSError(domain: "test", code: 1),
            httpStatus: .badRequest,
            httpHeaderFields: [:],
            httpBody: nil
        )

        handler.handleServerError(serverError)

        XCTAssertEqual(handler.handledErrors.count, 1)
        XCTAssertEqual(handler.handledErrors[0].operationID, "testOp")
        XCTAssertEqual(handler.handledErrors[0].httpStatus, .badRequest)
    }

    func testMultipleErrors_AreAllLogged() throws {
        let clientHandler = LoggingClientErrorHandler()
        let serverHandler = LoggingServerErrorHandler()

        // Log multiple client errors
        for i in 1...3 {
            let error = ClientError(
                operationID: "op\(i)",
                operationInput: nil as String?,
                request: nil,
                requestBody: nil,
                baseURL: nil,
                response: nil,
                responseBody: nil,
                causeDescription: "Error \(i)",
                underlyingError: NSError(domain: "test", code: i)
            )
            clientHandler.handleClientError(error)
        }

        // Log multiple server errors
        for i in 1...3 {
            let error = ServerError(
                operationID: "op\(i)",
                request: .init(soar_path: "/test", method: .get),
                requestBody: nil,
                requestMetadata: .init(),
                operationInput: nil as String?,
                operationOutput: nil as String?,
                causeDescription: "Error \(i)",
                underlyingError: NSError(domain: "test", code: i),
                httpStatus: .internalServerError,
                httpHeaderFields: [:],
                httpBody: nil
            )
            serverHandler.handleServerError(error)
        }

        XCTAssertEqual(clientHandler.handledErrors.count, 3)
        XCTAssertEqual(serverHandler.handledErrors.count, 3)
    }
}
