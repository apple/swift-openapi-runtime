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

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif
import XCTest
import HTTPTypes
@_spi(Generated) @testable import OpenAPIRuntime

struct MockHandler: Sendable {
    var shouldFail: Bool = false
    func greet(_ input: String) async throws -> String {
        if shouldFail { throw TestError() }
        guard input == "hello" else { throw TestError() }
        return "bye"
    }

    static let requestBody: HTTPBody = HTTPBody("hello")
    static let responseBody: HTTPBody = HTTPBody("bye")
}

final class Test_UniversalServer: Test_Runtime {

    func testSuccess() async throws {
        let server = UniversalServer(handler: MockHandler())
        let (response, responseBody) = try await server.handle(
            request: .init(soar_path: "/", method: .post),
            requestBody: .init("hello"),
            metadata: .init(),
            forOperation: "op",
            using: { MockHandler.greet($0) },
            deserializer: { request, body, metadata in
                let body = try XCTUnwrap(body)
                return try await String(collecting: body, upTo: 10)
            },
            serializer: { output, _ in (HTTPResponse(status: .ok), MockHandler.responseBody) }
        )
        XCTAssertEqual(response, HTTPResponse(status: .ok))
        XCTAssertEqual(responseBody, MockHandler.responseBody)
    }

    func testErrorPropagation_middlewareOnRequest() async throws {
        do {
            let server = UniversalServer(
                handler: MockHandler(),
                middlewares: [MockMiddleware(failurePhase: .onRequest)]
            )
            _ = try await server.handle(
                request: .init(soar_path: "/", method: .post),
                requestBody: MockHandler.requestBody,
                metadata: .init(),
                forOperation: "op",
                using: { MockHandler.greet($0) },
                deserializer: { request, body, metadata in fatalError() },
                serializer: { output, _ in fatalError() }
            )
        } catch {
            let serverError = try XCTUnwrap(error as? ServerError)
            XCTAssertEqual(serverError.operationID, "op")
            XCTAssertEqual(serverError.causeDescription, "Middleware of type 'MockMiddleware' threw an error.")
            XCTAssertEqual(serverError.underlyingError as? TestError, TestError())
            XCTAssertEqual(serverError.request, .init(soar_path: "/", method: .post))
            XCTAssertEqual(serverError.requestBody, MockHandler.requestBody)
            XCTAssertEqual(serverError.requestMetadata, .init())
            XCTAssertNil(serverError.operationInput)
            XCTAssertNil(serverError.operationOutput)
        }
    }

    func testErrorPropagation_deserializer() async throws {
        do {
            let server = UniversalServer(handler: MockHandler())
            _ = try await server.handle(
                request: .init(soar_path: "/", method: .post),
                requestBody: MockHandler.requestBody,
                metadata: .init(),
                forOperation: "op",
                using: { MockHandler.greet($0) },
                deserializer: { request, body, metadata in throw TestError() },
                serializer: { output, _ in fatalError() }
            )
        } catch {
            let serverError = try XCTUnwrap(error as? ServerError)
            XCTAssertEqual(serverError.operationID, "op")
            XCTAssertEqual(serverError.causeDescription, "Unknown")
            XCTAssertEqual(serverError.underlyingError as? TestError, TestError())
            XCTAssertEqual(serverError.request, .init(soar_path: "/", method: .post))
            XCTAssertEqual(serverError.requestBody, MockHandler.requestBody)
            XCTAssertEqual(serverError.requestMetadata, .init())
            XCTAssertNil(serverError.operationInput)
            XCTAssertNil(serverError.operationOutput)
        }
    }

    func testErrorPropagation_deserializerWithDecodingError() async throws {
        let decodingError = DecodingError.dataCorrupted(
            .init(codingPath: [], debugDescription: "Invalid request body.")
        )
        do {
            let server = UniversalServer(handler: MockHandler())
            _ = try await server.handle(
                request: .init(soar_path: "/", method: .post),
                requestBody: MockHandler.requestBody,
                metadata: .init(),
                forOperation: "op",
                using: { MockHandler.greet($0) },
                deserializer: { request, body, metadata in throw decodingError },
                serializer: { output, _ in fatalError() }
            )
        } catch {
            let serverError = try XCTUnwrap(error as? ServerError)
            XCTAssertEqual(serverError.operationID, "op")
            XCTAssert(serverError.causeDescription.contains("An error occurred while attempting to parse the request"))
            XCTAssert(serverError.underlyingError is DecodingError)
            XCTAssertEqual(serverError.httpStatus, .badRequest)
            XCTAssertEqual(serverError.httpHeaderFields, [:])
            XCTAssertNil(serverError.httpBody)
            XCTAssertEqual(serverError.request, .init(soar_path: "/", method: .post))
            XCTAssertEqual(serverError.requestBody, MockHandler.requestBody)
            XCTAssertEqual(serverError.requestMetadata, .init())
            XCTAssertNil(serverError.operationInput)
            XCTAssertNil(serverError.operationOutput)
        }
    }

