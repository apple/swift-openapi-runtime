//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftOpenAPIGenerator open source project
//
// Copyright (c) 2024 Apple Inc. and the SwiftOpenAPIGenerator project authors
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

struct MockRuntimeErrorHandler: Sendable {
    var failWithError: (any Error)? = nil
    func greet(_ input: String) async throws -> String {
        if let failWithError { throw failWithError }
        guard input == "hello" else { throw TestError() }
        return "bye"
    }

    static let requestBody: HTTPBody = HTTPBody("hello")
    static let responseBody: HTTPBody = HTTPBody("bye")
}

final class Test_RuntimeError: XCTestCase {
    
    func testRuntimeError_withUnderlyingErrorNotConfirming_returns500() async throws {
        
        let server = UniversalServer(handler: MockRuntimeErrorHandler(failWithError: RuntimeError.transportFailed(TestError())),
                                     middlewares: [ErrorHandlingMiddleware()])
        let response = try await server.handle(
            request: .init(soar_path: "/", method: .post),
            requestBody: MockHandler.requestBody,
            metadata: .init(),
            forOperation: "op",
            using: { MockRuntimeErrorHandler.greet($0) },
            deserializer: { request, body, metadata in
                let body = try XCTUnwrap(body)
                return try await String(collecting: body, upTo: 10)
            },
            serializer: { output, _ in fatalError() }
        )
        XCTAssertEqual(response.0.status, .internalServerError)
    }

    func testRuntimeError_withUnderlyingErrorConfirming_returnsCorrectStatusCode() async throws {
        
        let server = UniversalServer(handler: MockRuntimeErrorHandler(failWithError: TestErrorConvertible.testError("Test Error")),
                                     middlewares: [ErrorHandlingMiddleware()])
        let response = try await server.handle(
            request: .init(soar_path: "/", method: .post),
            requestBody: MockHandler.requestBody,
            metadata: .init(),
            forOperation: "op",
            using: { MockRuntimeErrorHandler.greet($0) },
            deserializer: { request, body, metadata in
                let body = try XCTUnwrap(body)
                return try await String(collecting: body, upTo: 10)
            },
            serializer: { output, _ in fatalError() }
        )
        XCTAssertEqual(response.0.status, .badGateway)
    }
}

enum TestErrorConvertible: Error, HTTPResponseConvertible {
    case testError(String)
    
    /// HTTP status code for error cases
    public var httpStatus: HTTPTypes.HTTPResponse.Status {
        .badGateway
    }
}


