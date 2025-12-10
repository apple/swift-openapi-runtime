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
import Foundation
@_spi(Generated) @testable import OpenAPIRuntime
import XCTest

// MARK: - Test Helpers

/// Tracks all client errors that pass through it
final class TrackingClientErrorHandler: ClientErrorHandler {
    private let lock = NSLock()
    private var _handledErrors: [ClientError] = []

    var handledErrors: [ClientError] {
        lock.lock()
        defer { lock.unlock() }
        return _handledErrors
    }

    func handleClientError(_ error: ClientError) {
        lock.lock()
        _handledErrors.append(error)
        lock.unlock()
    }
}

/// Tracks all server errors that pass through it
final class TrackingServerErrorHandler: ServerErrorHandler {
    private let lock = NSLock()
    private var _handledErrors: [ServerError] = []

    var handledErrors: [ServerError] {
        lock.lock()
        defer { lock.unlock() }
        return _handledErrors
    }

    func handleServerError(_ error: ServerError) {
        lock.lock()
        _handledErrors.append(error)
        lock.unlock()
    }
}

/// Mock client transport for testing
struct TestClientTransport: ClientTransport {
    var sendBlock: @Sendable (HTTPRequest, HTTPBody?, URL, String) async throws -> (HTTPResponse, HTTPBody?)

    func send(_ request: HTTPRequest, body: HTTPBody?, baseURL: URL, operationID: String) async throws -> (
        HTTPResponse, HTTPBody?
    ) { try await sendBlock(request, body, baseURL, operationID) }

    static var successful: Self {
        TestClientTransport { _, _, _, _ in (HTTPResponse(status: .ok), HTTPBody("success")) }
    }

    static var failing: Self { TestClientTransport { _, _, _, _ in throw NSError(domain: "Transport", code: -1) } }
}

/// Mock API handler for testing
struct TestAPIHandler: Sendable {
    var handleBlock: @Sendable (String) async throws -> String

    func handleRequest(_ input: String) async throws -> String { try await handleBlock(input) }

    static var successful: Self { TestAPIHandler { input in "Response: \(input)" } }

    static var failing: Self {
        TestAPIHandler { _ in throw NSError(domain: "Handler", code: -1, userInfo: [NSLocalizedDescriptionKey: "Handler failed"]) }
    }
}

// MARK: - Integration Tests

final class Test_ErrorHandlerIntegration: XCTestCase {

    // MARK: Client Integration Tests

    func testUniversalClient_CallsErrorHandler_OnSerializationError() async throws {
        let trackingHandler = TrackingClientErrorHandler()
        let configuration = Configuration(clientErrorHandler: trackingHandler)
        let client = UniversalClient(configuration: configuration, transport: TestClientTransport.successful)

        do {
            _ = try await client.send(
                input: "test",
                forOperation: "testOp",
                serializer: { _ in throw NSError(domain: "Serialization", code: 1) },
                deserializer: { _, _ in "" }
            )
            XCTFail("Expected error to be thrown")
        } catch {
            // Verify the error handler was called
            XCTAssertEqual(trackingHandler.handledErrors.count, 1)
            XCTAssertEqual(trackingHandler.handledErrors[0].operationID, "testOp")

            // Verify the error is a ClientError
            XCTAssertTrue(error is ClientError)
        }
    }

    func testUniversalClient_CallsErrorHandler_OnTransportError() async throws {
        let trackingHandler = TrackingClientErrorHandler()
        let configuration = Configuration(clientErrorHandler: trackingHandler)
        let client = UniversalClient(configuration: configuration, transport: TestClientTransport.failing)

        do {
            _ = try await client.send(
                input: "test",
                forOperation: "testOp",
                serializer: { _ in (HTTPRequest(soar_path: "/test", method: .get), nil) },
                deserializer: { _, _ in "" }
            )
            XCTFail("Expected error to be thrown")
        } catch {
            // Verify the error handler was called
            XCTAssertEqual(trackingHandler.handledErrors.count, 1)
            XCTAssertEqual(trackingHandler.handledErrors[0].operationID, "testOp")

            // Verify the error is a ClientError
            guard let clientError = error as? ClientError else {
                XCTFail("Expected ClientError")
                return
            }

            // Should be wrapped in RuntimeError.transportFailed
            XCTAssertTrue(clientError.causeDescription.contains("Transport"))
        }
    }

    func testUniversalClient_CallsErrorHandler_OnDeserializationError() async throws {
        let trackingHandler = TrackingClientErrorHandler()
        let configuration = Configuration(clientErrorHandler: trackingHandler)
        let client = UniversalClient(configuration: configuration, transport: TestClientTransport.successful)

        do {
            _ = try await client.send(
                input: "test",
                forOperation: "testOp",
                serializer: { _ in (HTTPRequest(soar_path: "/test", method: .get), nil) },
                deserializer: { _, _ in throw NSError(domain: "Deserialization", code: 1) }
            )
            XCTFail("Expected error to be thrown")
        } catch {
            // Verify the error handler was called
            XCTAssertEqual(trackingHandler.handledErrors.count, 1)
            XCTAssertEqual(trackingHandler.handledErrors[0].operationID, "testOp")

            // Verify the error is a ClientError
            XCTAssertTrue(error is ClientError)
        }
    }

    func testUniversalClient_DoesNotCallHandler_WhenNotConfigured() async throws {
        // No custom handler in configuration
        let client = UniversalClient(transport: TestClientTransport.failing)

        do {
            _ = try await client.send(
                input: "test",
                forOperation: "testOp",
                serializer: { _ in (HTTPRequest(soar_path: "/test", method: .get), nil) },
                deserializer: { _, _ in "" }
            )
            XCTFail("Expected error to be thrown")
        } catch {
            // Should still produce a ClientError
            guard let clientError = error as? ClientError else {
                XCTFail("Expected ClientError")
                return
            }

            XCTAssertEqual(clientError.operationID, "testOp")
        }
    }