    func testErrorPropagation_handler() async throws {
        do {
            let server = UniversalServer(handler: MockHandler(shouldFail: true))
            _ = try await server.handle(
                request: .init(soar_path: "/", method: .post),
                requestBody: MockHandler.requestBody,
                metadata: .init(),
                forOperation: "op",
                using: { MockHandler.greet($0) },
                deserializer: { request, body, metadata in
                    let body = try XCTUnwrap(body)
                    return try await String(collecting: body, upTo: 10)
                },
                serializer: { output, _ in fatalError() }
            )
        } catch {
            let serverError = try XCTUnwrap(error as? ServerError)
            XCTAssertEqual(serverError.operationID, "op")
            XCTAssertEqual(serverError.causeDescription, "User handler threw an error.")
            XCTAssertEqual(serverError.underlyingError as? TestError, TestError())
            XCTAssertEqual(serverError.request, .init(soar_path: "/", method: .post))
            XCTAssertEqual(serverError.requestBody, MockHandler.requestBody)
            XCTAssertEqual(serverError.requestMetadata, .init())
            XCTAssertEqual(serverError.operationInput as? String, "hello")
            XCTAssertNil(serverError.operationOutput)
        }
    }

    func testErrorPropagation_serializer() async throws {
        do {
            let server = UniversalServer(handler: MockHandler())
            _ = try await server.handle(
                request: .init(soar_path: "/", method: .post),
                requestBody: MockHandler.requestBody,
                metadata: .init(),
                forOperation: "op",
                using: { MockHandler.greet($0) },
                deserializer: { request, body, metadata in
                    let body = try XCTUnwrap(body)
                    return try await String(collecting: body, upTo: 10)
                },
                serializer: { output, _ in throw TestError() }
            )
        } catch {
            let serverError = try XCTUnwrap(error as? ServerError)
            XCTAssertEqual(serverError.operationID, "op")
            XCTAssertEqual(serverError.causeDescription, "Unknown")
            XCTAssertEqual(serverError.underlyingError as? TestError, TestError())
            XCTAssertEqual(serverError.request, .init(soar_path: "/", method: .post))
            XCTAssertEqual(serverError.requestBody, MockHandler.requestBody)
            XCTAssertEqual(serverError.requestMetadata, .init())
            XCTAssertEqual(serverError.operationInput as? String, "hello")
            XCTAssertEqual(serverError.operationOutput as? String, "bye")
        }
    }

    func testErrorPropagation_middlewareOnResponse() async throws {
        do {
            let server = UniversalServer(
                handler: MockHandler(),
                middlewares: [MockMiddleware(failurePhase: .onResponse)]
            )
            _ = try await server.handle(
                request: .init(soar_path: "/", method: .post),
                requestBody: MockHandler.requestBody,
                metadata: .init(),
                forOperation: "op",
                using: { MockHandler.greet($0) },
                deserializer: { request, body, metadata in
                    let body = try XCTUnwrap(body)
                    return try await String(collecting: body, upTo: 10)
                },
                serializer: { output, _ in (HTTPResponse(status: .ok), MockHandler.responseBody) }
            )
        } catch {
            let serverError = try XCTUnwrap(error as? ServerError)
            XCTAssertEqual(serverError.operationID, "op")
            XCTAssertEqual(serverError.causeDescription, "Middleware of type 'MockMiddleware' threw an error.")
            XCTAssertEqual(serverError.underlyingError as? TestError, TestError())
            XCTAssertEqual(serverError.request, .init(soar_path: "/", method: .post))
            XCTAssertEqual(serverError.requestBody, MockHandler.requestBody)
            XCTAssertEqual(serverError.requestMetadata, .init())
            XCTAssertNil(serverError.operationInput)
            XCTAssertNil(serverError.operationOutput)
        }
    }

    func testApiPathComponentsWithServerPrefix_noPrefix() throws {
        let server = UniversalServer(handler: MockHandler())
        let components = "/foo/{bar}"
        let prefixed = try server.apiPathComponentsWithServerPrefix(components)
        // When no server path prefix, components stay the same
        XCTAssertEqual(prefixed, components)
    }

    func testApiPathComponentsWithServerPrefix_withPrefix() throws {
        let server = UniversalServer(serverURL: try serverURL, handler: MockHandler())
        let components = "/foo/{bar}"
        let prefixed = try server.apiPathComponentsWithServerPrefix(components)
        let expected = "/api/foo/{bar}"
        XCTAssertEqual(prefixed, expected)
    }
}
