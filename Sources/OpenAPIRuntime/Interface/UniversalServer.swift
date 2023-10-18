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

import HTTPTypes

#if canImport(Darwin)
import struct Foundation.URL
import struct Foundation.URLComponents
#else
@preconcurrency import struct Foundation.URL
@preconcurrency import struct Foundation.URLComponents
#endif

/// OpenAPI document-agnostic HTTP server used by OpenAPI document-specific,
/// generated servers to perform request deserialization, middleware and handler
/// invocation, and response serialization.
///
/// Do not call this directly, only invoked by generated code.
@_spi(Generated) public struct UniversalServer<APIHandler: Sendable>: Sendable {

    /// The URL of the server, used to determine the path prefix for
    /// registered request handlers.
    public var serverURL: URL

    /// A converter for encoding/decoding data.
    public var converter: Converter

    /// A type capable of handling HTTP requests and returning HTTP responses.
    public var handler: APIHandler

    /// The middlewares to be invoked before the handler receives the request.
    public var middlewares: [any ServerMiddleware]

    /// Internal initializer that takes an initialized converter.
    internal init(
        serverURL: URL,
        converter: Converter,
        handler: APIHandler,
        middlewares: [any ServerMiddleware]
    ) {
        self.serverURL = serverURL
        self.converter = converter
        self.handler = handler
        self.middlewares = middlewares
    }

    /// Creates a new server with the specified parameters.
    public init(
        serverURL: URL = .defaultOpenAPIServerURL,
        handler: APIHandler,
        configuration: Configuration = .init(),
        middlewares: [any ServerMiddleware] = []
    ) {
        self.init(
            serverURL: serverURL,
            converter: Converter(configuration: configuration),
            handler: handler,
            middlewares: middlewares
        )
    }

    /// Performs the operation.
    ///
    /// Should only be called by generated code, not directly.
    ///
    /// An operation consists of three steps (middlewares happen before 1 and after 3):
    /// 1. Convert HTTP request into Input.
    /// 2. Invoke the user handler to perform the user logic.
    /// 3. Convert Output into an HTTP response.
    ///
    /// It wraps any thrown errors and attaching appropriate context.
    /// - Parameters:
    ///   - request: The HTTP request.
    ///   - requestBody: The HTTP request body.
    ///   - metadata: The HTTP request metadata.
    ///   - operationID: The OpenAPI operation identifier.
    ///   - handlerMethod: The user handler method.
    ///   - deserializer: A closure that creates an Input value from the
    ///     provided HTTP request.
    ///   - serializer: A closure that creates an HTTP response from the
    ///     provided Output value.
    /// - Returns: The HTTP response and its body produced by the serializer.
    /// - Throws: An error if any part of the operation process fails.
    public func handle<OperationInput, OperationOutput>(
        request: HTTPRequest,
        requestBody: HTTPBody?,
        metadata: ServerRequestMetadata,
        forOperation operationID: String,
        using handlerMethod: @Sendable @escaping (APIHandler) -> ((OperationInput) async throws -> OperationOutput),
        deserializer: @Sendable @escaping (HTTPRequest, HTTPBody?, ServerRequestMetadata) async throws ->
            OperationInput,
        serializer: @Sendable @escaping (OperationOutput, HTTPRequest) throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) where OperationInput: Sendable, OperationOutput: Sendable {
        @Sendable
        func wrappingErrors<R>(
            work: () async throws -> R,
            mapError: (any Error) -> any Error
        ) async throws -> R {
            do {
                return try await work()
            } catch {
                throw mapError(error)
            }
        }
        @Sendable
        func makeError(
            input: OperationInput? = nil,
            output: OperationOutput? = nil,
            error: any Error
        ) -> any Error {
            ServerError(
                operationID: operationID,
                request: request,
                requestBody: requestBody,
                requestMetadata: metadata,
                operationInput: input,
                operationOutput: output,
                underlyingError: error
            )
        }
        var next: @Sendable (HTTPRequest, HTTPBody?, ServerRequestMetadata) async throws -> (HTTPResponse, HTTPBody?) =
            {
                _request,
                _requestBody,
                _metadata in
                let input: OperationInput = try await wrappingErrors {
                    try await deserializer(_request, _requestBody, _metadata)
                } mapError: { error in
                    makeError(error: error)
                }
                let output: OperationOutput = try await wrappingErrors {
                    let method = handlerMethod(handler)
                    return try await wrappingErrors {
                        try await method(input)
                    } mapError: { error in
                        RuntimeError.handlerFailed(error)
                    }
                } mapError: { error in
                    makeError(input: input, error: error)
                }
                return try await wrappingErrors {
                    try serializer(output, _request)
                } mapError: { error in
                    makeError(input: input, output: output, error: error)
                }
            }
        for middleware in middlewares.reversed() {
            let tmp = next
            next = {
                try await middleware.intercept(
                    $0,
                    body: $1,
                    metadata: $2,
                    operationID: operationID,
                    next: tmp
                )
            }
        }
        return try await next(request, requestBody, metadata)
    }

    /// Returns the path with the server URL's path prefix prepended.
    /// - Parameter path: The path suffix.
    /// - Returns: The path appended to the server URL's path.
    /// - Throws: An error if resolving the server URL components fails or if the server URL is invalid.
    public func apiPathComponentsWithServerPrefix(
        _ path: String
    ) throws -> String {
        // Operation path is for example "/pets/42"
        // Server may be configured with a prefix, for example http://localhost/foo/bar/v1
        // Goal is to return something like "/foo/bar/v1/pets/42".
        guard let components = URLComponents(url: serverURL, resolvingAgainstBaseURL: false) else {
            throw RuntimeError.invalidServerURL(serverURL.absoluteString)
        }
        let prefixPath = components.path
        guard prefixPath == "/" else {
            return prefixPath + path
        }
        return path
    }
}