    // MARK: Server Integration Tests

    func testUniversalServer_CallsErrorHandler_OnDeserializationError() async throws {
        let trackingHandler = TrackingServerErrorHandler()
        let configuration = Configuration(serverErrorHandler: trackingHandler)
        let server = UniversalServer(handler: TestAPIHandler.successful, configuration: configuration)

        do {
            _ = try await server.handle(
                request: HTTPRequest(soar_path: "/test", method: .post),
                requestBody: nil,
                metadata: ServerRequestMetadata(),
                forOperation: "serverOp",
                using: { handler in handler.handleRequest },
                deserializer: { _, _, _ in throw NSError(domain: "Deserialization", code: 1) },
                serializer: { output, _ in (HTTPResponse(status: .ok), HTTPBody(output)) }
            )
            XCTFail("Expected error to be thrown")
        } catch {
            // Verify the error handler was called
            XCTAssertEqual(trackingHandler.handledErrors.count, 1)
            XCTAssertEqual(trackingHandler.handledErrors[0].operationID, "serverOp")

            // Verify the error is a ServerError
            XCTAssertTrue(error is ServerError)
        }
    }

    func testUniversalServer_CallsErrorHandler_OnHandlerError() async throws {
        let trackingHandler = TrackingServerErrorHandler()
        let configuration = Configuration(serverErrorHandler: trackingHandler)
        let server = UniversalServer(handler: TestAPIHandler.failing, configuration: configuration)

        do {
            _ = try await server.handle(
                request: HTTPRequest(soar_path: "/test", method: .post),
                requestBody: nil,
                metadata: ServerRequestMetadata(),
                forOperation: "serverOp",
                using: { handler in handler.handleRequest },
                deserializer: { _, _, _ in "test-input" },
                serializer: { output, _ in (HTTPResponse(status: .ok), HTTPBody(output)) }
            )
            XCTFail("Expected error to be thrown")
        } catch {
            // Verify the error handler was called
            XCTAssertEqual(trackingHandler.handledErrors.count, 1)
            XCTAssertEqual(trackingHandler.handledErrors[0].operationID, "serverOp")

            // Verify the error is a ServerError
            guard let serverError = error as? ServerError else {
                XCTFail("Expected ServerError")
                return
            }

            // Should be wrapped in RuntimeError.handlerFailed
            XCTAssertTrue(serverError.causeDescription.contains("handler"))
            XCTAssertEqual(serverError.httpStatus, .internalServerError)
        }
    }

    func testUniversalServer_CallsErrorHandler_OnSerializationError() async throws {
        let trackingHandler = TrackingServerErrorHandler()
        let configuration = Configuration(serverErrorHandler: trackingHandler)
        let server = UniversalServer(handler: TestAPIHandler.successful, configuration: configuration)

        do {
            _ = try await server.handle(
                request: HTTPRequest(soar_path: "/test", method: .post),
                requestBody: nil,
                metadata: ServerRequestMetadata(),
                forOperation: "serverOp",
                using: { handler in handler.handleRequest },
                deserializer: { _, _, _ in "test-input" },
                serializer: { _, _ in throw NSError(domain: "Serialization", code: 1) }
            )
            XCTFail("Expected error to be thrown")
        } catch {
            // Verify the error handler was called
            XCTAssertEqual(trackingHandler.handledErrors.count, 1)
            XCTAssertEqual(trackingHandler.handledErrors[0].operationID, "serverOp")

            // Verify the error is a ServerError
            XCTAssertTrue(error is ServerError)
        }
    }

    func testUniversalServer_DoesNotCallHandler_WhenNotConfigured() async throws {
        // No custom handler in configuration
        let server = UniversalServer(handler: TestAPIHandler.failing)

        do {
            _ = try await server.handle(
                request: HTTPRequest(soar_path: "/test", method: .post),
                requestBody: nil,
                metadata: ServerRequestMetadata(),
                forOperation: "serverOp",
                using: { handler in handler.handleRequest },
                deserializer: { _, _, _ in "test-input" },
                serializer: { output, _ in (HTTPResponse(status: .ok), HTTPBody(output)) }
            )
            XCTFail("Expected error to be thrown")
        } catch {
            // Should still produce a ServerError
            guard let serverError = error as? ServerError else {
                XCTFail("Expected ServerError")
                return
            }

            XCTAssertEqual(serverError.operationID, "serverOp")
            XCTAssertEqual(serverError.httpStatus, .internalServerError)
        }
    }

    // MARK: Multiple Error Handler Tests

    func testMultipleErrors_EachPassesThroughHandler() async throws {
        let trackingHandler = TrackingClientErrorHandler()
        let configuration = Configuration(clientErrorHandler: trackingHandler)
        let client = UniversalClient(configuration: configuration, transport: TestClientTransport.failing)

        // Trigger multiple errors
        for i in 1...3 {
            do {
                _ = try await client.send(
                    input: "test-\(i)",
                    forOperation: "testOp\(i)",
                    serializer: { _ in (HTTPRequest(soar_path: "/test", method: .get), nil) },
                    deserializer: { _, _ in "" }
                )
                XCTFail("Expected error to be thrown")
            } catch {
                // Expected
            }
        }

        // Verify all errors were tracked
        XCTAssertEqual(trackingHandler.handledErrors.count, 3)
        XCTAssertEqual(trackingHandler.handledErrors[0].operationID, "testOp1")
        XCTAssertEqual(trackingHandler.handledErrors[1].operationID, "testOp2")
        XCTAssertEqual(trackingHandler.handledErrors[2].operationID, "testOp3")
    }
}
