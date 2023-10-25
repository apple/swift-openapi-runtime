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
import HTTPTypes
import Foundation
@_spi(Generated) @testable import OpenAPIRuntime

struct MockClientTransport: ClientTransport {
    var sendBlock: @Sendable (HTTPRequest, HTTPBody?, URL, String) async throws -> (HTTPResponse, HTTPBody?)
    func send(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String
    ) async throws -> (HTTPResponse, HTTPBody?) {
        try await sendBlock(request, body, baseURL, operationID)
    }

    static let requestBody: HTTPBody = HTTPBody("hello")
    static let responseBody: HTTPBody = HTTPBody("bye")

    static var successful: Self {
        MockClientTransport { _, _, _, _ in
            (HTTPResponse(status: .ok), responseBody)
        }
    }

    static var failing: Self {
        MockClientTransport { _, _, _, _ in
            throw TestError()
        }
    }
}

final class Test_UniversalClient: Test_Runtime {

    func testSuccess() async throws {
        let client = UniversalClient(transport: MockClientTransport.successful)
        let output = try await client.send(
            input: "input",
            forOperation: "op",
            serializer: { input in
                (
                    HTTPRequest(soar_path: "/", method: .post),
                    MockClientTransport.requestBody
                )
            },
            deserializer: { response, body in
                let body = try XCTUnwrap(body)
                let string = try await String(collecting: body, upTo: 10)
                return string
            }
        )
        XCTAssertEqual(output, "bye")
    }

    func testErrorPropagation_serializer() async throws {
        do {
            let client = UniversalClient(transport: MockClientTransport.successful)
            try await client.send(
                input: "input",
                forOperation: "op",
                serializer: { input in
                    throw TestError()
                },
                deserializer: { response, body in
                    fatalError()
                }
            )
        } catch {
            let clientError = try XCTUnwrap(error as? ClientError)
            XCTAssertEqual(clientError.operationID, "op")
            XCTAssertEqual(clientError.operationInput as? String, "input")
            XCTAssertEqual(clientError.causeDescription, "Unknown")
            XCTAssertEqual(clientError.underlyingError as? TestError, TestError())
            XCTAssertNil(clientError.request)
            XCTAssertNil(clientError.requestBody)
            XCTAssertNil(clientError.baseURL)
            XCTAssertNil(clientError.response)
            XCTAssertNil(clientError.responseBody)
        }
    }
    
    func testErrorPropagation_middlewareOnRequest() async throws {
        do {
            let client = UniversalClient(
                transport: MockClientTransport.successful,
                middlewares: [
                    MockMiddleware(failurePhase: .onRequest)
                ]
            )
            try await client.send(
                input: "input",
                forOperation: "op",
                serializer: { input in
                    (
                        HTTPRequest(soar_path: "/", method: .post),
                        MockClientTransport.requestBody
                    )
                },
                deserializer: { response, body in
                    fatalError()
                }
            )
        } catch {
            let clientError = try XCTUnwrap(error as? ClientError)
            XCTAssertEqual(clientError.operationID, "op")
            XCTAssertEqual(clientError.operationInput as? String, "input")
            XCTAssertEqual(clientError.causeDescription, "Middleware of type 'MockMiddleware' threw an error.")
            XCTAssertEqual(clientError.underlyingError as? TestError, TestError())
            XCTAssertEqual(clientError.request, HTTPRequest(soar_path: "/", method: .post))
            XCTAssertEqual(clientError.requestBody, MockClientTransport.requestBody)
            XCTAssertEqual(clientError.baseURL, URL(string: "/"))
            XCTAssertNil(clientError.response)
            XCTAssertNil(clientError.responseBody)
        }
    }

    func testErrorPropagation_transport() async throws {
        do {
            let client = UniversalClient(
                transport: MockClientTransport.failing,
                middlewares: [
                    MockMiddleware()
                ]
            )
            try await client.send(
                input: "input",
                forOperation: "op",
                serializer: { input in
                    (
                        HTTPRequest(soar_path: "/", method: .post),
                        MockClientTransport.requestBody
                    )
                },
                deserializer: { response, body in
                    fatalError()
                }
            )
        } catch {
            let clientError = try XCTUnwrap(error as? ClientError)
            XCTAssertEqual(clientError.operationID, "op")
            XCTAssertEqual(clientError.operationInput as? String, "input")
            XCTAssertEqual(clientError.causeDescription, "Transport threw an error.")
            XCTAssertEqual(clientError.underlyingError as? TestError, TestError())
            XCTAssertEqual(clientError.request, HTTPRequest(soar_path: "/", method: .post))
            XCTAssertEqual(clientError.requestBody, MockClientTransport.requestBody)
            XCTAssertEqual(clientError.baseURL, URL(string: "/"))
            XCTAssertNil(clientError.response)
            XCTAssertNil(clientError.responseBody)
        }
    }

    func testErrorPropagation_middlewareOnResponse() async throws {
        do {
            let client = UniversalClient(
                transport: MockClientTransport.successful,
                middlewares: [
                    MockMiddleware(failurePhase: .onResponse)
                ]
            )
            try await client.send(
                input: "input",
                forOperation: "op",
                serializer: { input in
                    (
                        HTTPRequest(soar_path: "/", method: .post),
                        MockClientTransport.requestBody
                    )
                },
                deserializer: { response, body in
                    fatalError()
                }
            )
        } catch {
            let clientError = try XCTUnwrap(error as? ClientError)
            XCTAssertEqual(clientError.operationID, "op")
            XCTAssertEqual(clientError.operationInput as? String, "input")
            XCTAssertEqual(clientError.causeDescription, "Middleware of type 'MockMiddleware' threw an error.")
            XCTAssertEqual(clientError.underlyingError as? TestError, TestError())
            XCTAssertEqual(clientError.request, HTTPRequest(soar_path: "/", method: .post))
            XCTAssertEqual(clientError.requestBody, MockClientTransport.requestBody)
            XCTAssertEqual(clientError.baseURL, URL(string: "/"))
            XCTAssertEqual(clientError.response, HTTPResponse(status: .ok))
            XCTAssertEqual(clientError.responseBody, MockClientTransport.responseBody)
        }
    }

    func testErrorPropagation_deserializer() async throws {
        do {
            let client = UniversalClient(transport: MockClientTransport.successful)
            try await client.send(
                input: "input",
                forOperation: "op",
                serializer: { input in
                    (
                        HTTPRequest(soar_path: "/", method: .post),
                        MockClientTransport.requestBody
                    )
                },
                deserializer: { response, body in
                    throw TestError()
                }
            )
        } catch {
            let clientError = try XCTUnwrap(error as? ClientError)
            XCTAssertEqual(clientError.operationID, "op")
            XCTAssertEqual(clientError.operationInput as? String, "input")
            XCTAssertEqual(clientError.causeDescription, "Unknown")
            XCTAssertEqual(clientError.underlyingError as? TestError, TestError())
            XCTAssertEqual(clientError.request, HTTPRequest(soar_path: "/", method: .post))
            XCTAssertEqual(clientError.requestBody, MockClientTransport.requestBody)
            XCTAssertEqual(clientError.baseURL, URL(string: "/"))
            XCTAssertEqual(clientError.response, HTTPResponse(status: .ok))
            XCTAssertEqual(clientError.responseBody, MockClientTransport.responseBody)
        }
    }
}
