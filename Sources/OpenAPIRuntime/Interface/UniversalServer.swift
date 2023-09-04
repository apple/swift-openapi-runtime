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

@_spi(Generated)
public struct UniversalServer<APIHandler: Sendable>: Sendable {

    public var serverURL: URL

    public var converter: Converter

    public var handler: APIHandler

    public var middlewares: [any ServerMiddleware]

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

    public func handle<OperationInput, OperationOutput>(
        request: HTTPRequest,
        requestBody: HTTPBody?,
        forOperation operationID: String,
        using handlerMethod: @Sendable @escaping (APIHandler) -> ((OperationInput) async throws -> OperationOutput),
        deserializer: @Sendable @escaping (HTTPRequest, HTTPBody?) throws -> OperationInput,
        serializer: @Sendable @escaping (OperationOutput, HTTPRequest) throws -> (HTTPResponse, HTTPBody)
    ) async throws -> (HTTPResponse, HTTPBody) where OperationInput: Sendable, OperationOutput: Sendable {
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
                operationInput: input,
                operationOutput: output,
                underlyingError: error
            )
        }
        var next: @Sendable (HTTPRequest, HTTPBody?) async throws -> (HTTPResponse, HTTPBody) = {
            _request,
            _requestBody in
            let input: OperationInput = try await wrappingErrors {
                try deserializer(_request, _requestBody)
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
                    operationID: operationID,
                    next: tmp
                )
            }
        }
        return try await next(request, requestBody)
    }

    public func apiPathComponentsWithServerPrefix(
        _ path: String
    ) throws -> String {
        // Operation path is for example [pets, 42]
        // Server may be configured with a prefix, for example http://localhost/foo/bar/v1
        // Goal is to return something like [foo, bar, v1, pets, 42]
        guard let components = URLComponents(url: serverURL, resolvingAgainstBaseURL: false) else {
            throw RuntimeError.invalidServerURL(serverURL.absoluteString)
        }
        return components.path + path
    }
}
